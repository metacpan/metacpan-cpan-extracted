package App::CPANIDX;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.40';

1;

__END__

=head1 NAME

App::CPANIDX - Queryable web-based CPAN Index

=head1 SYNOPSIS

  # Generate the index database

  $ cpanidx-gendb --config cpanidx.ini

  # Run the FastCGI script

  $ cpanidx-fcgi --config cpanidx.ini

=head1 DESCRIPTION

App::CPANIDX provides a number of scripts to build a queryable web-based CPAN index.

=head1 CONFIGURATION

Configuration is dealt with by a L<Config::Tiny> based configuration file.

There are a number of parameters which can be specified

=over

=item C<dsn>

The L<DBI> dsn string of the database that the scripts will use. This is a mandatory requirement.

=item C<user>

The username for the supplied C<dsn>.

=item C<pass>

The password for the supplied C<dsn>.

=item C<url>

The C<cpanidx-gendb> script will poll this url when it has finished its update. It should be the
root url of your CPANIDX site

  url=http://my.cpanidx.site/cpanidx/

=item C<mirror>

The url of a CPAN mirror site where C<cpanidx-gendb> will obtain its index files from. If not
supplied it defaults to the Funet site L<ftp://ftp.funet.fi/pub/CPAN/>.

=item C<socket>

This is the socket that L<FCGI> should listen on for requests. It is a mandatory requirement for the
C<cpanidx-fcgi> script.

=item C<skipcore>

Applicable to the C<cpanidx-gendb> script, will skip the generation of the L<Module::CoreList>
based tables.

=item C<skipmirrors>

Applicable to the C<cpanidx-gendb> script, will skip the generation of the mirrorlist
based tables.

=item C<skipperms>

Applicable to the C<cpanidx-gendb> script, will skip the generation of the CPAN permissions
based tables.

=back

=head1 SCRIPTS

Both the scripts will by default look for a C<cpanidx.ini> file in the current working directory
unless you specify an alternative with the C<--config> command line option.

=over

=item C<cpanidx-gendb>

Generates the CPANIDX database. It will retrieve the CPAN index files from a CPAN mirror and
parse them to build the database.

The CPAN indexes are downloaded to C<~/.cpanidx> by default. You may override this location
by setting the C<PERL5_CPANIDX_DIR> environment variable to a different location to use.

In tests a L<DBD::SQLite> database took over 3 minutes to generate and a L<DBD::mysql> database
took 30 seconds.

It is recommended that one uses cron or some such scheduler to run this script every hour to
ensure freshness of the CPAN index.

=item C<cpanidx-fcgi>

Presents the CPAN index to web clients via FastCGI. Specify a socket that the script should
listen for requests on and configure your webserver accordingly.

The following is an example for Lighttpd:

  fastcgi.server = (
        "/cpanidx/" =>
         ( "localhost" => (
            "host" => "127.0.0.1",
            "port" => 1027,
            "check-local" => "disable",
            )
         ),
  )

The interface that clients can query is described below.

=back

=head1 INTERFACE

The C<cpanidx-fcgi> provides a number of ways that clients can access information from the CPAN Index.

The information is provided in a number of different formats: YAML, JSON, XML and HTML.

Information is requested by using a special URL

  http://name.of.website/<prefix>/<format>/<cmd>/<search_term>

We will assume that <prefix> is C<cpanidx> for the purposes of this documentation.

=over

=item C<<format>>

The format may be one of C<yaml>, C<json>, C<xml> or C<html>.

=item C<<cmd>>

The command may be one of the following:

=over

=item C<mod>

Takes a search term which is a module name to search for. Returns information relating to that module if it
exists.

  curl -i http://name.of.website/cpanidx/yaml/mod/LWP

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 04 Mar 2010 11:34:07 GMT
  Server: lighttpd/1.4.25

  ---
  -
    cpan_id: GAAS
    dist_file: G/GA/GAAS/libwww-perl-5.834.tar.gz
    dist_name: libwww-perl
    dist_vers: 5.834
    mod_name: LWP
    mod_vers: 5.834

=item C<dist>

Takes a search term which is a distribution name to search for. Returns information relating to that
distribution if it exists.

  curl -i http://name.of.website/cpanidx/yaml/dist/CPANPLUS-Dist-Build

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Mon, 06 Sep 2010 14:02:23 GMT
  Server: lighttpd/1.4.25

  ---
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/CPANPLUS-Dist-Build-0.48.tar.gz
    dist_name: CPANPLUS-Dist-Build
    dist_vers: 0.48

=item C<auth>

Takes a search term which is the CPAN ID of an author to search for. Returns information relating to that
author if they exist.

  curl -i http://name.of.website/cpanidx/yaml/auth/BINGOS

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 04 Mar 2010 11:36:13 GMT
  Server: lighttpd/1.4.25

  ---
  -
    cpan_id: BINGOS
    email: chris@bingosnet.co.uk
    fullname: 'Chris Williams'

=item C<dists>

Takes a search term which is the CPAN ID of an author. Returns a list of distributions that author has on
CPAN.

  curl -i http://name.of.website/cpanidx/yaml/dists/BINGOS

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 04 Mar 2010 11:39:14 GMT
  Server: lighttpd/1.4.25

  ---
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/POE-Filter-LZO-1.70.tar.gz
    dist_name: POE-Filter-LZO
    dist_vers: 1.70
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/POE-Component-Server-SimpleSMTP-1.44.tar.gz
    dist_name: POE-Component-Server-SimpleSMTP
    dist_vers: 1.44
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/POE-Component-Server-RADIUS-1.02.tar.gz
    dist_name: POE-Component-Server-RADIUS
    dist_vers: 1.02
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/Archive-Extract-0.38.tar.gz
    dist_name: Archive-Extract
    dist_vers: 0.38
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/POE-Component-IRC-Plugin-URI-Find-1.08.tar.gz
    dist_name: POE-Component-IRC-Plugin-URI-Find
    dist_vers: 1.08
  -
    cpan_id: BINGOS
    dist_file: B/BI/BINGOS/POE-Component-SmokeBox-Dists-1.00.tar.gz
    dist_name: POE-Component-SmokeBox-Dists
    dist_vers: 1.00

etc, etc.

=item C<perms>

Takes a search term which is a module name to search for. Returns CPAN permissions relating to
that module if it exists.

The permission is one of C<m> for C<modulelist>, C<f> for C<first-come> and
C<c> for C<co-maint>.

  curl -i http://name.of.website/cpanidx/yaml/perms/POE::Component::SmokeBox::Dists

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 04 Mar 2010 11:39:14 GMT
  Server: lighttpd/1.4.25

  ---
  -
    mod_name: POE::Component::SmokeBox::Dists
    cpan_id: BINGOS
    perms: f

=item C<timestamp>

Does not take a search term. Returns a timestamp of when the CPAN Index Database was last updated
and when the packages file that was used was last updated. Both values are in epoch time.

  curl -i http://name.of.website/cpanidx/yaml/timestamp

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Wed, 09 Jun 2010 10:16:15 GMT
  Server: lighttpd/1.4.25

  ---
  -
    lastupdated: 1276075625
    timestamp: 1276077865

=item C<topten>

Does not take a search term. Returns a list of the authors with the most distributions. This is not the
most accurate, try L<http://thegestalt.org/simon/perl/wholecpan.html> for a more accurate leaderboard.

  curl -i http://name.of.website/cpanidx/yaml/topten

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 04 Mar 2010 11:44:44 GMT
  Server: lighttpd/1.4.25

  ---
  -
    cpan_id: ADAMK
    dists: 237
  -
    cpan_id: RJBS
    dists: 215
  -
    cpan_id: ZOFFIX
    dists: 212
  -
    cpan_id: MIYAGAWA
    dists: 190
  -
    cpan_id: SMUELLER
    dists: 130
  -
    cpan_id: NUFFIN
    dists: 122
  -
    cpan_id: TOKUHIROM
    dists: 121
  -
    cpan_id: BINGOS
    dists: 121
  -
    cpan_id: GUGOD
    dists: 118
  -
    cpan_id: MARCEL
    dists: 114

=item C<mirrors>

Does not take a search term. Returns a list of CPAN mirror sites as listed in the C<MIRRORED.BY> file.

  curl -i http://name.of.website/cpanidx/yaml/mirrors

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Mon, 19 Apr 2010 14:52:52 GMT
  Server: lighttpd/1.4.25

  ---
  -
    dst_bandwidth: STM-1
    dst_contact: tenet.ac.za^aa
    dst_ftp: ftp://cpan.mirror.ac.za/
    dst_http: http://cpan.mirror.ac.za/
    dst_location: 'Cape Town, South Africa, Africa (-33.93 18.47)'
    dst_notes: ''
    dst_organisation: TENET
    dst_rsync: mirror.ac.za::cpan
    dst_src: rsync://www.cpan.org/CPAN/
    dst_timezone: '+2'
    frequency: '12 Hourly'
    hostname: mirror.ac.za
  -
    dst_bandwidth: 50MB
    dst_contact: is.co.za|ftpadmin
    dst_ftp: ftp://ftp.is.co.za/pub/cpan/
    dst_http: http://mirror.is.co.za/pub/cpan/
    dst_location: 'Johannesburg, Gauteng, South Africa, Africa (-26.17 28.03)'
    dst_notes: 'Limit to 4 simultaneous connections.'
    dst_organisation: 'Internet Solutions'
    dst_rsync: ftp.is.co.za::IS-Mirror/ftp.cpan.org/
    dst_src: rsync.nic.funet.fi
    dst_timezone: '+2'
    frequency: daily
    hostname: is.co.za
  -
    dst_bandwidth: T3
    dst_contact: saix.net=ftp
    dst_ftp: ftp://ftp.saix.net/pub/CPAN/
    dst_http: ''
    dst_location: 'Parow, Western Cape, South Africa, Africa (-33.9064 18.5631)'
    dst_notes: ''
    dst_organisation: 'South African Internet eXchange (SAIX)'
    dst_rsync: ''
    dst_src: ftp.funet.fi
    dst_timezone: '+2'
    frequency: daily
    hostname: saix.net
  -

etc. etc.

=item C<corelist>

Takes a search term which is a module name to search for. Returns information if that module is shipped
with perl core.

  curl -i http://name.of.website/cpanidx/yaml/corelist/Class::ISA

  HTTP/1.1 200 OK
  Content-type: application/x-yaml; charset=utf-8
  Transfer-Encoding: chunked
  Date: Thu, 06 May 2010 09:31:25 GMT
  Server: lighttpd/1.4.25

  ---
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.007003
    released: 2002-03-05
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008
    released: 2002-07-19
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008001
    released: 2003-09-25
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008002
    released: 2003-11-05
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008003
    released: 2004-01-14
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008004
    released: 2004-04-21
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008005
    released: 2004-07-19
  -
    deprecated: 0
    mod_vers: 0.32
    perl_ver: 5.008006
    released: 2004-11-27

etc etc.

=back

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Config::Tiny>

L<DBI>

L<FCGI>

=cut
