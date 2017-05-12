package Apache::Geo::Mirror;

use strict;
use warnings;
use vars qw($VERSION $GM $ROBOTS_TXT $DEFAULT $FRESH $XFORWARDEDFOR);
use Apache::GeoIP;
use POSIX;

$VERSION = '1.99';

my $GEOIP_DBFILE;
my $robots_txt = '';

use Apache;
use Apache::Constants qw(REMOTE_HOST REDIRECT OK);
use Apache::URI;

@Apache::Geo::Mirror::ISA = qw(Apache);

use Geo::Mirror;
use Apache::GeoIP qw(find_addr);

sub new {
  my ($class, $r) = @_;
  
  my $loc = $r->location;
  init($r, $loc) unless (exists $GM->{$loc});
  
  return bless { r => $r,
                 gm => $GM->{$loc},
                 robots_txt => $ROBOTS_TXT->{$loc},
                 default => $DEFAULT->{$loc},
                 fresh => $FRESH->{$loc},
                 xforwardedfor => $XFORWARDEDFOR->{$loc},
               }, $class;
}

sub init {
  my ($r, $loc) = @_;

  my $file = $r->dir_config->get('GeoIPDBFile');
  if ($file)  {
    unless ( -e $file) {
      $r->log->error("Cannot find GeoIP database file '$file'");
      die;
    }
  }

  my $mirror_file = $r->dir_config->get('GeoIPMirror');
  unless (defined $mirror_file) {
    $r->log->error("Must specify location of the mirror file");
     die;
  }
  unless (-e $mirror_file) {
    $r->log->error("Cannot find the mirror file '$mirror_file'");
    die;
  }

  my $gm = Geo::Mirror->new(mirror_file => $mirror_file,
                            database_file => $file,
                            );
  unless (defined $gm and ref($gm) eq 'Geo::Mirror') {
    $r->log->error("Cannot create Geo::Mirror object");
    die;
  }
  $GM->{$loc} = $gm;
  
  my $robot = $r->dir_config->get('GeoIPRobot') || '';
  my $robots_txt;
  if ($robot) {
    if (lc $robot eq 'default') {
      $robots_txt = <<'END';
User-agent: *
Disallow: /
END
    }
    else {
      my $fh;
      unless (open($fh, '<', $robot) ) {
        $r->log->error("Cannot open GeoIP robots file '$robot': $!");
        die;
      }
      my @lines = <$fh>;
      close($fh);
      $robots_txt = join "\n", @lines;
    }
  }    
  $ROBOTS_TXT->{$loc} = $robots_txt;
  
  my @defaults = $r->dir_config->get('GeoIPDefault') || ();
  $DEFAULT->{$loc} = \@defaults;

  $FRESH->{$loc} = $r->dir_config->get('GeoIPFresh') || 0;
  
  $XFORWARDEDFOR->{$loc} = $r->dir_config->get('GeoIPXForwardedFor') || '';
}

sub find_mirror_by_country {
  my ($self, $country) = @_;
  my $gm = $self->{gm};
  my $fresh = $self->{fresh};
  my $url;
  if ($country) {
    $url = $gm->find_mirror_by_country($country, $fresh) || $self->find_default;
  }
  else {
    my $addr = find_addr($self, $self->{xforwardedfor});
    my $url = $gm->find_mirror_by_addr($addr, $fresh) || $self->find_default;
  }
  return $url;
}

sub find_mirror_by_addr {
  my $self = shift;
  my $addr = shift || $self->connection->remote_ip;
  
  my $gm = $self->{gm};
  my $url = $gm->find_mirror_by_addr($addr, $self->{fresh}) || $self->find_default;
  return $url;
}

sub find_default {
  my $self = shift;
  my $default = '';
  my $self_default = $self->{default};
  if ($self_default and ref($self_default) eq 'ARRAY') {
    my @defaults = @$self_default;
    my $num = scalar @defaults;
    $default = ($num == 1) ? $defaults[0] : $defaults[ rand($num) ];
  }
  return $default;
}

sub gm {
  my $self = shift;
  return $self->{gm};
}


sub auto_redirect : method {
  my $class = shift;
  my $r = __PACKAGE__->new(shift);
  my $host = find_addr($r, 1);
  my $chosen = $r->find_mirror_by_addr($host);
  my $uri = Apache::URI->parse($r, $chosen);
  my $robots_txt = $r->{robots_txt} || '';
  my $uri_path = $uri->path;
  my $path_info = $r->path_info;
  if ($path_info =~ /robots\.txt$/ and defined $robots_txt) {
    $r->send_http_header('text/plain');
    $r->print("$robots_txt\n");
    return OK;
  }
  $uri->path($uri_path . $path_info);
  #    my $where = $uri->unparse;
  #  $r->warn("$where $host");
  $r->headers_out->set(Location => $uri->unparse);
  return REDIRECT;
}

1;

__END__

=head1 NAME

Apache::Geo::Mirror - Find closest Mirror

=head1 SYNOPSIS

 # in httpd.conf
 # PerlModule Apache::HelloMirror
 #<Location /mirror>
 #   SetHandler perl-script
 #   PerlHandler Apache::HelloMirror
 #   PerlSetVar GeoIPDBFile "/usr/local/share/geoip/GeoIP.dat"
 #   PerlSetVar GeoIPFlag Standard
 #   PerlSetVar GeoIPMirror "/usr/local/share/data/mirror.txt"
 #   PerlSetVar GeoIPDefault "http://www.cpan.org/"
 #</Location>
 
 # file Apache::HelloMirror
 
 use Apache::Geo::Mirror;
 use strict;
  
 use Apache::Constants qw(OK);
 
 sub handler {
   my $r = Apache::Geo::Mirror->new(shift);
   $r->content_type('text/plain');
   my $mirror = $r->find_mirror_by_addr();
   $r->print($mirror);
  
   OK;
 }
 1;

=head1 DESCRIPTION

This module provides a mod_perl (version 1) interface to the
I<Geo::Mirror> module, which
finds the closest mirror for an IP address.  It uses I<Geo::IP>
to identify the country that the IP address originated from.  If
the country is not represented in the mirror list, then it finds the
closest country using a latitude/longitude table.

=head1 CONFIGURATION

This module subclasses I<Apache>, and can be used as follows
in an Apache module.
 
  # file Apache::HelloMirror
  
  use Apache::Geo::Mirror;
  use strict;
 
  sub handler {
     my $r = Apache::Geo::Mirror->new(shift);
     # continue along
  }
 
The directives in F<httpd.conf> are as follows:
 
  <Location /mirror>
    PerlSetVar GeoIPDBFile "/usr/local/share/GeoIP/GeoIP.dat"
    PerlSetVar GeoIPFlag Standard
    PerlSetVar GeoIPMirror "/usr/local/share/data/mirror.txt"
    PerlSetVar GeoIPDefault "http://www.cpan.org"
    # other directives
  </Location>
 
The directives available are

=over 4

=item PerlSetVar GeoIPDBFile "/path/to/GeoIP.dat"

This specifies the location of the F<GeoIP.dat> file.
If not given, it defaults to the location specified
upon installing the module.

=item PerlSetVar GeoIPFresh 5

This specifies a minimum freshness that the chosen mirror must satisfy.
If this is not specified, a value of 0 is assumed.

=item PerlSetVar GeoIPMirror "/path/to/mirror.txt"

This specifies the location of a file containing
the list of available mirrors. No default location for this file is assumed.
This file contains a list of mirror sites and the corresponding 
country code in the format

  http://some.server.com/some/path         us
  ftp://some.other.server.fr/somewhere     fr

An optional third field may be specified, such as

  ftp://some.other.server.ca/somewhere    ca  3

where the third number indicates the freshness of the mirror. A default
freshness of 0 is assumed when none is specified. When choosing a mirror,
if the I<GeoIPFresh> directive is specified, only those mirrors
with a freshness equal to or above this value may be chosen.

=item PerlSetVar GeoIPDefault "http://some.where.org/"

This specifies the default url to be used if no nearby mirror is found.
Multiple values may be specified using I<PerlAddVar>; if more than one
default is given, a random one will be chosen.

=item PerlSetVar GeoIPXForwardedFor 1

If this directive is set to something true, the I<X-Forwarded-For> header will
be used to try to identify the originating IP address; this is useful for clients 
connecting to a web server through an HTTP proxy or load balancer. If this header
is not present, C<$r-E<gt>connection-E<gt>remote_ip> will be used.

=back

=head1 METHODS

The available methods are as follows.

=over 4

=item $mirror = $r->find_mirror_by_country( [$country] );

Finds the nearest mirror by country code. If I<$country> is not
given, this defaults to the country as specified by a lookup
of C<$r-E<gt>connection-E<gt>remote_ip>.

=item $mirror = $r->find_mirror_by_addr( [$ipaddr] );

Finds the nearest mirror by IP address. If I<$ipaddr> is not
given, the value obtained by
examining the I<X-Forwarded-For> header will be used, if
I<GeoIPXForwardedFor> is used, or else
C<$r-E<gt>connection-E<gt>remote_ip> is used.

=item $gm = $r->gm;

Returns the L<Geo::IP::Mirror> object.

=back
=head1 AUTOMATIC REDIRECTION

If I<Apache::Geo::Mirror> is used as

  PerlModule Apache::Geo::Mirror
  <Location /CPAN>
    PerlSetVar GeoIPDBFile "/usr/local/share/geoip/GeoIP.dat"
    PerlSetVar GeoIPFlag Standard
    PerlSetVar GeoIPMirror "/usr/local/share/data/mirror.txt"
    PerlSetVar GeoIPDefault "http://www.cpan.org"
    PerlHandler Apache::Geo::Mirror->auto_redirect
  </Location>

then an automatic redirection is made. Within this, the directive

    PerlSetVar GeoIPRobot "/path/to/a/robots.txt"

can be used to handle robots that honor a I<robots.txt> file. This can be
a physical file that exists on the system or, if it is set to the special
value I<default>, the string

    User-agent: *
    Disallow: /

will be used, which disallows robot access to anything.

Within automatic redirection, the I<X-Forwarded-For> header wil be
used to try to infer the IP address of the client.

=head1 SEE ALSO

L<Geo::IP>, L<Geo::Mirror>, and L<Apache>.

=head1 AUTHOR

The look-up code for associating a country with an IP address 
is based on the GeoIP library and the Geo::IP Perl module, and is 
Copyright (c) 2002, T.J. Mather, E<lt> tjmather@tjmather.com E<gt>, New York, NY, 
USA. See http://www.maxmind.com/ for details. The mod_perl interface is 
Copyright (c) 2002, 2009 Randy Kobes E<lt> randy.kobes@gmail.com E<gt>.

All rights reserved.  This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
