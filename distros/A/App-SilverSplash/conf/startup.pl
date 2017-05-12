#!/usr/bin/perl

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} or die "GATEWAY_INTERFACE not Perl!";

$|++;

print "Loading modules...\n";

use Config::SL ();

our $Config = SL::Config->new();

use APR::Table                         ();
use Apache2::RequestRec                ();
use Apache2::RequestUtil               ();
use Apache2::Log                       ();
use Apache2::Connection                ();
use Apache2::ConnectionUtil            ();
use Apache2::ServerUtil                ();
use Apache2::URI                       ();
use Apache2::Response                  ();
use Apache2::Request                   ();
use Apache2::RequestIO                 ();
use Apache2::Connection::XForwardedFor ();

use Business::PayPal ();
use Template         ();
use URI::Escape      ();

use App::SilverSplash           ();
use App::SilverSplash::Apache2  ();
use App::SilverSplash::IPTables ();

if ( Apache2::ServerUtil::restart_count() > 1 ) {
    print "Initializing firewall...\n";
    App::SilverSplash::IPTables->init_firewall;
}

# BROKEN
# register cleanup
# print "Registering cleanup handler...\n";
#Apache2::ServerUtil::server_shutdown_cleanup_register(
#    \&App::SilverSplash::IPTables::clear_firewall );

print "Startup.pl finished...\n";

1;
