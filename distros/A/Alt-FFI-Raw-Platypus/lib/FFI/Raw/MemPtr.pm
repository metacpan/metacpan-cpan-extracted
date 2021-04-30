package FFI::Raw::MemPtr;

use strict;
use warnings;
use base qw( FFI::Platypus::Legacy::Raw::MemPtr FFI::Raw::Ptr );

# ABSTRACT: FFI::Platypus::Legacy::Raw memory pointer type
our $VERSION = '0.32';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Raw::MemPtr - FFI::Platypus::Legacy::Raw memory pointer type

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A B<FFI::Raw::MemPtr> represents a memory pointer which can be passed to
functions taking a C<FFI::Raw::ptr> argument.

The allocated memory is automatically deallocated once the object is not in use
anymore.

=head1 CONSTRUCTORS

=head2 new

 FFI::Raw::MemPtr->new( $length );

Allocate a new C<FFI::Raw::MemPtr> of size C<$length> bytes.

=head2 new_from_buf

 my $memptr = FFI::Platypus::Legacy::Raw::MemPtr->new_from_buf( $buffer, $length );

Allocate a new C<FFI::Platypus::Legacy::Raw::MemPtr> of size C<$length> bytes and copy C<$buffer>
into it. This can be used, for example, to pass a pointer to a function that
takes a C struct pointer, by using C<pack()> or the L<Convert::Binary::C> module
to create the actual struct content.

For example, consider the following C code

 struct some_struct {
   int some_int;
   char some_str[];
 };
 
 extern void take_one_struct(struct some_struct *arg) {
   if (arg->some_int == 42)
     puts(arg->some_str);
 }

It can be called using FFI::Platypus::Legacy::Raw as follows:

 use FFI::Platypus::Legacy::Raw;
 
 my $packed = pack('ix![p]p', 42, 'hello');
 my $arg = FFI::Platypus::Legacy::Raw::MemPtr->new_from_buf($packed, length $packed);
 
 my $take_one_struct = FFI::Platypus::Legacy::Raw->new(
   $shared, 'take_one_struct',
   FFI::Platypus::Legacy::Raw::void, FFI::Platypus::Legacy::Raw::ptr
 );
 
 $take_one_struct->($arg);

Which would print C<hello>.

=head2 new_from_ptr

 my $memptr = FFI::Platypus::Legacy::Raw::MemPtr->new_from_ptr( $ptr );

Allocate a new C<FFI::Platypus::Legacy::Raw::MemPtr> pointing to the C<$ptr>, which can be either
a C<FFI::Platypus::Legacy::Raw::MemPtr> or a pointer returned by another function.

This is the C<FFI::Platypus::Legacy::Raw> equivalent of a pointer to a pointer.

=head1 METHODS

=head2 to_perl_str

 my $memptr = FFI::Platypus::Legacy::Raw::MemPtr->to_perl_str;
 my $memptr = FFI::Platypus::Legacy::Raw::MemPtr->to_perl_str( $length );

Convert a C<FFI::Platypus::Legacy::Raw::MemPtr> to a Perl string. If C<$length> is not provided,
the length of the string will be computed using C<strlen()>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
