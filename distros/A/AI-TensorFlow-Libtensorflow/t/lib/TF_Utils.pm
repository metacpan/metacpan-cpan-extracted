package TF_Utils;

use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::Lib;
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT INT32 INT8);
use Path::Tiny;
use List::Util qw(first);

use PDL::Core ':Internal';

use FFI::Platypus::Buffer;
use Test2::V0;

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;

sub ScalarStringTensor {
	my ($str, $status) = @_;
	#my $tensor = AI::TensorFlow::Libtensorflow::Tensor->_Allocate(
		#AI::TensorFlow::Libtensorflow::DType::STRING,
		#\@dims, $ndims,
		#$data_size_bytes,
	#);
	...
}

sub ReadBufferFromFile {
	my ($path) = @_;
	my $data = path($path)->slurp_raw;
	my $buffer = AI::TensorFlow::Libtensorflow::Buffer->NewFromData(
		$data
	);
}

sub LoadGraph {
	my ($path, $checkpoint_prefix, $status) = @_;
	my $buffer = ReadBufferFromFile( $path );

	$status //= AI::TensorFlow::Libtensorflow::Status->New;

	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $opts  = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;

	$graph->ImportGraphDef( $buffer, $opts, $status );

	if( $status->GetCode != AI::TensorFlow::Libtensorflow::Status::OK ) {
		return undef;
	}

	if( ! defined $checkpoint_prefix ) {
		return $graph;
	}
}

sub FloatPDLToTFTensor {
	my ($p) = @_;
	my $pdl_closure = sub {
		my ($pointer, $size, $pdl_addr) = @_;
		# noop
	};

	my $p_dataref = $p->get_dataref;
	my $tensor = AI::TensorFlow::Libtensorflow::Tensor->New(
		FLOAT, [ $p->dims ], $p_dataref, $pdl_closure
	);

	$tensor;
}

sub Placeholder {
	my ($graph, $status, $name, $dtype) = @_;
	$name ||= 'feed';
	$dtype ||= INT32;
	my $desc = AI::TensorFlow::Libtensorflow::OperationDescription->New($graph, 'Placeholder', $name);
	$desc->SetAttrType('dtype', $dtype);
	my $op = $desc->FinishOperation($status);
	AssertStatusOK($status);
	$op;
}

sub Const {
	my ($graph, $status, $name, $t) = @_;
	my $desc = AI::TensorFlow::Libtensorflow::OperationDescription->New($graph, 'Const', $name);
	$desc->SetAttrTensor('value', $t, $status);
	$desc->SetAttrType('dtype', $t->Type);
	my $op = $desc->FinishOperation($status);
	AssertStatusOK($status);
	$op;
}

my %dtype_to_pack = (
	FLOAT  => 'f',
	DOUBLE => 'd',
	INT32  => 'l',
	INT8   => 'c',
	BOOL   => 'c',
);

use FFI::Platypus::Buffer qw(scalar_to_pointer);
use FFI::Platypus::Memory qw(memcpy);

sub ScalarConst {
	my ($graph, $status, $name, $dtype, $value) = @_;
	$name ||= 'scalar';
	my $t = AI::TensorFlow::Libtensorflow::Tensor->Allocate($dtype, []);
	die "Pack format for $dtype is unknown" unless exists $dtype_to_pack{$dtype};
	my $data = pack $dtype_to_pack{$dtype} . '*', $value;
	memcpy scalar_to_pointer(${ $t->Data }),
		 scalar_to_pointer($data),
		 $t->ByteSize;
	return Const($graph, $status, $name, $t);
}


use AI::TensorFlow::Libtensorflow::Lib::Types qw(TFOutput TFOutputFromTuple);
use Types::Standard qw(HashRef);

my $TFOutput = TFOutput->plus_constructors(
		HashRef, 'New'
	)->plus_coercions(TFOutputFromTuple);
sub Add {
	my ($l, $r, $graph, $s, $name, $check) = @_;
	$name ||= 'add';
	$check = 1 if not defined $check;
	my $desc = AI::TensorFlow::Libtensorflow::OperationDescription->New(
		$graph, "AddN", $name);
	$desc->AddInputList([
		$TFOutput->map( [ $l => 0 ], [ $r => 0 ] )
	]);
	my $op = $desc->FinishOperation($s);
	AssertStatusOK($s) if $check;
	$op;
}

sub AddNoCheck {
	my ($l, $r, $graph, $s, $name) = @_;
	return Add( $l, $r, $graph, $s, $name, 0);
}

sub Neg {
	my ($n, $graph, $s, $name) = @_;
	$name ||= 'neg';
	my $desc = AI::TensorFlow::Libtensorflow::OperationDescription->New(
		$graph, "Neg", $name);
	my $neg_input = $TFOutput->coerce([$n => 0]);
	$desc->AddInput($neg_input);
	my $op = $desc->FinishOperation($s);
	AssertStatusOK($s);
	$op;
}

sub AnyTensor {
	my ($dtype, $v) = @_;
	die "Pack format for $dtype is unknown" unless exists $dtype_to_pack{$dtype};
	if( ! ref $v ) {
		my $t = AI::TensorFlow::Libtensorflow::Tensor->Allocate( $dtype, [] );
		memcpy scalar_to_pointer( ${ $t->Data } ),
			scalar_to_pointer(pack($dtype_to_pack{$dtype}, $v)), $dtype->Size;
		return $t;
	} elsif( ref $v eq 'ARRAY' ) {
		my $n = @$v;
		my $t = AI::TensorFlow::Libtensorflow::Tensor->Allocate( $dtype, [$n] );
		memcpy scalar_to_pointer( ${ $t->Data } ),
			scalar_to_pointer(pack("$dtype_to_pack{$dtype}*", @$v)), $n * $dtype->Size;
		return $t;
	}
}

sub Int8Tensor {
	return AnyTensor(INT8, @_);
}

sub Int32Tensor {
	return AnyTensor(INT32, @_);
}

sub AssertStatusOK {
	my ($status) = @_;
	die "Status not OK: @{[ $status->GetCode ]} : @{[ $status->Message ]}"
		unless $status->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;
}

sub AssertStatusNotOK {
	my ($status) = @_;
	die "Status expected not OK" if $status->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;
	return "Status: @{[ $status->GetCode ]}:  @{[ $status->Message ]}";
}

package # hide from PAUSE
  TF_Utils::CSession {

	use Class::Tiny qw(
		session
		graph use_XLA
		_inputs _input_values
		_outputs _output_values
		_targets
	), {
		use_XLA => sub { 0 },
	};

  sub BUILD {
	my ($self, $args) = @_;
	my $s = delete $args->{status};
	my $opts = AI::TensorFlow::Libtensorflow::SessionOptions->New;
	$opts->EnableXLACompilation( $self->use_XLA );
	if( ! exists $args->{session} ) {
		$self->session( AI::TensorFlow::Libtensorflow::Session->New( $self->graph, $opts, $s ) );
	}
  }

  sub SetInputs {
	my ($self, @data) = @_;
	my (@inputs, @input_values);
	for my $pair (@data) {
		my ($oper, $t) = @$pair;
		push @inputs, AI::TensorFlow::Libtensorflow::Output->New({ oper => $oper, index => 0 });
		push @input_values, $t;
	}
	$self->_inputs( \@inputs );
	$self->_input_values( \@input_values );
  }

  sub SetOutputs {
	my ($self, @data) = @_;
	my @outputs;
	my @output_values;
	for my $oper (@data) {
		push @outputs, AI::TensorFlow::Libtensorflow::Output->New({ oper => $oper, index => 0 });
	}
	$self->_outputs( \@outputs );
	$self->_output_values( \@output_values );
  }

  sub SetTargets {
	my ($self, @data) = @_;
	$self->_targets( \@data );
  }

  sub Run {
	my ($self, $s) = @_;
	if( @{ $self->_inputs } != @{ $self->_input_values } ) {
		die "Call SetInputs() before Run()";
	}

	$self->session->Run(
		undef,
		$self->_inputs, $self->_input_values,
		$self->_outputs, $self->_output_values,
		$self->_targets,
		undef,
		$s
	);
  }

  sub output_tensor { my ($self, $i) = @_; $self->_output_values->[$i] }
}

sub BinaryOpHelper {
	my ($op_name, $l, $r,
		$graph, $s, $name,
		$device, $check) = @_;
	$check ||= 1;

	my $desc = AI::TensorFlow::Libtensorflow::OperationDescription
		->New( $graph, $op_name, $name );

	$desc->SetDevice($device) if $device;

	$desc->AddInput( $TFOutput->coerce([ $l => 0 ]) );
	$desc->AddInput( $TFOutput->coerce([ $r => 0 ]) );

	my $op = $desc->FinishOperation($s);

	if( $check ) {
		TF_Utils::AssertStatusOK($s);
	}

	return $op;
}

sub MinWithDevice {
	my ($l, $r, $graph, $device, $s, $name) = @_;
	$name ||= 'min';

	return TF_Utils::BinaryOpHelper(
		'Min', $l, $r, $graph, $s, $name, $device, 1
	)
}

sub RunMinTest {
	my (%args) = @_;
	my $device  = delete $args{device} || "";
	my $use_XLA = delete $args{use_XLA} || 0;

	my $ctx = Test2::API::context();

	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	$ctx->note('Make a placeholder operation.');
	my $feed = TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);

	$ctx->note('Make a constant operation with the scalar "0", for axis.');
	my $one = TF_Utils::ScalarConst($graph, $s, 'scalar', INT32, 0);
	TF_Utils::AssertStatusOK($s);

	$ctx->note('Create a session for this graph.');
	my $csession = TF_Utils::CSession->new( graph => $graph, status => $s, use_XLA => $use_XLA );
	TF_Utils::AssertStatusOK($s);

	if( $device ) {
		$ctx->note("Setting op Min on device $device");
	}
	my $min = TF_Utils::MinWithDevice( $feed, $one, $graph, $device, $s );
	TF_Utils::AssertStatusOK($s);

	$ctx->note('Run the graph.');
	$csession->SetInputs( [ $feed, TF_Utils::Int32Tensor([3, 2, 5]) ]);
	$csession->SetOutputs($min);
	$csession->Run($s);
	TF_Utils::AssertStatusOK($s);
	is($csession->output_tensor(0), object {
		call Type => INT32;
		call NumDims => 0; # scalar
		call ByteSize => INT32->Size;
		call sub {
			[ unpack "l*", ${ shift->Data } ];
		} => [ 2 ];
	}, 'Min( Feed() = [3, 2, 5] )');

	$ctx->release;
}

sub GPUDeviceName {
	my ($session) = @_;

	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph;
	if( ! $session ) {
		my $opts = AI::TensorFlow::Libtensorflow::SessionOptions->New;
		$graph = AI::TensorFlow::Libtensorflow::Graph->New;
		$session ||= AI::TensorFlow::Libtensorflow::Session->New($graph, $opts, $s);
	}

	my $device_list = $session->ListDevices($s);
	my $device_idx = first { my $type = $device_list->Type( $_, $s ) eq 'GPU' } 0..$device_list->Count - 1;

	return "" unless $device_idx;

	return $device_list->Name( $device_idx, $s );
}

sub DumpDevices {
	my ($session) = @_;

	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph;
	if( ! $session ) {
		my $opts = AI::TensorFlow::Libtensorflow::SessionOptions->New;
		$graph = AI::TensorFlow::Libtensorflow::Graph->New;
		$session ||= AI::TensorFlow::Libtensorflow::Session->New($graph, $opts, $s);
	}

	my $device_list = $session->ListDevices($s);
	my @devices = map {
		my $idx = $_;
		my %h = map { ( $_ => $device_list->$_( $idx, $s ) ) } qw(Name Type MemoryBytes Incarnation);
		\%h;
	} 0..$device_list->Count - 1;
	use Data::Dumper; print Dumper(\@devices);
}

1;
