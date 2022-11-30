package AI::TensorFlow::Libtensorflow::Graph;
$AI::TensorFlow::Libtensorflow::Graph::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewGraph' => 'New' ] => [] => 'TF_Graph' );

$ffi->attach( [ 'DeleteGraph' => 'DESTROY' ] => [ arg 'TF_Graph' => 'self' ], 'void' );

$ffi->attach( [ 'GraphImportGraphDef'  => 'ImportGraphDef'  ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Buffer' => 'graph_def',
	arg 'TF_ImportGraphDefOptions' => 'options',
	arg 'TF_Status' => 'status',
] => 'void' );

$ffi->attach( [ 'GraphOperationByName' => 'OperationByName' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'string'   => 'oper_name',
] => 'TF_Operation' );

$ffi->attach( [ 'GraphSetTensorShape' => 'SetTensorShape' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'tf_dims_buffer' => [qw(dims num_dims)],
	arg 'TF_Status' => 'status',
] => 'void' );

$ffi->attach( ['GraphGetTensorShape' => 'GetTensorShape'] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'tf_dims_buffer' => [qw(dims num_dims)],
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach( [ 'GraphGetTensorNumDims' => 'GetTensorNumDims' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'TF_Status' => 'status',
] => 'int');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Graph

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TF_NewGraph>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewGraph >>

=head1 METHODS

=head2 ImportGraphDef

B<C API>: L<< C<TF_GraphImportGraphDef>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphImportGraphDef >>

=head2 OperationByName

B<C API>: L<< C<TF_GraphOperationByName>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphOperationByName >>

=head2 SetTensorShape

B<C API>: L<< C<TF_GraphSetTensorShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphSetTensorShape >>

=head2 GetTensorShape

B<C API>: L<< C<TF_GraphGetTensorShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphGetTensorShape >>

=head2 GetTensorNumDims

B<C API>: L<< C<TF_GraphGetTensorNumDims>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphGetTensorNumDims >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteGraph>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteGraph >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
