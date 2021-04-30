package FFI::Raw::Callback;

use strict;
use warnings;
use base qw( FFI::Platypus::Legacy::Raw::Callback );

# ABSTRACT: FFI::Platypus::Legacy::Raw function pointer type
our $VERSION = '0.32';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Raw::Callback - FFI::Platypus::Legacy::Raw function pointer type

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A B<FFI::Raw::Callback> represents a function pointer to a Perl routine. It can
be passed to functions taking a C<FFI::Raw::ptr> type.

=head1 CONSTRUCTOR

=head2 new

 my $callback = FFI::Raw::Callback->new( $coderef, $ret_type, @arg_types );

Create a C<FFI::Raw::Callback> using the code reference C<$coderef> as body. The
signature (return and arguments types) must also be passed.

=head1 CAVEATS

For callbacks with a C<FFI::Raw::str> return type, the string value will be copied
to a private field on the callback object.  The memory for this value will be
freed the next time the callback is called, or when the callback itself is freed.
For more exact control over when the return value is freed, you can instead
use C<FFI::Raw::ptr> type and return a L<FFI::Raw::MemPtr> object.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
