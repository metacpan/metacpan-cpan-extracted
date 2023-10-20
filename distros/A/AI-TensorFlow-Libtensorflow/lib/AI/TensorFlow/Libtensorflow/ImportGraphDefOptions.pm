package AI::TensorFlow::Libtensorflow::ImportGraphDefOptions;
# ABSTRACT: Holds options that can be passed to ::Graph::ImportGraphDef
$AI::TensorFlow::Libtensorflow::ImportGraphDefOptions::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewImportGraphDefOptions' => 'New' ] => [] => 'TF_ImportGraphDefOptions' );

$ffi->attach( [ 'DeleteImportGraphDefOptions' => 'DESTROY' ] => [
	arg 'TF_ImportGraphDefOptions' => 'self',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefOptionsSetPrefix' => 'SetPrefix' ] => [
	arg 'TF_ImportGraphDefOptions' => 'opts',
	arg 'string' => 'prefix',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefOptionsAddInputMapping' => 'AddInputMapping' ] => [
	arg 'TF_ImportGraphDefOptions' => 'opts',
	arg 'string' => 'src_name',
	arg 'int' => 'src_index',
	arg 'TF_Output' => 'dst',
] => 'void');

$ffi->attach( [ 'ImportGraphDefOptionsAddReturnOutput' => 'AddReturnOutput' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
	arg string => 'oper_name',
	arg int => 'index',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefOptionsNumReturnOutputs' => 'NumReturnOutputs' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
] => 'int');

$ffi->attach( [ 'ImportGraphDefOptionsAddReturnOperation' => 'AddReturnOperation' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
	arg string => 'oper_name',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefOptionsNumReturnOperations' => 'NumReturnOperations' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
] => 'int' );

$ffi->attach( [ 'ImportGraphDefOptionsAddControlDependency' => 'AddControlDependency' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
	arg TF_Operation => 'oper',
] => 'void' );

$ffi->attach( [ 'ImportGraphDefOptionsRemapControlDependency' => 'RemapControlDependency' ] => [
	arg TF_ImportGraphDefOptions => 'opts',
	arg string => 'src_name',
	arg TF_Operation => 'dst',
] => 'void' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::ImportGraphDefOptions - Holds options that can be passed to ::Graph::ImportGraphDef

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TF_NewImportGraphDefOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewImportGraphDefOptions >>

=head1 METHODS

=head2 SetPrefix

B<C API>: L<< C<TF_ImportGraphDefOptionsSetPrefix>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsSetPrefix >>

=head2 AddInputMapping

B<C API>: L<< C<TF_ImportGraphDefOptionsAddInputMapping>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsAddInputMapping >>

=head2 AddReturnOutput

B<C API>: L<< C<TF_ImportGraphDefOptionsAddReturnOutput>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsAddReturnOutput >>

=head2 NumReturnOutputs

B<C API>: L<< C<TF_ImportGraphDefOptionsNumReturnOutputs>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsNumReturnOutputs >>

=head2 AddReturnOperation

B<C API>: L<< C<TF_ImportGraphDefOptionsAddReturnOperation>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsAddReturnOperation >>

=head2 NumReturnOperations

B<C API>: L<< C<TF_ImportGraphDefOptionsNumReturnOperations>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsNumReturnOperations >>

=head2 AddControlDependency

B<C API>: L<< C<TF_ImportGraphDefOptionsAddControlDependency>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsAddControlDependency >>

=head2 RemapControlDependency

B<C API>: L<< C<TF_ImportGraphDefOptionsRemapControlDependency>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_ImportGraphDefOptionsRemapControlDependency >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteImportGraphDefOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteImportGraphDefOptions >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
