package AI::TensorFlow::Libtensorflow::Session;
$AI::TensorFlow::Libtensorflow::Session::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);;

use AI::TensorFlow::Libtensorflow::Tensor;
use AI::TensorFlow::Libtensorflow::Output;

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

$ffi->attach( [ 'SessionRun' => 'Run' ] =>
	[
		arg 'TF_Session' => 'session',

		# RunOptions
		#arg 'TF_Buffer*'  => 'run_options',
		arg 'opaque'  => 'run_options',

		# Input TFTensors
		arg 'TF_Output_array' => 'inputs',
		arg 'TF_Tensor_array' => 'input_values',
		arg 'int'             => 'ninputs',

		# Output TFTensors
		arg 'TF_Output_array' => 'outputs',
		arg 'TF_Tensor_array' => 'output_values',
		arg 'int'             => 'noutputs',

		# Target operations
		#arg 'TF_Operation_array' => 'target_opers',
		arg 'opaque'         => 'target_opers',
		arg 'int'            => 'ntargets',

		# RunMetadata
		#arg 'TF_Buffer*' => 'run_metadata',
		arg 'opaque'      => 'run_metadata',

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
		my $input_a    = AI::TensorFlow::Libtensorflow::Output->_as_array(@$inputs);
		my $input_v_a  = AI::TensorFlow::Libtensorflow::Tensor->_as_array(@$input_values);
		my $output_a   = AI::TensorFlow::Libtensorflow::Output->_as_array(@$outputs);
		my $output_v_a = AI::TensorFlow::Libtensorflow::Tensor->_adef->create( 0+@$outputs );


		my @target_opers_args = defined $target_opers
			? do {
				my $target_opers_a = AI::TensorFlow::Libtensorflow::Operation->_as_array( @$target_opers );
				( $target_opers_a, $target_opers_a->count )
			}
			: ( undef, 0 );

		$xs->($self,
			$run_options,

			# Inputs
			$input_a , $input_v_a , $input_a->count,

			# Outputs
			$output_a, $output_v_a, $output_a->count,

			@target_opers_args,

			$run_metadata,

			$status
		);

		@{$output_values} =
			map {
				$ffi->cast(
					'opaque',
					'TF_Tensor',
					$output_v_a->[$_]->p)
			} 0.. $output_v_a->count - 1
	}
);

$ffi->attach( [ 'CloseSession' => 'Close' ] =>
	[ 'TF_Session',
	'TF_Status',
	],
	=> 'void' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Session

=head1 CONSTRUCTORS

=head2 New

TODO

B<Parameters>

=over 4

=item L<TFGraph|AI::TensorFlow::Libtensorflow::Lib::Types/TFGraph> $graph

TODO

=item L<TFSessionOptions|AI::TensorFlow::Libtensorflow::Lib::Types/TFSessionOptions> $opt

TODO

=item L<TFStatus|AI::TensorFlow::Libtensorflow::Lib::Types/TFStatus> $status

=back

B<Returns>

=over 4

=item L<TFSession|AI::TensorFlow::Libtensorflow::Lib::Types/TFSession>

TODO

=back

B<C API>: L<< C<TF_NewSession>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewSession >>

=head1 METHODS

=head2 Run

TODO

B<Parameters>

=over 4

=item Maybe[TFBuffer] $run_options

TODO

=item ArrayRef[TFOutput] $inputs

TODO

=item ArrayRef[TFTensor] $input_values

TODO

=item ArrayRef[TFOutput] $outputs

TODO

=item ArrayRef[TFTensor] $output

TODO

=item ArrayRef[TFOperation] $target_opers

TODO

=item Maybe[TFBuffer] $run_metadata

TODO

=item L<TFStatus|AI::TensorFlow::Libtensorflow::Lib::Types/TFStatus> $status

TODO

=back

B<C API>: L<< C<TF_SessionRun>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SessionRun >>

=head2 Close

TODO

B<C API>: L<< C<TF_CloseSession>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_CloseSession >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
