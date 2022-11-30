package TF_Utils;

use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::Lib;
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use Path::Tiny;

use PDL::Core ':Internal';

use FFI::Platypus::Buffer;

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

	#$opts->_Delete;
	#$buffer->_Delete;

	if( $status->GetCode ne 'OK' ) {
		$graph->_Delete;
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

1;
