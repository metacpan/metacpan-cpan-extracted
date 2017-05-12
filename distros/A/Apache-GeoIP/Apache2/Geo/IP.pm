package Apache2::Geo::IP;

use strict;
use warnings;
use Apache2::RequestRec ();                      # $r
use Apache2::Const -compile => qw(REMOTE_HOST);  # constants
use Apache2::RequestUtil ();                     # $r->dir_config
use APR::Table ();                               # dir_config->get
use Apache2::Log ();                             # log_error
use Apache2::Connection ();
use vars qw($VERSION $gi $xforwardedfor);

use Geo::IP;
use Apache2::GeoIP qw(find_addr);
@Apache2::Geo::IP::ISA = qw(Apache2::RequestRec);

$VERSION = '1.99';

my @flags = qw(STANDARD MEMORY_CACHE CHECK_CACHE 
               INDEX_CACHE MMAP_CACHE
            );
my %flags = geoip_flags(@flags);
my @types = qw(COUNTRY_EDITION REGION_EDITION_REV0 CITY_EDITION_REV0
               ORG_EDITION ISP_EDITION CITY_EDITION_REV1 REGION_EDITION_REV1
               PROXY_EDITION ASNUM_EDITION NETSPEED_EDITION DOMAIN_EDITION
            );
my %types = geoip_flags(@types);

sub geoip_flags {
  my @flags = @_;
  my %hash;
  foreach my $f (@flags) {
    my $sub = 'Geo::IP::GEOIP_' . $f . '()';
    my $rv = eval "$sub";
    unless ($@) {
      $hash{$f} = $rv;
    }
  }
  return %hash;
}

sub new {
  my ($class, $r) = @_;
  init($r) unless $gi;

  return bless { r => $r}, $class;
}

sub init {
  my $r = shift;

  my $file = $r->dir_config->get('GeoIPDBFile');
  if ($file) {
    unless ( -e $file) {
      $r->log->error("Cannot find GeoIP database file '$file'");
      die;
    }
  }

  my @cfg_flags = $r->dir_config->get('GeoIPFlag') || qw(STANDARD);
  my $flag_re = join '|', keys %flags;
  my $flag = 0;
  if (@cfg_flags) {
    foreach my $f (@cfg_flags) {
      unless ($f =~ /^($flag_re)$/i) {
        $r->log->error("GeoIP flag '$f' not understood");
        die;
      }
      $flag |= $flags{uc $f};
    }
  }

  my $type = $r->dir_config->get('GeoIPType') || '';
  if ($type) {
    my $type_re = join '|', keys %types;
    unless ($type =~ /^($type_re)$/i) {
      $r->log->error("GeoIP type '$type' not understood");
      die;
    }
  }

  if ($type) {
    $gi = Geo::IP->open_type( $types{uc $type}, $flag );
    unless ($gi and ref($gi) eq 'Geo::IP') {
      $r->log->error("Couldn't make Geo::IP object from Geo::IP->open_type( $type, $flag )");
      die;
    }
  }
  else {
    if ($file) {
      $gi = Geo::IP->open( $file, $flag );
      unless ($gi and ref($gi) eq 'Geo::IP') {
        $r->log->error("Couldn't make Geo::IP object from Geo::IP->open( $file, $flag )");
        die;
      }
    }
    else {
      $gi = Geo::IP->new( $flag );
      unless ($gi and ref($gi) eq 'Geo::IP') {
        $r->log->error("Couldn't make Geo::IP object from Geo::IP->new( $flag )");
        die;
      }
    }
  }
  
  $xforwardedfor = $r->dir_config->get('GeoIPXForwardedFor') || '';
}

sub country_code_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->country_code_by_addr($ip);
}

sub country_code_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->country_code_by_name($host);
}

sub country_code3_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->country_code3_by_addr($ip);
}

sub country_code3_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->country_code3_by_name($host);
}

sub country_name_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->country_name_by_addr($ip);
}

sub country_name_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->country_name_by_name($host);
}

sub record_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->record_by_addr($ip);
}

sub record_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->record_by_name($host);
}

sub org_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->org_by_addr($ip);
}

sub org_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->org_by_name($host);
}

sub region_by_addr {
  my $self = shift;
  my $ip = shift || find_addr($self, $xforwardedfor);
  return $gi->region_by_addr($ip);
}

sub region_by_name {
  my $self = shift;
  my $host = shift || $self->get_remote_host(Apache2::Const::REMOTE_HOST);
  return $gi->region_by_name($host);
}

sub gi {
   return $gi;
}

1;

__END__

=head1 NAME

Apache2::Geo::IP - Look up country by IP address

=head1 SYNOPSIS

 # in httpd.conf
 # PerlModule Apache2::HelloIP
 #<Location /ip>
 #   SetHandler perl-script
 #   PerlResponseHandler Apache2::HelloIP
 #   PerlSetVar GeoIPDBFile "/usr/local/share/GeoIP/GeoIP.dat"
 #   PerlSetVar GeoIPFlag Standard
 #   PerlSetVar GeoIPXForwardedFor 1
 #</Location>
 
 # file Apache2::HelloIP
  
 use Apache2::Geo::IP;
 use strict;
 
 use Apache2::Const -compile => 'OK';
 
 sub handler {
   my $r = Apache2::Geo::IP->new(shift);
   $r->content_type('text/plain');
   my $country = uc($r->country_code_by_addr());
  
   $r->print($country);
  
   return Apache2::OK;
 }
 1;
 
=head1 DESCRIPTION

This module constitutes a mod_perl (version 2) interface to the 
L<Geo::IP> module, which looks up in a database a country of origin of
an IP address. This database simply contains
IP blocks as keys, and countries as values. This database should be more
complete and accurate than reverse DNS lookups.

This module can be used to automatically select the geographically 
closest mirror, to analyze your web server logs
to determine the countries of your visiters, for credit card fraud
detection, and for software export controls.

To find a country for an IP address, this module a finds the Network
that contains the IP address, then returns the country the Network is
assigned to.

=head1 CONFIGURATION

This module subclasses I<Apache2::RequestRec>, and can be used 
as follows in an Apache module.
 
  # file Apache2::HelloIP
  
  use Apache2::Geo::IP;
  use strict;
 
  sub handler {
     my $r = Apache2::Geo::IP->new(shift);
     # continue along
  }
 
The directives in F<httpd.conf> are as follows:
 
  <Location /ip>
    PerlSetVar GeoIPDBFile "/usr/local/share/GeoIP/GeoIP.dat"
    PerlSetVar GeoIPFlag Standard
    # other directives
  </Location>
 
The C<PerlSetVar> directives available are

=over 4

=item PerlSetVar GeoIPDBFile "/path/to/GeoIP.dat"

This specifies the location of the F<GeoIP.dat> file.
If not given, it defaults to the location specified
upon installing the L<Geo::IP> module.

=item PerlSetVar GeoIPFlag Standard

Flags can be set to either I<STANDARD>, or for faster performance 
(at a cost of using more memory), I<MEMORY_CACHE>. When using memory 
cache you can force a reload if the file is updated by setting I<CHECK_CACHE>. 
I<INDEX_CACHE> caches the most frequently accessed index portion of the database, 
resulting in faster lookups than I<STANDARD>, but less memory usage than 
I<MEMORY_CACHE> - this is useful for larger databases such as GeoIP 
Organization and GeoIP City. Note, for GeoIP Country, Region and Netspeed databases, 
I<INDEX_CACHE> is equivalent to I<MEMORY_CACHE>.

Multiple values of I<GeoIPFlag> can be set by specifying them
using I<PerlAddVar>. If no values are specified, I<STANDARD> is used.

=item PerlSetVar GeoIPType CITY_EDITION_REV1

This specifies the type of database file to be used. See the L<Geo::IP> documentation
for the various types that are supported.

=item PerlSetVar GeoIPXForwardedFor 1

If this directive is set to something true, the I<X-Forwarded-For> header will
be used to try to identify the originating IP address; this is useful for clients 
connecting to a web server through an HTTP proxy or load balancer. If this header
is not present, C<$r-E<gt>connection-E<gt>remote_ip> will be used.

=back

=head1 METHODS

The available methods are as follows.

=over 4

=item $code = $r->country_code_by_addr( [$ipaddr] );

Returns the ISO 3166 country code for an IP address.
If I<$ipaddr> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used

=item $code = $r->country_code_by_name( [$ipname] );

Returns the ISO 3166 country code for a hostname.
If I<$ipname> is not given, the value obtained by
C<$r-E<gt>get_remote_host(Apache2::Const::REMOTE_HOST)> is used.

=item $code = $r->country_code3_by_addr( [$ipaddr] );

Returns the 3 letter country code for an IP address.
If I<$ipaddr> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used.

=item $code = $r->country_code3_by_name( [$ipname] );

Returns the 3 letter country code for a hostname.
If I<$ipname> is not given, the value obtained by
C<$r-E<gt>get_remote_host(Apache2::Const::REMOTE_HOST)> is used.

=item $org = $r->org_by_addr( [$ipaddr] );

Returns the Organization, ISP name or Domain Name for an IP address.
If I<$ipaddr> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used.

=item $org = $r->org_by_name( [$ipname] );

Returns the Organization, ISP name or Domain Name for a hostname.
If I<$ipname> is not given, the value obtained by
C<$r-E<gt>get_remote_host(Apache2::Const::REMOTE_HOST)> is used.

=item ( $country, $region ) = $r->region_by_addr( [$ipaddr] );

Returns a list containing country and region for an IP address. If the
region and/or country is unknown, I<undef> is returned. This works only 
for region databases. If I<$ipaddr> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used.

=item ( $country, $region ) = $r->region_by_name( [$ipname] );

Returns a list containing country and region for a hostname. If the
region and/or country is unknown, I<undef> is returned. This works only 
for region databases. If I<$ipname> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>get_remote_host(Apache2::Const::REMOTE_HOST)> is used.

=item $gi = $r->gi

Returns the L<Geo::IP> object.

=back

=head1 Geo::IP::Record

A L<Geo::IP::Record> object can be created by two ways:

=over 4

=item $record = $r->record_by_addr( [$ipaddr] );

Returns a L<Geo::IP::Record> object containing city location an IP address.
If I<$ipaddr> is not given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used.

=item $record = $r->record_by_name( [$ipname] );

Returns a L<Geo::IP::Record> object containing city location for a hostname.
If I<$ipname> is not given, the value obtained by
C<$r-E<gt>get_remote_host(Apache2::Const::REMOTE_HOST)> is used.

=back

The information contained in this object can be accessed as:

=over 4

=item $code = $record->country_code;

Returns the ISO 3166 country code from the location object.

=item $code3 = $record->country_code3;

Returns the ISO 3166 3 letter country code from the location object.

=item $name = $record->country_name;

Returns the country name from the location object.

=item $region = $record->region;

Returns the region code from the location object.

=item $region = $record->region_name;

Returns the region name from the location object.

=item $city = $record->city;

Returns the city from the location object.

=item $postal_code = $record->postal_code;

Returns the postal code from the location object.

=item $lat = $record->latitude;

Returns the latitude from the location object.

=item $lon = $record->longitude;

Returns the longitude from the location object.

=item $time_zone = $record->time_zone;

Returns the time zone from the location object.

=item $area_code = $record->area_code;

Returns the area code from the location object (for city-level US locations only)

=item $metro_code = $record->metro_code;

Returns the metro code from the location object (for city-level US locations only)

=item $continent_code = $record->continent_code;

Returns the continent code from the location object.
Possible continent codes are AF, AS, EU, NA, OC, SA for 
Africa, Asia, Europe, North America, Oceania  and South America. 

=back

=head1 SEE ALSO

L<Geo::IP> and L<Apache2::RequestRec>.

=head1 AUTHOR

The look-up code for associating a country with an IP address 
is based on the GeoIP library and the Geo::IP Perl module, and is 
Copyright (c) 2002, T.J. Mather, E<lt> tjmather@tjmather.com E<gt> New York, NY, 
USA. See http://www.maxmind.com/ for details. The mod_perl interface is 
Copyright (c) 2002, 2009 Randy Kobes E<lt> randy.kobes@gmail.com E<gt>.

All rights reserved.  This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
