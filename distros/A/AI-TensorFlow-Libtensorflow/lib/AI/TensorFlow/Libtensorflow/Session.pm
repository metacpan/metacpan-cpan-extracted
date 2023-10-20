package AI::TensorFlow::Libtensorflow::Session;
# ABSTRACT: Session for driving ::Graph execution
$AI::TensorFlow::Libtensorflow::Session::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);;

use AI::TensorFlow::Libtensorflow::Tensor;
use AI::TensorFlow::Libtensorflow::Output;
use FFI::Platypus::Buffer qw(window scalar_to_pointer);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewSession' => 'New' ] =>
	[
		arg 'TF_Graph' => 'graph',
		arg 'TF_SessionOptions' => 'opt',
		arg 'TF_Status' => 'status',
	],
	=> 'TF_Session' => sub {
		my ($xs, $class, @rest) = @_;
		return $xs->(@rest);
	});

$ffi->attach( [ 'LoadSessionFromSavedModel' => 'LoadFromSavedModel' ] => [
    arg TF_SessionOptions => 'session_options',
    arg opaque => { id => 'run_options', ffi_type => 'TF_Buffer', maybe => 1 },
    arg string => 'export_dir',
    arg 'string[]' => 'tags',
    arg int => 'tags_len',
    arg TF_Graph => 'graph',
    arg opaque => { id => 'meta_graph_def', ffi_type => 'TF_Buffer', maybe => 1 },
    arg TF_Status => 'status',
] => 'TF_Session' => sub {
	my ($xs, $class, @rest) = @_;
	my ( $session_options,
		$run_options,
		$export_dir, $tags,
		$graph, $meta_graph_def,
		$status) = @rest;


	$run_options = $ffi->cast('TF_Buffer', 'opaque', $run_options)
		if defined $run_options;
	$meta_graph_def = $ffi->cast('TF_Buffer', 'opaque', $meta_graph_def)
		if defined $meta_graph_def;

	my $tags_len = @$tags;

	$xs->(
		$session_options,
		$run_options,
		$export_dir,
		$tags, $tags_len,
		$graph, $meta_graph_def,
		$status
	);
} );

$ffi->attach( [ 'SessionRun' => 'Run' ] =>
	[
		arg 'TF_Session' => 'session',

		# RunOptions
		arg 'opaque'  => { id => 'run_options', ffi_type => 'TF_Buffer', maybe => 1 },

		# Input TFTensors
		arg 'TF_Output_struct_array' => 'inputs',
		arg 'TF_Tensor_array' => 'input_values',
		arg 'int'             => 'ninputs',

		# Output TFTensors
		arg 'TF_Output_struct_array' => 'outputs',
		arg 'TF_Tensor_array' => 'output_values',
		arg 'int'             => 'noutputs',

		# Target operations
		arg 'opaque'         => { id => 'target_opers', ffi_type => 'TF_Operation_array', maybe => 1 },
		arg 'int'            => 'ntargets',

		# RunMetadata
		arg 'opaque'      => { id => 'run_metadata', ffi_type => 'TF_Buffer', maybe => 1 },

		# Output status
		arg 'TF_Status' => 'status',
	],
	=> 'void' => sub {
		my ($xs,
			$self,
			$run_options,
			$inputs , $input_values,
			$outputs, $output_values,
			$target_opers,
			$run_metadata,
			$status ) = @_;

		die "Mismatch in number of inputs and input values" unless $#$inputs == $#$input_values;
		my $input_v_a  = AI::TensorFlow::Libtensorflow::Tensor->_as_array(@$input_values);
		my $output_v_a = AI::TensorFlow::Libtensorflow::Tensor->_adef->create( 0+@$outputs );

		$inputs  = AI::TensorFlow::Libtensorflow::Output->_as_array( @$inputs );
		$outputs = AI::TensorFlow::Libtensorflow::Output->_as_array( @$outputs );
		$xs->($self,
			$run_options,

			# Inputs
			$inputs, $input_v_a , $input_v_a->count,

			# Outputs
			$outputs, $output_v_a, $output_v_a->count,

			_process_target_opers_args($target_opers),

			$run_metadata,

			$status
		);

		@{$output_values} = @{ AI::TensorFlow::Libtensorflow::Tensor->_from_array( $output_v_a ) };
	}
);

sub _process_target_opers_args {
	my ($target_opers) = @_;
	my @target_opers_args = defined $target_opers
		? do {
			my $target_opers_a = AI::TensorFlow::Libtensorflow::Operation->_as_array( @$target_opers );
			( $target_opers_a, $target_opers_a->count )
		}
		: ( undef, 0 );

	return @target_opers_args;
}

$ffi->attach([ 'SessionPRunSetup' => 'PRunSetup' ] => [
    arg TF_Session => 'session',
    # Input names
    arg TF_Output_struct_array => 'inputs',
    arg int => 'ninputs',
    # Output names
    arg TF_Output_struct_array => 'outputs',
    arg int => 'noutputs',
    # Target operations
    arg opaque => { id => 'target_opers', ffi_type => 'TF_Operation_array', maybe => 1 },
    arg int => 'ntargets',
    # Output handle
    arg 'opaque*' => { id => 'handle', ffi_type => 'string*', window =>  1 },
    # Output status
    arg TF_Status => 'status',
] => 'void' => sub {
	my ($xs, $session, $inputs, $outputs, $target_opers, $status) = @_;

	$inputs  = AI::TensorFlow::Libtensorflow::Output->_as_array( @$inputs );
	$outputs = AI::TensorFlow::Libtensorflow::Output->_as_array( @$outputs );

	my $handle;
	$xs->($session,
		$inputs, $inputs->count,
		$outputs, $outputs->count,
		_process_target_opers_args($target_opers),
		\$handle,
		$status,
	);

	return unless defined $handle;

	window( my $handle_window, $handle );

	my $handle_obj = bless \\$handle_window,
		'AI::TensorFlow::Libtensorflow::Session::_PRHandle';

	return $handle_obj;
});

$ffi->attach( [ 'DeletePRunHandle' => 'AI::TensorFlow::Libtensorflow::Session::_PRHandle::DESTROY' ] => [
	arg 'opaque' => 'handle',
] => 'void' => sub {
	my ($xs, $handle_obj) = @_;
	my $handle = scalar_to_pointer($$$handle_obj);
	$xs->( $handle );
} );

$ffi->attach( [ 'SessionPRun' => 'PRun' ] => [
	arg TF_Session => 'session',
	arg 'opaque' => 'handle',

	# Inputs
	arg TF_Output_struct_array => 'inputs',
	arg TF_Tensor_array => 'input_values',
	arg int => 'ninputs',

	# Outputs
	arg TF_Output_struct_array => 'outputs',
	arg TF_Tensor_array => 'output_values',
	arg int => 'noutputs',

	# Targets
	arg 'opaque*' => { id => 'target_opers', ffi_type => 'TF_Operation_array', maybe => 1 },
	arg int => 'ntargets',

	arg TF_Status => 'status',
] => 'void' => sub {
	my ($xs, $session, $handle_obj,
		$inputs, $input_values,
		$outputs, $output_values,
		$target_opers,
		$status) = @_;

	die "Mismatch in number of inputs and input values" unless $#$inputs == $#$input_values;
	my $input_v_a  = AI::TensorFlow::Libtensorflow::Tensor->_as_array(@$input_values);
	my $output_v_a = AI::TensorFlow::Libtensorflow::Tensor->_adef->create( 0+@$outputs );

	$inputs  = AI::TensorFlow::Libtensorflow::Output->_as_array( @$inputs );
	$outputs = AI::TensorFlow::Libtensorflow::Output->_as_array( @$outputs );
	my $handle = scalar_to_pointer( $$$handle_obj );
	$xs->($session, $handle,
		# Inputs
		$inputs, $input_v_a , $input_v_a->count,

		# Outputs
		$outputs, $output_v_a, $output_v_a->count,

		_process_target_opers_args($target_opers),

		$status,
	);

	@{$output_values} = @{ AI::TensorFlow::Libtensorflow::Tensor->_from_array( $output_v_a ) };
} );

$ffi->attach( [ 'SessionListDevices' => 'ListDevices' ] => [
	arg TF_Session => 'session',
	arg TF_Status => 'status',
] => 'TF_DeviceList');

$ffi->attach( [ 'CloseSession' => 'Close' ] =>
	[ 'TF_Session',
	'TF_Status',
	],
	=> 'void' );

$ffi->attach( [ 'DeleteSession' => '_Delete' ] => [
	arg 'TF_Session' => 's',
	arg 'TF_Status' => 'status',
], => 'void' );

sub DESTROY {
	my ($self) = @_;
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	$self->Close($s);
	# TODO this may not be needed with automatic Status handling
	die "Could not close session" unless $s->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;
	$self->_Delete($s);
	die "Could not delete session" unless $s->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Session - Session for driving ::Graph execution

=head1 CONSTRUCTORS

=head2 New

B<Parameters>

=over 4

=item L<TFGraph|AI::TensorFlow::Libtensorflow::Lib::Types/TFGraph> $graph

Graph to associate with the session.

=item L<TFSessionOptions|AI::TensorFlow::Libtensorflow::Lib::Types/TFSessionOptions> $opt

Session options.

=item L<TFStatus|AI::TensorFlow::Libtensorflow::Lib::Types/TFStatus> $status

Status.

=back

B<Returns>

=over 4

=item Maybe[TFSession]

A new execution session with the associated graph, or C<undef> on
error.

=back

B<C API>: L<< C<TF_NewSession>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewSession >>

=head2 LoadFromSavedModel

B<C API>: L<< C<TF_LoadSessionFromSavedModel>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_LoadSessionFromSavedModel >>

=head1 METHODS

=head2 Run

Run the graph associated with the session starting with the supplied
C<$inputs> with corresponding values in C<$input_values>.

The values at the outputs given by C<$outputs> will be placed in
C<$output_values>.

B<Parameters>

=over 4

=item Maybe[TFBuffer] $run_options

Optional C<TFBuffer> containing serialized representation of a `RunOptions` protocol buffer.

=item ArrayRef[TFOutput] $inputs

Inputs to set.

=item ArrayRef[TFTensor] $input_values

Values to assign to the inputs given by C<$inputs>.

=item ArrayRef[TFOutput] $outputs

Outputs to get.

=item ArrayRef[TFTensor] $output_values

Reference to where the output values for C<$outputs> will be placed.

=item ArrayRef[TFOperation] $target_opers

TODO

=item Maybe[TFBuffer] $run_metadata

Optional empty C<TFBuffer> which will be updated to contain a serialized
representation of a `RunMetadata` protocol buffer.

=item L<TFStatus|AI::TensorFlow::Libtensorflow::Lib::Types/TFStatus> $status

Status

=back

B<C API>: L<< C<TF_SessionRun>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SessionRun >>

=head2 PRunSetup

B<C API>: L<< C<TF_SessionPRunSetup>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SessionPRunSetup >>

=head2 AI::TensorFlow::Libtensorflow::Session::_PRHandle::DESTROY

B<C API>: L<< C<TF_DeletePRunHandle>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeletePRunHandle >>

=head2 PRun

B<C API>: L<< C<TF_SessionPRun>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SessionPRun >>

=head2 ListDevices

B<C API>: L<< C<TF_SessionListDevices>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SessionListDevices >>

=head2 Close

TODO

B<C API>: L<< C<TF_CloseSession>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_CloseSession >>

=head2 _Delete

B<C API>: L<< C<TF_DeleteSession>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteSession >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
