package AI::TensorFlow::Libtensorflow::ImportGraphDefOptions;
$AI::TensorFlow::Libtensorflow::ImportGraphDefOptions::VERSION = '0.0.2';
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);

$ffi->attach( [ 'NewImportGraphDefOptions' => 'New' ] => [] => 'TF_ImportGraphDefOptions' );

$ffi->attach( [ 'DeleteImportGraphDefOptions' => 'DESTROY' ] => [
	arg 'TF_ImportGraphDefOptions' => 'self',
] => 'void' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::ImportGraphDefOptions

=head1 CONSTRUCTORS

=head2 New

B<C API>: L<< C<TF_NewImportGraphDefOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewImportGraphDefOptions >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteImportGraphDefOptions>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteImportGraphDefOptions >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
