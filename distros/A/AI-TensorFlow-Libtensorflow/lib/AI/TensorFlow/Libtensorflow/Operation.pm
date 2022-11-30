package AI::TensorFlow::Libtensorflow::Operation;
# ABSTRACT: An operation
$AI::TensorFlow::Libtensorflow::Operation::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

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
	# TODO (simplify API)
	arg 'opaque' => 'TF_Output oper',
] => 'TF_DataType' );

$ffi->attach( [ 'OperationNumInputs' => 'NumInputs' ] => [
	arg 'TF_Operation' => 'oper',
] => 'int' );

$ffi->attach( [ 'OperationInputType'  => 'InputType' ] => [
	# TODO (simplify API)
	arg 'opaque' => 'TF_Input oper_in',
] => 'TF_DataType');

$ffi->attach( [ 'OperationNumControlInputs' => 'NumControlInputs' ] => [
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
	arg 'opaque' => 'TF_Input oper_in',
] => ( 'opaque' , 'TF_Output' )[0] );

$ffi->attach( [ 'OperationAllInputs' => 'AllInputs' ] => [
	arg 'TF_Operation' => 'oper',
	# TODO make OutputArray
	arg 'opaque' => 'TF_Output* inputs',
	arg 'int' => 'max_inputs',
] => 'void' );

$ffi->attach( [ 'OperationOutputNumConsumers' => 'OutputNumConsumers' ] => [
	# TODO
	arg 'opaque' => 'TF_Output oper_out',
], 'int');

$ffi->attach( [ 'OperationOutputConsumers'  => 'OutputConsumers' ] => [
	# TODO simplify API
	arg 'opaque' => 'TF_Output oper_out',
	arg 'opaque' => 'TF_Input* consumers',
	arg 'int'    => 'max_consumers',
] => 'int');


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
sub _adef {
	$adef;
}
sub _as_array {
	my $class = shift;
	my $array = $class->_adef->create(0 + @_);
	for my $idx (0..@_-1) {
		next unless defined $_[$idx];
		$array->[$idx]->p($ffi->cast('TF_Operation', 'opaque', $_[$idx]));
	}
	$array;
}

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

=head1 METHODS

=head2 OutputListLength

B<C API>: L<< C<TF_OperationOutputListLength>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationOutputListLength >>

=head2 InputListLength

B<C API>: L<< C<TF_OperationInputListLength>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationInputListLength >>

=head2 Input

B<C API>: L<< C<TF_OperationInput>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationInput >>

=head2 AllInputs

B<C API>: L<< C<TF_OperationAllInputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_OperationAllInputs >>

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
