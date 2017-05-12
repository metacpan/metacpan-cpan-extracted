package Apache2::GeoIP;

use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT_OK);

$VERSION = '1.99';
@EXPORT_OK = qw(find_addr);

sub find_addr {
  my ($r, $xforwardedfor) = @_;
  my $host;
  if (defined $xforwardedfor) {
    my $ReIpNum = qr{([01]?\d\d?|2[0-4]\d|25[0-5])};
    my $ReIpAddr = qr{^$ReIpNum\.$ReIpNum\.$ReIpNum\.$ReIpNum$};
    $host =  $r->headers_in->get('X-Forwarded-For') || 
      $r->connection->remote_ip;
    if ($host =~ /,/) {
      my @a = split /\s*,\s*/, $host;
      for my $i (0 .. $#a) {
          if ($a[$i] =~ /$ReIpAddr/ and $a[$i] ne '127.0.0.1') {
              $host = $a[$i];
              last;
          }
      }
      $host = '127.0.0.1' if $host =~ /,/;
    }
  }
  else {
    $host = $r->connection->remote_ip;
  }
  return $host;
}


1;

__END__

=head1 NAME

Apache2::GeoIP - Look up country by IP Address

=head1 IP ADDRESS TO COUNTRY DATABASES

Free monthly updates to the database are available from 

  http://www.maxmind.com/download/geoip/database/

This free database is similar to the database contained in IP::Country, as 
well as many paid databases. It uses ARIN, RIPE, APNIC, and LACNIC whois to 
obtain the IP->Country mappings.

For Win32 users, the F<GeoIP.dat> database file is expected
to reside in the F</Program Files/GeoIP/> directory.

If you require greater accuracy, MaxMind offers a Premium database on a paid 
subscription basis. 

=head1 MAILING LISTS AND CVS

A mailing list and cvs access for the GeoIP library are available 
from SourceForge; see http://sourceforge.net/projects/geoip/.

=head1 SEE ALSO

L<Apache2::Geo::IP> and L<Apache2::Geo::Mirror>.

=head1 AUTHOR

The look-up code for associating a country with an IP address 
is based on the GeoIP library and the Geo::IP Perl module, and is 
Copyright (c) 2002, T.J. Mather, tjmather@tjmather.com, New York, NY, 
USA. See http://www.maxmind.com/ for details. The mod_perl interface is 
Copyright (c) 2002, Randy Kobes <randy@theoryx5.uwinnipeg.ca>.

All rights reserved.  This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
