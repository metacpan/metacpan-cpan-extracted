package Acme::Tie::Formatted;
use strict;
use warnings;
use Carp;

our $VERSION = '0.04';

my $first_char = qr/[_a-zA-Z]/;
my $next_char  = qr/[_a-zA-Z0-9]/;
my $ok_name    = qr/^$first_char($next_char)*$/;

our %format;

sub import {
  $DB::single=1;
  my ($class, $arg) = @_;
  my $hash_name = "format";

  if (defined $arg and $arg =~ /$ok_name/) {
    $hash_name = $arg;
  }

  {
    no strict 'refs';
    *{"main::$hash_name"} = \%format;
  }

  # Connect the magic to the hash.
  tie %format, 'Acme::Tie::Formatted';
}


sub TIEHASH {
  my $class = shift;

  # Someplace to hang our hat.
  bless \my($self), $class; 
}

sub FETCH {
  my ($self, $key) = @_;
  return '' unless $key;

  my @args = split $;, $key, -1;

  # Return a null string if nothing was passed in.
  return '' unless @args;

  my $format = pop @args;

  # Return a null string if there were no arguments
  # to be formatted.
  return '' unless @args;

  # Format arguments and return.
  local $_;
  return join($", map { sprintf($format, $_) } @args);
}

# Stolen directly from Tie::Comma.
# Invalidate all other hash access.
use subs qw(
 STORE    EXISTS    CLEAR    FIRSTKEY    NEXTKEY  );
*STORE = *EXISTS = *CLEAR = *FIRSTKEY = *NEXTKEY = 
  sub {
    croak "You can only use %format by accessing it";
  };


1; # Magic true value required at end of module

__END__

=head1 NAME

Acme::Tie::Formatted - embed sprintf() formatting in regular print()


=head1 VERSION

This document describes Acme::Tie::Formatted version 0.03


=head1 SYNOPSIS

    use Acme::Tie::Formatted;
    print "The value is $format{$number, "%3d"} ",
          "(or $format{$number, "%04x"} in hex)\n";

    print "some numbers: $format{ 12, 492, 1, 8753, "%04d"}\n";

=head1 DESCRIPTION

This module creates a global read-only hash, C<%format>, for formatting
data items with standard C<sprintf> format specifications. Since it's a
hash, you can interpolate it into strings as well as use it standalone.

The hash should be "accessed" with two or more "keys". The last key
is interpreted as a C<sprintf> format for each data item specified in the
preceeding arguments. This allows you to format multiple items at once
using the same format for each.

=head2 Alternate name

If you prefer, you can specify a different name for the magical
formatting hash by supplying it as as argument when C<use>ing the
module:

  use Acme::Tie::Formatted qw(z);

This makes C<%z> the magic hash instead.

  print "This is hex: $z{255, "%04x"}\n";

C<Acme::Tie::Formatted> currently supports only one format in the final 
argument; this may change if there is demand for it.

=head1 DIAGNOSTICS

=over

=item C<< You can only use %format by accessing it >>

You tried to store something in C<%format>, check if an element
exists in it, delete an element, empty out the hash, or 
access the key in it. 

None of these operations do anything; only reading elements
of the hash works.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Tie::Formatted requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Fixed in 0.04: A number of POD errors and typos. Thanks to Frank Wiegand
(frank.weigand@gmail.com) for the patch.

Please report any bugs or feature requests to
C<bug-tie-formatted@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Joe McMahon C<< <mcmahon@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 CREDITS

Sean Burke, for saying he wanted this.

Eric J. Roode, for Tie::Comma (which this is derived from).

Mark-Jason Dominus, for Interpolate.

=over 4

"We are like dwarfs sitting on the shoulders of giants. We see more 
than they do, indeed even farther; but not because our sight is 
better than theirs or because we are taller than they. Our sight 
is enhanced because they raise us up and increase our stature by 
their enormous height." - Bernard de Chartes

=back
