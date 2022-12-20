package AI::TensorFlow::Libtensorflow::Operation;
# ABSTRACT: An operation
$AI::TensorFlow::Libtensorflow::Operation::VERSION = '0.0.3';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
use AI::TensorFlow::Libtensorflow::Output;
use AI::TensorFlow::Libtensorflow::Input;

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

use FFI::C::ArrayDef;
my $adef = FFI::C::ArrayDef->new(
	$ffi,
	name => 'TF_Operation_array',
	members => [
		FFI::C::StructDef->new(
			$ffi,
			members => [
				p => 'opaque'
			]
		)
	],
);
sub _adef { $adef; }
sub _as_array {
	my $class = shift;
	my $array = $class->_adef->create(0 + @_);
	for my $idx (0..@_-1) {
		next unless defined $_[$idx];
		$array->[$idx]->p($ffi->cast('TF_Operation', 'opaque', $_[$idx]));
	}
	$array;
}
sub _from_array {
	my ($class, $array) = @_;
	[
		map {
			$ffi->cast('opaque', 'TF_Operation', $array->[$_]->p);
		} 0..$array->count-1
	]
}

$ffi->attach( [ 'OperationName' => 'Name' ], [
	arg 'TF_Operation' => 'oper',
] => 'string');

$ffi->attach( [ 'OperationOpType' => 'OpType' ], [
	arg 'TF_Operation' => 'oper',
] => 'string');

$ffi->attach( [ 'OperationDevice' => 'Device' ], [
	arg 'TF_Operation' => 'oper',
] => 'string');

$ffi->attach( [ 'OperationNumOutputs' => 'NumOutputs' ], [
	arg 'TF_Operation' => 'oper',
] => 'int');

$ffi->attach( [ 'OperationOutputType' => 'OutputType' ] => [
	arg 'TF_Output' => 'oper_out',
] => 'TF_DataType' => sub {
	my ($xs, $self, $output) = @_;
	# TODO coerce from LibtfPartialOutput here
	$xs->($output);
} );

$ffi->attach( [ 'OperationNumInputs' => 'NumInputs' ] => [
	arg 'TF_Operation' => 'oper',
] => 'int' );

$ffi->attach( [ 'OperationInputType'  => 'InputType' ] => [
	arg 'TF_Input' => 'oper_in',
] => 'TF_DataType' => sub {
	my ($xs, $self, $input) = @_;
	# TODO coerce from LibtfPartialInput here
	$xs->($input);
});

$ffi->attach( [ 'OperationNumControlInputs' => 'NumControlInputs' ] => [
	arg 'TF_Operation' => 'oper',
] => 'int' );

$ffi->attach( [ 'OperationNumControlOutputs' => 'NumControlOutputs' ] => [
	arg 'TF_Operation' => 'oper',
] => 'int' );

$ffi->attach( [ OperationOutputListLength => 'OutputListLength' ] => [
	arg 'TF_Operation' => 'oper',
	arg 'string' => 'arg_name',
	arg 'TF_Status' => 'status',
] => 'int');

$ffi->attach( [ 'OperationInputListLength' => 'InputListLength' ] => [
	arg 'TF_Operation' => 'oper',
	arg 'string' => 'arg_name',
	arg 'TF_Status' => 'status',
] => 'int' );

$ffi->attach( [ 'OperationInput' => 'Input' ] => [
	arg 'TF_Input' => 'oper_in',
] => 'TF_Output' => sub {
	my ($xs, $self, $input) = @_;
	# TODO coerce from LibtfPartialInput here
	$xs->($input);
});

$ffi->attach( [ 'OperationAllInputs' => 'AllInputs' ] => [
	arg 'TF_Operation' => 'oper',
	# TODO make OutputArray
	arg 'TF_Output_struct_array' => 'inputs',
	arg 'int' => 'max_inputs',
] => 'void' => sub {
	my ($xs, $oper) = @_;
	my $max_inputs = $oper->NumInputs;
	my $inputs = AI::TensorFlow::Libtensorflow::Output->_adef->create(0 + $max_inputs);
	$xs->($oper, $inputs, $max_inputs);
	return AI::TensorFlow::Libtensorflow::Output->_from_array($inputs);
});

$ffi->attach( [ 'OperationGetControlInputs' => 'GetControlInputs' ] => [
	arg 'TF_Operation' => 'oper',
	arg 'TF_Operation_array' => 'control_inputs',
	arg 'int' => 'max_control_inputs',
] => 'void' => sub {
	my ($xs, $oper) = @_;
	my $max_inputs = $oper->NumControlInputs;
	return [] if $max_inputs == 0;
	my $inputs = AI::TensorFlow::Libtensorflow::Operation->_adef->create(0 + $max_inputs);
	$xs->($oper, $inputs, $max_inputs);
	return AI::TensorFlow::Libtensorflow::Operation->_from_array($inputs);
});

$ffi->attach( [ 'OperationGetControlOutputs' => 'GetControlOutputs' ] => [
	arg 'TF_Operation' => 'oper',
	arg 'TF_Operation_array' => 'control_outputs',
	arg 'int' => 'max_control_outputs',
] => 'void' => sub {
	my ($xs, $oper) = @_;
	my $max_outputs = $oper->NumControlOutputs;
	return [] if $max_outputs == 0;
	my $outputs = AI::TensorFlow::Libtensorflow::Operation->_adef->create(0 + $max_outputs);
	$xs->($oper, $outputs, $max_outputs);
	return AI::TensorFlow::Libtensorflow::Operation->_from_array($outputs);
});

$ffi->attach( [ 'OperationOutputNumConsumers' => 'OutputNumConsumers' ] => [
	arg 'TF_Output' => 'oper_out',
], 'int' => sub {
	my ($xs, $self, $output) = @_;
	# TODO coerce from LibtfPartialOutput here
	$xs->($output);
});

$ffi->attach( [ 'OperationOutputConsumers'  => 'OutputConsumers' ] => [
	# TODO simplify API
	arg 'TF_Output' => 'oper_out',
	arg 'TF_Input_struct_array' => 'consumers',
	arg 'int'                   => 'max_consumers',
] => 'int' => sub {
	my ($xs, $self, $output) = @_;
	my $max_consumers = $self->OutputNumConsumers( $output );
	my $consumers = AI::TensorFlow::Libtensorflow::Input->_adef->create( $max_consumers );
	my $count = $xs->($output, $consumers, $max_consumers);
	return AI::TensorFlow::Libtensorflow::Input->_from_array( $consumers );
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Operation - An operation

=head1 ATTRIBUTES

=head2 Name

B<C API>: L<< C<TF_OperationName>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationName >>

=head2 OpType

B<C API>: L<< C<TF_OperationOpType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOpType >>

=head2 Device

B<C API>: L<< C<TF_OperationDevice>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationDevice >>

=head2 NumOutputs

B<C API>: L<< C<TF_OperationNumOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationNumOutputs >>

=head2 OutputType

B<C API>: L<< C<TF_OperationOutputType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOutputType >>

=head2 NumInputs

B<C API>: L<< C<TF_OperationNumInputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationNumInputs >>

=head2 InputType

B<C API>: L<< C<TF_OperationInputType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationInputType >>

=head2 NumControlInputs

B<C API>: L<< C<TF_OperationNumControlInputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationNumControlInputs >>

=head2 NumControlOutputs

B<C API>: L<< C<TF_OperationNumControlOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationNumControlOutputs >>

=head1 METHODS

=head2 OutputListLength

B<C API>: L<< C<TF_OperationOutputListLength>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOutputListLength >>

=head2 InputListLength

B<C API>: L<< C<TF_OperationInputListLength>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationInputListLength >>

=head2 Input

B<C API>: L<< C<TF_OperationInput>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationInput >>

=head2 AllInputs

B<C API>: L<< C<TF_OperationAllInputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationAllInputs >>

=head2 GetControlInputs

B<C API>: L<< C<TF_OperationGetControlInputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationGetControlInputs >>

=head2 GetControlOutputs

B<C API>: L<< C<TF_OperationGetControlOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationGetControlOutputs >>

=head2 OutputNumConsumers

B<C API>: L<< C<TF_OperationOutputNumConsumers>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOutputNumConsumers >>

=head2 OutputConsumers

B<C API>: L<< C<TF_OperationOutputConsumers>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOutputConsumers >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
