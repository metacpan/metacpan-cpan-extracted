#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for App::OpenHAP::Host: the host wiring around the sans-IO
# Protocol::HAP::Server engine. The engine's own behavior is covered
# in t/protocol/server.t.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);

BEGIN {
    eval {
        require IO::Socket::INET;
        require Crypt::Ed25519;
    };
    if ($@) {
        plan skip_all => 'Required modules not available';
    }
}

use_ok('App::OpenHAP::Host');
use_ok('Protocol::HAP::Store::File');
use_ok('Fugu::Mdnsd');

# Test host creation: the engine is built over
# Protocol::HAP::Store::File and the host contracts
{
    my $temp_dir = tempdir(CLEANUP => 1);
    my $server = App::OpenHAP::Host->new(
        port         => 51827,
        pin          => '123-45-678',
        name         => 'Test Bridge',
        storage_path => $temp_dir,
    );

    ok(defined $server, 'server object created');
    isa_ok($server, 'App::OpenHAP::Host');
    ok(defined $server->{storage}, 'storage initialized');
    isa_ok($server->engine, 'Protocol::HAP::Server');
    ok(!$server->is_paired, 'not paired initially');

    # The engine persists through the host's storage
    $server->{storage}->save_pairing('test-controller', 'X' x 32, 1);
    ok($server->is_paired, 'paired state reaches through the engine');
}

# update_config_number delegates to the engine over the host storage
{
    my $temp_dir = tempdir(CLEANUP => 1);
    my %args = (
        port         => 51834,
        pin          => '123-45-678',
        storage_path => $temp_dir,
    );

    my $server = App::OpenHAP::Host->new(%args);
    is($server->update_config_number, 1,
        '[HAP-mDNS §3.1] first run keeps c# at 1');

    # Restart with the same database: the c# does not change
    my $server2 = App::OpenHAP::Host->new(%args);
    is($server2->update_config_number, 1,
        '[HAP-mDNS §8] c# persisted across restart');
}

# The TXT string formatter joins key=value pairs with '.' in sorted
# key order. The TXT delimiter of mdnsd makes the order observable.
# Thus the order must be deterministic ([HAP-mDNS §2]).
{
    my $temp_dir = tempdir(CLEANUP => 1);
    my $server = App::OpenHAP::Host->new(
        port         => 51836,
        pin          => '123-45-678',
        storage_path => $temp_dir,
    );

    my $txt     = $server->mdns_txt_string;
    my $records = $server->engine->mdns_txt_records;

    # No default value carries a '.', so the pairs split back apart
    my @pairs = split /\./, $txt;
    is(scalar @pairs, scalar keys %$records,
        '[HAP-mDNS §2] every TXT record is one dot-separated pair');

    my @keys = map { /^([^=]+)=/ ? $1 : () } @pairs;
    is_deeply(\@keys, [sort keys %$records],
        'pairs appear in sorted key order');

    my %parsed = map { split /=/, $_, 2 } @pairs;
    is_deeply(\%parsed, $records, 'formatted string carries the records');
}

# Test mDNS re-advertisement on pairing change ([HAP-mDNS §8]). The
# engine calls on_pairing_changed; the host publishes.
{
    package MockMDNS;

    sub new($class) { bless { updates => [], published => 1 }, $class }

    sub is_published($self) { return $self->{published} }

    sub update_txt($self, %args)
    {
        push @{ $self->{updates} }, $args{txt};
        return 1;
    }

    sub error($self) { return }

    package main;

    my $temp_dir = tempdir(CLEANUP => 1);
    my $server = App::OpenHAP::Host->new(
        port         => 51835,
        pin          => '123-45-678',
        storage_path => $temp_dir,
    );
    my $mdns = MockMDNS->new;
    $server->set_mdns($mdns);

    # Pairing added: sf flips to 0 and the host re-advertises the
    # TXT record
    $server->_refresh_mdns(1);
    is(scalar @{ $mdns->{updates} }, 1,
        '[HAP-mDNS §8] TXT re-advertised when the engine reports a flip');

    $server->{storage}->save_pairing('controller', 'X' x 32, 1);
    $server->_refresh_mdns(1);
    like($mdns->{updates}[1], qr/(?:^|\.)sf=0(?:\.|$)/,
        'advertised sf=0 once paired');

    # Pairing removed: the host re-advertises with sf=1
    $server->{storage}->remove_all_pairings;
    $server->_refresh_mdns(0);
    like($mdns->{updates}[2], qr/(?:^|\.)sf=1(?:\.|$)/,
        '[HAP-mDNS §8] advertised sf=1 when pairing removed');

    # Unpublished handle: the pairing path must never drive an update
    # onto it
    $mdns->{published} = 0;
    $server->_refresh_mdns(1);
    is(scalar @{ $mdns->{updates} }, 3,
        'no TXT update pushed while unpublished');
}

# control_status composes engine introspection with host state
{
    my $temp_dir = tempdir(CLEANUP => 1);
    my $server = App::OpenHAP::Host->new(
        port         => 51837,
        pin          => '123-45-678',
        name         => 'Status Bridge',
        storage_path => $temp_dir,
    );

    my $status = $server->control_status;
    is($status->{name}, 'Status Bridge', 'status carries the name');
    is($status->{port}, 51837, 'status carries the port');
    is($status->{paired}, 0, 'status reports unpaired');
    is($status->{pairings}, 0, 'status counts pairings');
    is($status->{devices}, 0, 'status counts devices');
    is($status->{connections}, 0, 'status counts connections');
    is($status->{mdns}, 'absent', 'status reports mdns absent');
    is($status->{mqtt}, 'none', 'status reports mqtt none');
    ok(defined $status->{started}, 'status carries the start time');

    is_deeply($server->control_devices, [],
        'control_devices is empty without devices');
}

done_testing();
