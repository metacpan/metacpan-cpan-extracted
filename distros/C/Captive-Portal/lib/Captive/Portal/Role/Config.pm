package Captive::Portal::Role::Config;

use strict;
use warnings;

=head1 NAME

Captive::Portal::Role::Config - config reader for Captive::Portal

=head1 DESCRIPTION

Config file parser and storage for cfg hash. The configuration syntax is perl.


=cut

our $VERSION = '4.10';

use Log::Log4perl qw(:easy);
use FindBin qw($Bin);
use File::Spec::Functions qw(splitdir rootdir catfile catdir);

use Role::Basic;

# just bin/../ => bin
my @bin_parts = splitdir($Bin);
pop(@bin_parts);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant ON  => 1;
use constant OFF => 0;

use constant YES => 'yes';
use constant NO  => '';

use vars qw($APP_NAME $APP_DIR);

$APP_NAME = 'capo';
$APP_DIR  = catdir(@bin_parts);

# SINGLETON
my $cfg_hash = {};

=head1 PRESET GLOBAL PACKAGE VARIABLES

The following variables are predefined and can be used for interpolation in config values.

 $APP_NAME = 'capo'

 $APP_DIR = "$Bin/../"

=head1 PRESET DEFAULTS

=over 4

=item DOCUMENT_ROOT => "$APP_DIR/static"

Basedir for static content like images, css or error pages.

=item TEMPLATE_INCLUDE_PATH => "$APP_DIR/templates/local/:$APP_DIR/templates/orig"

Directories to search for templates.

=item RUN_USER => 'wwwrun'

Drop privileges to RUN_USER.

=item RUN_GROUP => 'www',

Drop privileges to RUN_GROUP.

=item SESSIONS_DIR => "/var/cache/$APP_NAME"

Where to store the session files. This directory must exist und must be readable/writeable by RUN_USER.

=item SSL_REQUIRED => ON

A JS script looks for SSL encryption of the login/splash page and throws an error when not. Maybe a man-in-the-middle plays http-https proxy like sslstrip(8). If the mitm strips JS then this doesn't help anyway. The users must check the location bar for HTTPS these days, sigh.

=item SESSION_MAX => 48 * 3600    # 2d

Max session time until a forced disconnect.

=item IDLE_TIME => 60 * 10      # 10 min

How long to wait for activity from ip/mac until a session is marked idle.

=item KEEP_OLD_STATE_PERIOD => 1 * 60 * 60,  # 1h

How long to keep idle session records on disk for fast reconnect with proper ip/mac/cookie match.

=back

=head1 LOCAL PARAMETERS

=over 4

=item ADMIN_SECRET

Passphrase for detailed sessions view.

=item AUTHEN_SIMPLE_MODULES

Authentication is handled by the Authen::Simple framework. You may stack any of the Authen::Simple::... plugins for authentication, see the $Bin/../etc/config.pl template.

=item IPTABLES->capture_if => 'eth1'

The inside gateway interface, e.g. 'eth1'. All http traffic, not allowed by any predefined rule, is captured and redirected to the capo.fcgi script.

=item IPTABLES->capture_net => '192.168.0.0/22'

The inside IP network in CIDR notation, e.g. '192.168.0.0/22'

=item IPTABLES->capture_ports => [80, 8080]

What tcp ports should be captured and redirected, e.g. [ 80, 8080]

=item IPTABLES->redirect_port => 5281

The port where the HTTP-server is listen in order to rewrite this http request to an https request.

The above settings result in a NAT rule equivalent to:

 iptables -t nat -A PREROUTING -i eth1 -s 192.168.0.0/22 ! -d 192.168.0.0/22 \
          -p tcp -m multiport --dports 80,8080 -j  REDIRECT --to-port 5281

=item IPTABLES->throttle => OFF

You may throttle HTTP/HTTPS requests/sec per client IP. Some clients/gadgets fire a lot of HTTP traffic without human intervention. Depending on your hardware and your encryption resources this will overload your gateway.

=item IPTABLES->throttle_ports => [ 80, 5281]

You should protect/throttle port 80 and the redirect_port (see above).


=item IPTABLES->throttle_seconds => 30

=item IPTABLES->throttle_hitcount => 15

Both parameters define the average and the burst. Average is hitcount/seconds and burst is hitcount in seconds. With the values of 30 and 15, the average would be 15hits/30s => 1hit/2s. The burst would be 15hits in 30 seconds.

The above settings result in iptable rules equivalent to:

 # throttle/drop new connections
 iptables -t filter -A INPUT -p tcp --syn -m multiport --dports 80,5281 \
    -m recent --name capo_throttle --rcheck --seconds 30 --hitcount 15 -j DROP

 # at last accept new connections but set/update the recent table
 iptables -t filter -A INPUT -p tcp --syn -m multiport --dports 80,5281 \
    -m recent --name capo_throttle --set -j ACCEPT

=item IPTABLES->open_services

Allow access to open local services like DHCP, DNS, NTP, ...

=item IPTABLES->open_clients

Allow access for some dumb clients without authentication.

=item IPTABLES->open_servers

Allow access to some open servers.

=item IPTABLES->open_networks

Allow access to some open networks.

=item I18N_LANGUAGES

Supported languages for system messages and HTML templates.

=item I18N_FALLBACK_LANG

Fallback language if the client message isn't supported in the system message catalog and templates.

=item I18N_MSG_CATALOG

Translations of the system messages.

=back

=cut

my %pre_defaults = (
    DOCUMENT_ROOT => catdir( $APP_DIR, 'static' ),

    TEMPLATE_INCLUDE_PATH => catdir( $APP_DIR, 'templates', 'local' ) . ':'
      . catdir( $APP_DIR, 'templates', 'orig' ),

    SESSIONS_DIR => catdir( rootdir(), 'var', 'cache', $APP_NAME ),

    RUN_USER  => 'wwwrun',
    RUN_GROUP => 'www',

    SSL_REQUIRED          => ON,
    SESSION_MAX           => 2 * 24 * 60 * 60,    # 2 days
    KEEP_OLD_STATE_PERIOD => 1 * 60 * 60,         # 1h

    IDLE_TIME     => 10 * 60,                     # 10min before set to idle

    I18N_LANGUAGES     => [ 'en', ],
    I18N_FALLBACK_LANG => 'en',
);

# Role::Basic exports ALL subroutines, there is currently no other way to
# prevent exporting private methods, sigh
#
my ($_priv_post_defaults, $_priv_check_cfg);

=head1 ROLES

=over

=item $capo->parse_cfg_file($filename)

Parse config file, merge with defaults. Die on error.

=cut

sub parse_cfg_file {
    my $self     = shift;
    my $cfg_file = shift;
    LOGDIE "missing parameter 'config_file'" unless defined $cfg_file;

    DEBUG "preset cfg_hash with default values";
    $cfg_hash = {%pre_defaults};

    DEBUG "parse config file $cfg_file";
    my $parsed_cfg_file = do $cfg_file;

    # check the config file for syntactic errors
    LOGDIE "couldn't parse $cfg_file: $@" if $@;
    LOGDIE "couldn't do $cfg_file: $!"
      unless defined $parsed_cfg_file;
    LOGDIE "couldn't run $cfg_file" unless $parsed_cfg_file;

    DEBUG "merge parsed values with preset default values to cfg_hash";
    $cfg_hash = { %$cfg_hash, %$parsed_cfg_file };

    $self->$_priv_check_cfg();

    $self->$_priv_post_defaults();

    return 1;
}

=item $capo->cfg()

Getter, return a shallow copy of the config hashref.

=cut

sub cfg { return {%$cfg_hash}; }

#
# Add some defaults after reading cfg file. Must be postponed to
# interpolate of already set params.
#

$_priv_post_defaults = sub {
    my $self     = shift;

    # defined as anonymous sub,
    # else Role::Basic would export this as role, sigh!

    DEBUG "add post_parse config default values, if needed";

    unless ( exists $cfg_hash->{LOCK_FILE} ) {
        $cfg_hash->{LOCK_FILE} =
          catfile( $cfg_hash->{SESSIONS_DIR}, 'capo-ctl.lock' );
    }
};

#
# semantic params validation of cfg_hash
#

$_priv_check_cfg = sub {

    # defined as anonymous sub,
    # else Role::Basic would export this as role, sigh!

    DEBUG "do cfg_hash params validation";

    # check the config file for sematic errors and warnings
    if ( $cfg_hash->{BOILERPLATE} ) {
        LOGDIE 'FATAL: the config file is in BOILERPLATE state';
    }

    unless ( $cfg_hash->{SESSIONS_DIR} ) {
        LOGDIE 'FATAL: missing SESSIONS_DIR in cfg file';
    }

    if ( $cfg_hash->{MOCK_MAC} ) {
        ERROR "uncomment 'MOCK_MAC' for production in cfg file";
    }

    if ( $cfg_hash->{MOCK_FIREWALL} ) {
        ERROR "uncomment 'MOCK_FIREWALL' for production in cfg file";
    }

    if ( $cfg_hash->{MOCK_AUTHEN} ) {
        ERROR "uncomment 'MOCK_AUTHEN' for production in cfg file";
    }
    else {
        ERROR 'missing Authen::Simple modules in cfg file'
          unless $cfg_hash->{'AUTHEN_SIMPLE_MODULES'};
    }

    unless ( $cfg_hash->{ADMIN_SECRET} ) {
        ERROR 'missing ADMIN_SECRET in cfg file';
    }

    unless ( $cfg_hash->{SSL_REQUIRED} ) {
        ERROR 'set SSL_REQUIRED for production in cfg file';
    }

    unless ( $cfg_hash->{IPTABLES}{capture_if} ) {
        ERROR "missing 'capture_if' in cfg file";
    }

    unless ( $cfg_hash->{IPTABLES}{capture_net} ) {
        ERROR "missing 'capture_net' in cfg file";
    }

    unless ( $cfg_hash->{IPTABLES}{capture_ports} ) {
        ERROR "missing 'capture_ports' in cfg file";
    }

    unless ( $cfg_hash->{IPTABLES}{redirect_port} ) {
        ERROR "missing 'redirect_port' in cfg file";
    }
};

1;

=back

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

#vim: sw=4
