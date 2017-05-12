package Business::PostNL::Data;
use strict;
use base 'Exporter';
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp;
use YAML;

$VERSION   = 0.14;
@EXPORT    = qw();
@EXPORT_OK = qw(zones table);
%EXPORT_TAGS = ("ALL" => [@EXPORT_OK]);

=pod

=head1 NAME

Business::PostNL::Data - Shipping cost data for Business::PostNL

=head1 DESCRIPTION

Data module for Business::PostNL containing shipping cost
information, country zones etc.

Nothing to see here, the show is over, move along please.

=head2 METHODS

The following methods are used and can be exported

=head3 zones

Returns a hashref with country and zone numbers

=cut

sub zones {
   my %zones = (
      0 => [ qw(NL) ],                                           # NL
      1 => [ qw(BE DK DE FR IT LU AT ES GB SE) ],                # EU 1
      2 => [ qw(BG EE FI HU IE HR LV LT PL PT RO SI SK CZ) ],    # EU 2
      3 => [ qw(AL AD BA IC CY FO GI GR GL IS LI MK MT MD
                ME NO UA SM RS TR VA BY CH) ],                   # EU 3
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
      '0,20': 0.64
      '21,50': 1.28
      '51,100': 1.92
      '101,250': 2.56
      '251,2000': 3.84
    machine:
      '0,20': 0.56
      '21,50': 1.12
      '51,100': 1.68
      '101,250': 2.24
      '251,2000': 3.36
  # Parcels (paketten)
  large:
    stamp:
      '0,10000': 6.75
      '10001,30000': 12.90
    machine:
      '0,10000': 6.75
  # Register (aangetekend)
  register:
    stamp:
      '0,2000': 7.95
      '2001,10000': 13.70
      '10001,30000': 14.20
    machine:
      '0,2000': 7.71
      '2001,10000': 8.05
# Outside of the Netherlands
world:
  # letters
  small:
    # Within Europe (EU1 & EU2 & EU3)
    europe:
      stamp:
        normal:
          '0,20': 1.05
          '21,50': 2.10
          '51,100': 3.15
          '101,250': 5.25
          '251,2000': 9.45
        register:
          '0,2000': 11.00
      machine:
        normal:
          '0,20': 1.02
          '21,50': 2.04
          '51,100': 3.06
          '101,250': 5.09
          '251,2000': 9.17
        register:
          '0,2000': 10.67
    # Outside Europe
    world:
      stamp:
        normal:
          '0,20': 1.05
          '21,50': 2.10
          '51,100': 3.15
          '101,250': 5.25
          '251,2000': 9.45
        register:
          '0,2000': 16.00
      machine:
        normal:
          '0,20': 1.02
          '21,50': 2.04
          '51,100': 3.06
          '101,250': 5.09
          '251,2000': 9.17
        register:
          '0,2000': 15.52
  # parcels
  large:
    zone:
      # EU1
      1:
        stamp:
          normal:
            '0,2000': 9.00
          tracktrace:
            '0,2000': 13.00
            '2001,5000': 19.50
            '5001,10000': 25.00
            '10001,20000': 34.00
            '20001,30000': 43.15
          register:
            '0,2000': 14.30
            '2001,5000': 20.80
            '5001,10000': 26.30
            '10001,20000': 35.30
            '20001,30000': 44.45
        machine:
          normal:
            '0,2000': 8.73
          tracktrace:
            '0,2000': 13.00
            '2001,5000': 19.50
            '5001,10000': 25.00
            '10001,20000': 34.00
          register:
            '0,2000': 14.30
            '2001,5000': 20.80
            '5001,10000': 26.30
            '10001,20000': 35.30
      # EU2
      2:
        stamp:
          normal:
            '0,2000': 11.00
          tracktrace:
            '0,2000': 18.50
            '2001,5000': 25.00
            '5001,10000': 31.00
            '10001,20000': 40.00
            '20001,30000': 50.40
          register:
            '0,2000': 19.80
            '2001,5000': 26.30
            '5001,10000': 32.30
            '10001,20000': 41.30
            '20001,30000': 51.70
        machine:
          normal:
            '0,2000': 10.67
          tracktrace:
            '0,2000': 18.50
            '2001,5000': 25.00
            '5001,10000': 31.00
            '10001,20000': 40.00
          register:
            '0,2000': 19.80
            '2001,5000': 26.30
            '5001,10000': 32.30
            '10001,20000': 41.30
      # EU3
      3:
        stamp:
          normal:
            '0,2000': 12.00
          tracktrace:
            '0,2000': 19.30
            '2001,5000': 26.30
            '5001,10000': 32.30
            '10001,20000': 42.30
          register:
            '0,2000': 20.60
            '2001,5000': 27.60
            '5001,10000': 33.60
            '10001,20000': 43.60
        machine:
          normal:
            '0,2000': 11.64
          tracktrace:
            '0,2000': 19.30
            '2001,5000': 26.30
            '5001,10000': 32.30
            '10001,20000': 42.30
          register:
            '0,2000': 20.60
            '2001,5000': 27.60
            '5001,10000': 33.60
            '10001,20000': 43.60
      # RoW
      4:
        stamp:
          normal:
            '0,2000': 18.00
          tracktrace:
            '0,2000': 24.30
            '2001,5000': 34.30
            '5001,10000': 58.30
            '10001,20000': 105.30
          register:
            '0,2000': 25.60
            '2001,5000': 35.60
            '5001,10000': 59.60
            '10001,20000': 106.60
        machine:
          normal:
            '0,2000': 17.46
          tracktrace:
            '0,2000': 24.30
            '2001,5000': 34.30
            '5001,10000': 58.30
            '10001,20000': 105.30
          register:
            '0,2000': 25.60
            '2001,5000': 35.60
            '5001,10000': 59.60
            '10001,20000': 106.60
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

L<Business::PostNL>,
L<http://www.postnl.nl/>

=cut

1;
