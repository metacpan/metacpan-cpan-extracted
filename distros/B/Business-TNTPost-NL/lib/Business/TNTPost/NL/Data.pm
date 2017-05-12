package Business::TNTPost::NL::Data;
use strict;
use base 'Exporter';
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp;
use YAML;

$VERSION   = 0.11;
@EXPORT    = qw();
@EXPORT_OK = qw(zones table);
%EXPORT_TAGS = ("ALL" => [@EXPORT_OK]);

=pod

=head1 NAME

Business::TNTPost::NL::Data - Shipping cost data for Business::TNTPost::NL

=head1 DESCRIPTION

Data module for Business::TNTPost::NL containing shipping cost
information, country zones etc.

Nothing to see here, the show is over, move along please.

=head2 METHODS

The following methods are used and can be exported

=head3 zones

Returns a hashref with country and zone numbers

=cut

sub zones {
   my %zones = (
      0 => [ qw(NL) ],                                      # NL
      1 => [ qw(BE LU DK DE FR IT AT ES GB SE) ],           # EU 1
      2 => [ qw(BG EE FI HU IE LV LT PL PT RO SI SK CZ) ],  # EU 2
      3 => [ qw(AL AD BA IC CY FO GI GR GL IS HR LI MK MD MT
                ME NO UA SM RS TR VA BY CH) ],              # EU 3
   );
   my %z;
   foreach my $key (keys %zones) {
      foreach my $val (@{$zones{$key}}) {
         $z{$val} = $key;
      }
   }
   return \%z;
}

=pod

=head3 table

This method contains the heart of this module, the lookup table

=cut

sub table {
my $table = Load(<<'...');
---
# Netherlands
netherlands:
  # Letters (brievenbuspost)
  small:
    stamp:
      '0,20': 0.46
      '21,50': 0.92
      '51,100': 1.38
      '101,250': 1.84
      '251,500': 2.30
      '501,2000': 2.76
    machine:
      '0,20': 0.42
      '21,50': 0.84
      '51,100': 1.26
      '101,250': 1.67
      '251,500': 2.09
      '501,2000': 2.51
  # Parcels (paketten)
  large:
    '0,10000': 6.75
    '10001,30000': 12.20
  # Register (aangetekend)
  register:
    stamp:
      '0,2000': 7.00
      '2001,20000': 8.05
      '20001,30000': 13.50
    machine:
      '0,2000': 6.79
      '2001,10000': 8.05
# Outside of the Netherlands
world:
  basic:
    # Within Europe (EU1 & EU2)
    europe:
      # Letters (brievenbuspost)
      small:
        stamp:
          priority:
            '0,20': 0.79
            '21,50': 1.58
            '51,100': 2.37
            '101,250': 3.16
            '251,500': 6.32
            '501,2000': 8.69
        machine:
          priority:
            '0,20': 0.77
            '21,50': 1.53
            '51,100': 2.30
            '101,250': 3.07
            '251,500': 6.13
            '501,2000': 8.43
    # Outside Europe
    world:
      # Letters (brievenbuspost)
      small:
        stamp:
          priority:
            '0,20': 0.95
            '21,50': 1.90
            '51,100': 2.85
            '101,250': 5.70
            '251,500': 10.45
            '501,2000': 16.15
        machine:
          priority:
            '0,20': 0.92
            '21,50': 1.84
            '51,100': 2.76
            '101,250': 5.53
            '251,500': 10.14
            '501,2000': 15.67
  # Internationaal Pakket Plus (Track&Trace)
  plus:
    zone:
      # EU1
      1:
        '0,2000': 13.00
        '2001,5000': 19.50
        '5001,10000': 25.00
        '10001,20000': 34.00
        '20001,30000': 40.46
      # EU2
      2:
        '0,2000': 18.50
        '2001,5000': 25.00
        '5001,10000': 31.00
        '10001,20000': 40.00
        '20001,30000': 47.60
      # EU3
      3:
        '0,2000': 19.30
        '2001,5000': 26.30
        '5001,10000': 32.30
        '10001,20000': 42.30
      # RoW
      4:
        '0,2000': 24.30
        '2001,5000': 34.30
        '5001,10000': 58.30
        '10001,20000': 105.30
  # Register ("aangetekend")
  register:
    europe:
      stamp:
        '0,2000': 9.48
      machine:
        '0,2000': 9.20
    world:
      stamp:
        '0,2000': 16.15
      machine:
        '0,2000': 15.67
...
   return $table;
}

=pod

=head1 AUTHOR

Menno Blom,
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Business::TNTPost::NL>,
L<http://www.tntpost.nl/>

=cut

1;
