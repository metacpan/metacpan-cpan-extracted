package AI::TensorFlow::Libtensorflow::Buffer;
# ABSTRACT: Buffer that holds pointer to data with length
$AI::TensorFlow::Libtensorflow::Buffer::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib qw(arg);

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);
use FFI::C;
FFI::C->ffi($ffi);
$ffi->load_custom_type('AI::TensorFlow::Libtensorflow::Lib::FFIType::TFPtrSizeScalarRef'
	=> 'tf_buffer_buffer'
);

use FFI::Platypus::Buffer;
use FFI::Platypus::Memory;





FFI::C->struct( 'TF_Buffer' => [
	data => 'opaque',
	length => 'size_t',
	_data_deallocator => 'opaque', # data_deallocator_t
	# this does not work?
	#_data_deallocator => 'data_deallocator_t',
]);
use Sub::Delete;
delete_sub 'DESTROY';

sub data_deallocator {
	my ($self, $coderef) = shift;

	return $self->{_data_deallocator_closure} unless $coderef;

	my $closure = $ffi->closure( $coderef );

	$closure->sticky;
	$self->{_data_deallocator_closure} = $closure;

	my $opaque = $ffi->cast('data_deallocator_t', 'opaque', $closure);
	$self->_data_deallocator( $opaque );
}


$ffi->attach( [ 'NewBuffer' => 'New' ] => [] => 'TF_Buffer' );

$ffi->attach( [ 'NewBufferFromString' => 'NewFromString' ] => [
	arg 'tf_buffer_buffer' => [qw(proto proto_len)]
] => 'TF_Buffer' => sub {
	my ($xs, $class, @rest) = @_;
	$xs->(@rest);
});


$ffi->attach( [ 'DeleteBuffer' => 'DESTROY' ] => [ 'TF_Buffer' ], 'void' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Buffer - Buffer that holds pointer to data with length

=head1 SYNOPSIS

  use aliased 'AI::TensorFlow::Libtensorflow::Buffer' => 'Buffer';

=head1 DESCRIPTION

C<TFBuffer> is a data structure that stores a pointer to a block of data, the
length of the data, and optionally a deallocator function for memory
management.

This structure is typically used in C<libtensorflow> to store the data for a
serialized protocol buffer.

=head1 CONSTRUCTORS

=head2 New

=over 2

C<<<
New()
>>>

=back

  my $buffer = Buffer->New();

  ok $buffer, 'created an empty buffer';
  is $buffer->length, 0, 'with a length of 0';

Create an empty buffer. Useful for passing as an output parameter.

B<Returns>

=over 4

=item L<TFBuffer|AI::TensorFlow::Libtensorflow::Lib::Types/TFBuffer>

Empty buffer.

=back

B<C API>: L<< C<TF_NewBuffer>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewBuffer >>

=head2 NewFromString

=over 2

C<<<
NewFromString( $proto )
>>>

=back

Makes a copy of the input and sets an appropriate deallocator. Useful for
passing in read-only, input protobufs.

  my $data = 'bytes';
  my $buffer = Buffer->NewFromString(\$data);
  ok $buffer, 'create buffer from string';
  is $buffer->length, bytes::length($data), 'same length as string';

B<Parameters>

=over 4

=item ScalarRef[Bytes] $proto

=back

B<Returns>

=over 4

=item L<TFBuffer|AI::TensorFlow::Libtensorflow::Lib::Types/TFBuffer>

Contains a copy of the input data from C<$proto>.

=back

B<C API>: L<< C<TF_NewBufferFromString>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_NewBufferFromString >>

=head1 ATTRIBUTES

=head2 data

An C<opaque> pointer to the buffer.

=head2 length

Length of the buffer as a C<size_t>.

=head2 data_deallocator

A C<CodeRef> for the deallocator.

=head1 DESTRUCTORS

=head2 DESTROY

B<C API>: L<< C<TF_DeleteBuffer>|AI::TensorFlow::Libtensorflow::Manual::CAPI/TF_DeleteBuffer >>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
