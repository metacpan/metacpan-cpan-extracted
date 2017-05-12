package Crypt::Memfrob;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw( memfrob );
$VERSION = '1.00';

sub memfrob($) {
    return(join("", map { chr((ord($_) ^ 42) + 0) } (split(//, shift))));
}

1;
__END__

=head1 NAME

Crypt::Memfrob - memfrob implementation in pure Perl

=head1 SYNOPSIS

  use Crypt::Memfrob 'memfrob';
  my $frobed = memfrob($str);

=head1 DESCRIPTION

This package provides one function 'memfrob.'  This is equivalent to
the memfrob function included in glibc.  With this library, you can
generate glibc-compatible frobnicated (encrypted) strings, and
defrobnicate glibc-generated strings, in Perl.

=head1 FUNCTIONS

=over 4

=item B<memfrob>

This function frobnicates given string and returns the result.

=back

=head1 FROBNICATION

This library is based on GNU libc 2.2.4.  From B<memfrob(3)>:

   The memfrob() function encrypts the first n bytes of the
   memory areas by exclusive-ORing each character with the
   number 42.  The effect can be reversed by using memfrob()
   on the encrypted memory area.

   Note that this function is not a proper encryption routine
   as the XOR constant is fixed, and is only suitable for
   hiding strings.

=head1 SEE ALSO

memfrob(3).

=head1 COPYRIGHT

Copyright 2001 Keiichiro Nagano <knagano@sodan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
