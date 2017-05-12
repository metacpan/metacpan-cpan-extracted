#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '4.10';

=head1 NAME

capo.fcgi - (f)cgi script for Captive::Portal

=head1 ABSTRACT

(f)cgi script to handle http(s) requests for Captive::Portal.

=head1 DESCRIPTION

This script is started by the HTTP server. It can be used as a simple CGI script, but for heavy loaded sites FastCGI is strongly recommended.

=cut

use sigtrap qw(die untrapped normal-signals);

use FindBin qw($Bin $Script);
use lib "$Bin/../lib";

use Log::Log4perl qw(:easy);
use CGI::Fast;
use Captive::Portal;

$ENV{PATH} = '/sbin:/bin:/usr/sbin:/usr/bin';

=head1 CONFIGURATION

The Captive::Portal config file is searched in the following places:

    $ENV{CAPTIVE_PORTAL_CONFIG} ||
    $Bin/../etc/local/config.pl ||
    $Bin/../etc/config.pl

=head1 LOGGING

The Log::Log4perl config file is searched in the following places:

    $ENV{CAPTIVE_PORTAL_LOG4PERL}   ||
    $Bin/../etc/local/log4perl.conf ||
    $Bin/../etc/log4perl.conf

=cut

#####################################################################
# put scriptname in process table instead of plain 'perl'
#####################################################################
$0 = $Script;

#####################################################################
# search for config files in default places
#####################################################################

my $cfg_file =
     $ENV{CAPTIVE_PORTAL_CONFIG}
  || -e "$Bin/../etc/local/config.pl" && "$Bin/../etc/local/config.pl"
  || -e "$Bin/../etc/config.pl" && "$Bin/../etc/config.pl";

my $log4perl = $ENV{CAPTIVE_PORTAL_LOG4PERL}
  || -e "$Bin/../etc/local/log4perl.conf"
  && "$Bin/../etc/local/log4perl.conf"
  || -e "$Bin/../etc/log4perl.conf" && "$Bin/../etc/log4perl.conf";

if ( $log4perl && -f $log4perl ) {
    Log::Log4perl->init($log4perl);
}
else {
    Log::Log4perl->easy_init($DEBUG);
}

=head1 CLIENT API

=over

=item C<https://capo.acme.org/capo>

Return the B<splash-page> with login form.

=item C<https://capo.acme.org/capo?login=username;password=secret>

Login the user, return the B<active-page> with logout form.

=item C<https://capo.acme.org/capo?logout=true>

Logout the user, return the B<splash-page> with login form.

=back

=head1 ADMIN API

=over

=item C<https://capo.acme.org/capo/status>

Return the B<summary-status-page> with admin-secret form.

=item C<https://capo.acme.org/capo/status?admin_secret=secret>

Return the B<detail-status-page>.

=item C<https://capo.acme.org/capo/status?admin_secret=secret;astext=true>

Return the B<detail-status-page> as text/plain.

=item C<https://capo.acme.org/capo/is_running>

Return the number of active clients (ipset entries) as text/plain.

Example:

  RUNNING 1340 rules loaded

=back

=cut

#####################################################################
# create Captive::Portal object and enter request loop
#####################################################################

DEBUG("create new Captive::Portal object ...");
my $capo = Captive::Portal->new( cfg_file => $cfg_file );

# main-loop
while ( my $q = CGI::Fast->new ) {
    $capo->run($q);
}

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Karl Gaissmaier, all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

=cut
