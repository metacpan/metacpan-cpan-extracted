package AI::TensorFlow::Libtensorflow::OperationDescription;
# ABSTRACT: Operation being built
$AI::TensorFlow::Libtensorflow::OperationDescription::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef'
        => 'tf_attr_string_buffer'
);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrPtrLenSizeArrayRefScalar'
        => 'tf_attr_string_list'
);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFInt64SizeArrayRef'
        => 'tf_attr_int_list'
);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFFloat32SizeArrayRef'
	=> 'tf_attr_float_list'
);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFBoolSizeArrayRef'
	=> 'tf_attr_bool_list',
);

$ffi->attach( [ 'NewOperation' => 'New' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'string'   => 'op_type',
	arg 'string'   => 'oper_name',
] => 'TF_OperationDescription' );

$ffi->attach( [ 'NewOperationLocked' => 'NewLocked' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'string'   => 'op_type',
	arg 'string'   => 'oper_name',
] => 'TF_OperationDescription' );

$ffi->attach( 'SetDevice' => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'device',
] => 'void');

$ffi->attach( 'AddInput' => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Output' => 'input',
] => 'void');

$ffi->attach( AddInputList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Output_array' => 'inputs',
	arg 'int' => 'num_inputs'
] => 'void' => sub {
	my ($xs, $self, $inputs) = @_;
	my $inputs_a    = AI::TensorFlow::Libtensorflow::Output->_as_array(@$inputs);
	$xs->( $self, $inputs_a, $inputs_a->count );
});

$ffi->attach( AddControlInput => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Operation' => 'input',
] => 'void');

$ffi->attach( ColocateWith => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Operation' => 'op',
] => 'void');

$ffi->attach( SetAttrString => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg tf_attr_string_buffer => [qw(value length)],
] => 'void');

$ffi->attach(SetAttrStringList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_string_list' => [qw(values lengths num_values)],
] => 'void');

$ffi->attach( SetAttrInt => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg int64_t  => 'value',
] => 'void');

$ffi->attach( SetAttrIntList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_int_list' => [qw(values num_values)],
] => 'void');

$ffi->attach( SetAttrFloat => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'float' => 'value',
] => 'void');

$ffi->attach(SetAttrFloatList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_float_list' => [qw(values num_values)],
] => 'void');

$ffi->attach( SetAttrBool => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'unsigned char' => 'value',
] => 'void');

$ffi->attach( SetAttrBoolList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_bool_list' => [qw(values num_values)],
] => 'void');

$ffi->attach(SetAttrType => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'TF_DataType' => 'value',
] => 'void');

$ffi->attach( SetAttrTypeList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',

	# TODO
	arg 'opaque' => 'values',
	#arg 'TF_DataType*' => 'values',
	arg 'int' => 'num_values',
]);

$ffi->attach( SetAttrPlaceholder => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'string' => 'placeholder',
] => 'void');

$ffi->attach( SetAttrFuncName => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_string_buffer' => [qw(value length)],
] => 'void');

$ffi->attach( SetAttrShape => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_dims_buffer' => [qw(dims num_dims)],
] => 'void');

$ffi->attach( SetAttrShapeList => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	# TODO
	arg 'opaque' => 'const int64_t* const* dims',
	arg 'opaque' => 'const int* num_dims',
	arg 'int'    => 'num_shapes',
]);

$ffi->attach(SetAttrTensorShapeProto => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_tensor_shape_proto_buffer' => [qw(proto proto_len)],
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach( SetAttrTensorShapeProtoList => [
	# TODO
] => 'void');

$ffi->attach( SetAttrTensor => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'TF_Tensor' => 'value',
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach( SetAttrTensorList => [
	# TODO
] => 'void');

$ffi->attach(SetAttrValueProto => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'string' => 'attr_name',
	arg 'tf_attr_value_proto_buffer' => [qw(proto proto_len)],
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach(FinishOperation => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Status' => 'status',
] => 'TF_Operation');

$ffi->attach(FinishOperationLocked => [
	arg 'TF_OperationDescription' => 'desc',
	arg 'TF_Status' => 'status',
] => 'TF_Operation');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::OperationDescription - Operation being built

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TF_NewOperation>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewOperation >>

=head2 NewLocked

B<C API>: L<< C<TF_NewOperationLocked>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewOperationLocked >>

=head1 METHODS

=head2 SetDevice

B<C API>: L<< C<TF_SetDevice>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetDevice >>

=head2 AddInput

B<C API>: L<< C<TF_AddInput>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_AddInput >>

=head2 AddInputList

B<C API>: L<< C<TF_AddInputList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_AddInputList >>

=head2 AddControlInput

B<C API>: L<< C<TF_AddControlInput>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_AddControlInput >>

=head2 ColocateWith

B<C API>: L<< C<TF_ColocateWith>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ColocateWith >>

=head2 SetAttrString

B<C API>: L<< C<TF_SetAttrString>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrString >>

=head2 SetAttrStringList

B<C API>: L<< C<TF_SetAttrStringList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrStringList >>

=head2 SetAttrInt

B<C API>: L<< C<TF_SetAttrInt>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrInt >>

=head2 SetAttrIntList

B<C API>: L<< C<TF_SetAttrIntList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrIntList >>

=head2 SetAttrFloat

B<C API>: L<< C<TF_SetAttrFloat>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrFloat >>

=head2 SetAttrFloatList

B<C API>: L<< C<TF_SetAttrFloatList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrFloatList >>

=head2 SetAttrBool

B<C API>: L<< C<TF_SetAttrBool>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrBool >>

=head2 SetAttrBoolList

B<C API>: L<< C<TF_SetAttrBoolList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrBoolList >>

=head2 SetAttrType

B<C API>: L<< C<TF_SetAttrType>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrType >>

=head2 SetAttrTypeList

B<C API>: L<< C<TF_SetAttrTypeList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrTypeList >>

=head2 SetAttrPlaceholder

B<C API>: L<< C<TF_SetAttrPlaceholder>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrPlaceholder >>

=head2 SetAttrFuncName

B<C API>: L<< C<TF_SetAttrFuncName>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrFuncName >>

=head2 SetAttrShape

B<C API>: L<< C<TF_SetAttrShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrShape >>

=head2 SetAttrShapeList

B<C API>: L<< C<TF_SetAttrShapeList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrShapeList >>

=head2 SetAttrTensorShapeProto

B<C API>: L<< C<TF_SetAttrTensorShapeProto>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrTensorShapeProto >>

=head2 SetAttrTensorShapeProtoList

B<C API>: L<< C<TF_SetAttrTensorShapeProtoList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrTensorShapeProtoList >>

=head2 SetAttrTensor

B<C API>: L<< C<TF_SetAttrTensor>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrTensor >>

=head2 SetAttrTensorList

B<C API>: L<< C<TF_SetAttrTensorList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrTensorList >>

=head2 SetAttrValueProto

B<C API>: L<< C<TF_SetAttrValueProto>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_SetAttrValueProto >>

=head2 FinishOperation

B<C API>: L<< C<TF_FinishOperation>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_FinishOperation >>

=head2 FinishOperationLocked

B<C API>: L<< C<TF_FinishOperationLocked>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_FinishOperationLocked >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
