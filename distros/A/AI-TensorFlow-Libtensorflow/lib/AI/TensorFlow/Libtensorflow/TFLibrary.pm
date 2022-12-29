package AI::TensorFlow::Libtensorflow::TFLibrary;
# ABSTRACT: TensorFlow dynamic library handle and ops
$AI::TensorFlow::Libtensorflow::TFLibrary::VERSION = '0.0.4';
use strict;
use warnings;

use AI::TensorFlow::Libtensorflow::Lib qw(arg);
my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;

$ffi->attach( [ 'LoadLibrary' => 'LoadLibrary' ] => [
	arg string => 'library_filename',
	arg TF_Status => 'status',
] => 'TF_Library' => sub {
	my ($xs, $class, @rest) = @_;
	$xs->(@rest);
} );

$ffi->attach( [ 'GetOpList' => 'GetOpList' ] => [
	arg TF_Library => 'lib_handle'
] => 'TF_Buffer' );

$ffi->attach( [ 'DeleteLibraryHandle' => 'DESTROY' ] => [
	arg TF_Library => 'lib_handle'
] => 'void' );

$ffi->attach( 'GetAllOpList' => [], 'TF_Buffer' );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::TFLibrary - TensorFlow dynamic library handle and ops

=head1 CONSTRUCTORS

=head2 LoadLibrary

B<C API>: L<< C<TF_LoadLibrary>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_LoadLibrary >>

=head1 CLASS METHODS

=head2 GetAllOpList

=over 2

C<<<
GetAllOpList()
>>>

=back

  my $buf = AI::TensorFlow::Libtensorflow::TFLibrary->GetAllOpList();
  cmp_ok $buf->length, '>', 0, 'Got OpList buffer';

B<Returns>

=over 4

=item L<TFBuffer|AI::TensorFlow::Libtensorflow::Lib::Types/TFBuffer>

Contains a serialized C<OpList> proto for ops registered in this address space.

=back

B<C API>: L<< C<TF_GetAllOpList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GetAllOpList >>

=head1 METHODS

=head2 GetOpList

B<C API>: L<< C<TF_GetOpList>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_GetOpList >>

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteLibraryHandle>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteLibraryHandle >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
