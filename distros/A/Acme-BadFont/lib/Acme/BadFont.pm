package Acme::BadFont;
use strict;
use warnings;

our $VERSION = '1.000000';
$VERSION =~ tr/_//d;

use Scalar::Util qw(dualvar looks_like_number);
use overload ();

sub import {
  overload::constant(q => sub {
    my $string = $_[1];
    my $number = $string;
    if (looks_like_number($number)) {
      return $string;
    }
    elsif ($number =~ tr/OoIlZzEASsGBq/0011223455689/ and looks_like_number($number)) {
      $number += 0;
      return dualvar($number, $string);
    }
    return $string;
  });
}

sub unimport {
  overload::remove_constant('q');
}

1;
__END__

=head1 NAME

Acme::BadFont - Cope with a bad font in your editor

=head1 SYNOPSIS

  use warnings;
  use Acme::BadFont;

  my $f = "1OO";
  print $f + 1, "\n";   # 101
  my $d = "I.S";
  print $d * 2, "\n";   # 3

=head1 DESCRIPTION

If the font in your editor is bad, this module will help by fixing the numbers
in your strings.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2017 the Acme::BadFont L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
