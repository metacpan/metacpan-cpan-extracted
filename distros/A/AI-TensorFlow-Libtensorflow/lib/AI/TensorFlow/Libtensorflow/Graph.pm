package AI::TensorFlow::Libtensorflow::Graph;
# ABSTRACT: A TensorFlow computation, represented as a dataflow graph
$AI::TensorFlow::Libtensorflow::Graph::VERSION = '0.0.4';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);
use AI::TensorFlow::Libtensorflow::Buffer;
use AI::TensorFlow::Libtensorflow::Output;
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

$ffi->attach( [ 'GraphImportGraphDefWithResults' => 'ImportGraphDefWithResults' ] => [
    arg TF_Graph => 'graph',
    arg TF_Buffer => 'graph_def',
    arg TF_ImportGraphDefOptions => 'options',
    arg TF_Status => 'status',
] => 'TF_ImportGraphDefResults');

$ffi->attach( [ 'GraphImportGraphDefWithReturnOutputs' => 'ImportGraphDefWithReturnOutputs' ] => [
    arg TF_Graph => 'graph',
    arg TF_Buffer => 'graph_def',
    arg TF_ImportGraphDefOptions => 'options',
    arg TF_Output_struct_array => 'return_outputs',
    arg int => 'num_return_outputs',
    arg TF_Status => 'status',
] => 'void' => sub {
	my ($xs, $graph, $graph_def, $options, $status) = @_;
	my $num_return_outputs = $options->NumReturnOutputs;
	return [] if $num_return_outputs == 0;

	my $return_outputs = AI::TensorFlow::Libtensorflow::Output->_adef->create( $num_return_outputs );
	$xs->($graph, $graph_def, $options,
		$return_outputs, $num_return_outputs,
		$status);
	return AI::TensorFlow::Libtensorflow::Output->_from_array( $return_outputs );
});

$ffi->attach( [ 'GraphOperationByName' => 'OperationByName' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'string'   => 'oper_name',
] => 'TF_Operation' );

$ffi->attach( [ 'GraphSetTensorShape' => 'SetTensorShape' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'tf_dims_buffer' => [qw(dims num_dims)],
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach( ['GraphGetTensorShape' => 'GetTensorShape'] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'tf_dims_buffer' => [qw(dims num_dims)],
	arg 'TF_Status' => 'status',
] => 'void' => sub {
	my ($xs, @rest) = @_;
	my ($graph, $output, $status) = @rest;
	my $dims = [ (0)x($graph->GetTensorNumDims($output, $status)) ];
	$xs->($graph, $output, $dims, $status);
	return $dims;
});

$ffi->attach( [ 'GraphGetTensorNumDims' => 'GetTensorNumDims' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'output',
	arg 'TF_Status' => 'status',
] => 'int');

$ffi->attach( [ 'GraphNextOperation' => 'NextOperation' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'size_t*'  => 'pos',
] => 'TF_Operation');

$ffi->attach( [ 'UpdateEdge' => 'UpdateEdge' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Output' => 'new_src',
	arg 'TF_Input'  => 'dst',
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach([ 'GraphToGraphDef' => 'ToGraphDef' ] => [
	arg 'TF_Graph' => 'graph',
	arg 'TF_Buffer' => 'output_graph_def',
	arg 'TF_Status' => 'status',
] => 'void');

$ffi->attach( [ 'GraphGetOpDef' => 'GetOpDef' ] => [
	arg TF_Graph => 'graph',
	arg string => 'op_name',
	arg TF_Buffer => 'output_op_def',
	arg TF_Status => 'status',
] => 'void');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Graph - A TensorFlow computation, represented as a dataflow graph

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow::Graph' => 'Graph';

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 New

=over 2

C<<<
New()
>>>

=back

  my $graph = Graph->New;
  ok $graph, 'created graph';

B<Returns>

=over 4

=item L<TFGraph|AI::TensorFlow::Libtensorflow::Lib::Types/TFGraph>

An empty graph.

=back

B<C API>: L<< C<TF_NewGraph>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewGraph >>

=head1 METHODS

=head2 ImportGraphDef

B<C API>: L<< C<TF_GraphImportGraphDef>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphImportGraphDef >>

=head2 ImportGraphDefWithResults

B<C API>: L<< C<TF_GraphImportGraphDefWithResults>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphImportGraphDefWithResults >>

=head2 ImportGraphDefWithReturnOutputs

B<C API>: L<< C<TF_GraphImportGraphDefWithReturnOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphImportGraphDefWithReturnOutputs >>

=head2 OperationByName

B<C API>: L<< C<TF_GraphOperationByName>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphOperationByName >>

=head2 SetTensorShape

B<C API>: L<< C<TF_GraphSetTensorShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphSetTensorShape >>

=head2 GetTensorShape

B<C API>: L<< C<TF_GraphGetTensorShape>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphGetTensorShape >>

=head2 GetTensorNumDims

B<C API>: L<< C<TF_GraphGetTensorNumDims>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphGetTensorNumDims >>

=head2 NextOperation

B<C API>: L<< C<TF_GraphNextOperation>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphNextOperation >>

=head2 UpdateEdge

B<C API>: L<< C<TF_UpdateEdge>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_UpdateEdge >>

=head2 ToGraphDef

B<C API>: L<< C<TF_GraphToGraphDef>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphToGraphDef >>

=head2 GetOpDef

B<C API>: L<< C<TF_GraphGetOpDef>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GraphGetOpDef >>

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
