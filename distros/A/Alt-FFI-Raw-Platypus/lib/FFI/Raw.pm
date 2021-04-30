package FFI::Raw;

use strict;
use warnings;
use base qw( FFI::Platypus::Legacy::Raw );
use FFI::Raw::Callback;
use FFI::Raw::Ptr;
use FFI::Raw::MemPtr;

# ABSTRACT: Perl bindings to the portable FFI library (libffi)
our $VERSION = '0.32';

foreach my $function (qw( memptr callback void int uint short ushort long ulong int64 uint64 char uchar float double str ptr ))
{
  no strict 'refs';
  *$function = *{"FFI::Platypus::Legacy::Raw::$function"};
}

sub platypus
{
  require Carp;
  Carp::croak("platypus not available for FFI::Raw interface");
}

sub attach
{
  require Carp;
  Carp::croak("attach not available for FFI::Raw interface");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Raw - Perl bindings to the portable FFI library (libffi)

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use FFI::Raw;
 
 my $cos = FFI::Raw->new(
   'libm.so', 'cos',
   FFI::Raw::double, # return value
   FFI::Raw::double  # arg #1
 );
 
 say $cos->call(2.0);

=head1 DESCRIPTION

B<FFI::Raw> provides a low-level foreign function interface (FFI) for Perl based
on L<libffi|http://sourceware.org/libffi/>. In essence, it can access and call
functions exported by shared libraries without the need to write C/XS code.

Dynamic symbols can be automatically resolved at runtime so that the only
information needed to use B<FFI::Raw> is the name (or path) of the target
library, the name of the function to call and its signature (though it is also
possible to pass a function pointer obtained, for example, using L<DynaLoader>).

Note that this module has nothing to do with L<FFI>.

=head1 CONSTRUCTORS

=head2 new

 my $ffi = FFI::Raw->new( $library, $function, $return_type, @arg_types )

Create a new C<FFI::Raw> object. It loads C<$library>, finds the function
C<$function> with return type C<$return_type> and creates a calling interface.

If C<$library> is C<undef> then the function is searched in the main program.

This method also takes a variable number of types, representing the arguments
of the wanted function.

=head2 new_from_ptr

 my $ffi = FFI::Raw->new_from_ptr( $function_ptr, $return_type, @arg_types )

Create a new C<FFI::Raw> object from the C<$function_ptr> function pointer.

This method also takes a variable number of types, representing the arguments
of the wanted function.

=head1 METHODS

=head2 call

 my $ret = $ffi->call( @args)

Execute the C<FFI::Raw> function. This method also takes a variable number of
arguments, which are passed to the called function. The argument types must
match the types passed to C<new> (or C<new_from_ptr>).

The C<FFI::Raw> object can be used as a CODE reference as well. Dereferencing
the object will work just like call():

 $cos->call(2.0); # normal call() call
 $cos->(2.0);     # dereference as CODE ref

This works because FFI::Raw overloads the C<&{}> operator.

=head2 coderef

 my $code = FFI::Raw->coderef;

Return a code reference of a given C<FFI::Raw>.

=head1 SUBROUTINES

=head2 memptr

 my $memptr = FFI::Raw::memptr( $length );

Create a L<FFI::Raw::MemPtr>. This is a shortcut for C<FFI::Raw::MemPtr-E<gt>new(...)>.

=head2 callback

 my $callback = FFI::Raw::callback( $coderef, $ret_type, \@arg_types );

Create a L<FFI::Raw::Callback>. This is a shortcut for C<FFI::Raw::Callback-E<gt>new(...)>.

=head1 TYPES

Caveats on the way types were defined by the original L<FFI::Raw>:

This module uses the common convention that C<char> is 8 bits, C<short> is 16 bits,
C<int> is 32 bits, C<long> is 32 bits on a 32bit arch and 64 bits on a 64 bit arch,
C<int64> is 64 bits.  While this is probably true on most modern platforms
(if not all), it isn't technically guaranteed by the standard.  L<FFI::Platypus>
itself, differs in that C<int>, C<long>, etc are the native sizes, even if they do not
follow this common convention and you need to use C<sint32>, C<sint64>, etc if you
want a specific sized type.

This module also assumes that C<char> is signed.  Although this is commonly true
on many platforms it is not guaranteed by the standard.  On Windows, for example the
C<char> type is unsigned.  L<FFI::Platypus> by contrast follows to the standard
where C<char> uses the native behavior, and if you want an signed character type
you can use C<sint8> instead.

=head2 void

 my $type = FFI::Raw::void();

Return a C<FFI::Raw> void type.

=head2 int

 my $type = FFI::Raw::int();

Return a C<FFI::Raw> integer type.

=head2 uint

 my $type = FFI::Raw::uint();

Return a C<FFI::Raw> unsigned integer type.

=head2 short

 my $type = FFI::Raw::short();

Return a C<FFI::Raw> short integer type.

=head2 ushort

 my $type = FFI::Raw::ushort();

Return a C<FFI::Raw> unsigned short integer type.

=head2 long

 my $type = FFI::Raw::long();

Return a C<FFI::Raw> long integer type.

=head2 ulong

 my $type = FFI::Raw::ulong();

Return a C<FFI::Raw> unsigned long integer type.

=head2 int64

 my $type = FFI::Raw::int64();

Return a C<FFI::Raw> 64 bit integer type. This requires L<Math::Int64> to work.

=head2 uint64

 my $type = FFI::Raw::uint64();

Return a C<FFI::Raw> unsigned 64 bit integer type. This requires L<Math::Int64> 
to work.

=head2 char

 my $type = FFI::Raw::char();

Return a C<FFI::Raw> char type.

=head2 uchar

 my $type = FFI::Raw::uchar();

Return a C<FFI::Raw> unsigned char type.

=head2 float

 my $type = FFI::Raw::float();

Return a C<FFI::Raw> float type.

=head2 double

 my $type = FFI::Raw::double();

Return a C<FFI::Raw> double type.

=head2 str

 my $type = FFI::Raw::str();

Return a C<FFI::Raw> string type.

=head2 ptr

 my $type = FFI::Raw::ptr();

Return a C<FFI::Raw> pointer type.

=head1 SEE ALSO

L<FFI::Platypus>, L<Alt::FFI::Raw::Platypus>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
