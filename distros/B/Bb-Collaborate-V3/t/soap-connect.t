#!perl
use warnings; use strict;
use Test::More tests => 18;
use Test::Fatal;

use lib '.';
use t::Bb::Collaborate::V3;

use Bb::Collaborate::V3;
# don't 'use' anything here! We're testing Elive's ability to load the
# other required classes (Elive::Connection, Elive::Entity::User etc)

our $t = Test::More->builder;

SKIP: {

    my %result = t::Bb::Collaborate::V3->test_connection(noload => 1);
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 18)
	unless $auth && @$auth;

    my $connection_class = $result{class};

    my $connection;

    if ($connection_class eq 'Bb::Collaborate::V3::Connection') {
	#
	# exercise a direct connection from Elive main. No preload
	# of connection or entity classes.
	#
        note("connecting: @$auth");
	
	is( exception {$connection = Bb::Collaborate::V3::Connection->connect(@$auth)} => undef,
	      "Bb::Collaborate::V3::Connection->connect(...) - lives");
    }
    else {
	eval "require $connection_class";
	die $@ if $@;

	note ("connecting: user=$auth->[1], url=$auth->[0]");

	is( exception {$connection = $connection_class->connect(@$auth)} => undef,
		       "${connection_class}->connect(...) - lives");
	Bb::Collaborate::V3->connection($connection);
    }

    ok($connection, 'got connection');

    BAIL_OUT("unable to connect - aborting further tests")
	unless $t->is_passing;

    isa_ok($connection, $connection_class,'connection')
	or exit(1);

    my $scheduling_manager;
    is ( exception {$scheduling_manager = $connection->scheduling_manager} => undef,
	      '$connection->scheduling_manager - lives');
    isa_ok($scheduling_manager, 'Bb::Collaborate::V3::SchedulingManager','scheduling_manager');
    my %min_version_nums = (ELM => '3.5.0', SAS => '7.2.0-935');
    my %max_version_nums = (ELM => '3.7.0', SAS => '7.7.0-205');

    ok(my $scheduler_version = $scheduling_manager->version, 'got server version');
    ok(my $scheduler_manager = $scheduling_manager->manager, 'got server manager');

    my $min_version_num = $min_version_nums{$scheduler_manager};
    my $max_version_num = $max_version_nums{$scheduler_manager};

    ok $min_version_num, "known schedular manager"
        or diag "unknown scheduler manager, expected ELM or SAS, found: $scheduler_manager";

    my ($scheduler_version_num) = ($scheduler_version =~ m{([\d\.\-]+)});
    ok $scheduler_version_num, 'extracted scheduler version number'
        or diag "unable to extract version number: $scheduler_version";
    note ("Collaborate $scheduler_manager manager $scheduler_version_num");
    ok($scheduler_version_num ge $min_version_num, "Collaborate server is $min_version_num or higher");

    my $manager = $scheduling_manager->manager;

    if ($scheduler_version_num gt $max_version_num) {
	diag "************************";
	diag "Note: Collaborate server version is ".$scheduler_version_num;
	diag "      This Bb::Collaborate::V3 release ($Bb::Collaborate::V3::VERSION) has been tested against $scheduler_manager on $min_version_num - $max_version_num";
	diag "      You might want to check CPAN for a more recent version of Bb::Collaborate::V3.";
	diag "************************";
    }

    my $sc;
    is ( exception {$sc = $connection->server_configuration} => undef, 'get server_configuration - lives');
    isa_ok($sc, 'Bb::Collaborate::V3::Server::Configuration','server_configuration');
    note "server config:-";
    note "   -- boundary:@{[ $sc->boundaryTime ]}  max-talkers:@{[ $sc->maxAvailableTalkers ]}  max-cameras:@{[ $sc->maxAvailableCameras ]}";
    note "   -- telephony:@{[ $sc->mayUseTelephony ]}  secure-sign-on:@{[ $sc->mayUseSecureSignOn ]}  must-reserve-seats:@{[ $sc->mustReserveSeats ]}";
    note "   -- time-zone:@{[ $sc->timeZone ]}";


    my $server_version;
    is ( exception {$server_version = $connection->server_versions} => undef, 'get server_versions - lives');
    if ($server_version) {
	isa_ok($server_version, 'Bb::Collaborate::V3::Server::Version','server_version');

	note 'Collaborate '.$scheduler_manager.' server '.$server_version->versionName.' ('.$server_version->versionId.')';
    }
    else {
	diag "unable to get server versions - are all servers running?";
	$t->skip ("unable to get server version - skipping");
    }

    my $quota_limits;
    is ( exception {$quota_limits = $connection->quota_limits} => undef, 'get quota_limits - lives');
    if ($quota_limits) {
	isa_ok($quota_limits->[0], 'Bb::Collaborate::V3::Server::QuotaLimits','quota_limits');

	note 'Bb Collaborate Quota Usage :-';
	for my $quota (@$quota_limits) {
	    note '   -- '.sprintf("%-20s", $quota->quotaName).': '.$quota->quotaUsage.' used of '.$quota->quotaAvailable." availiable (@{[ sprintf('%.2f', 100 * $quota->quotaUsage /( $quota->quotaAvailable || 1) ) ]}%).";
	}
    }
    else {
	$t->skip ("unable to get quota limits - skipping");
    }

    my $telephony_license;
    is ( exception {$telephony_license = $connection->telephony_license} => undef, 'get telephony_license - lives');
    if ($telephony_license) {
	like($telephony_license, qr/thirdParty|integrated|none/,'telephony_license');

	note 'Bb Collaborate Telephony License: ' . $telephony_license;
    }
    else {
	$t->skip ("unable to get telephony license - skipping");
    }

    $connection->disconnect;
}

