#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MQTT-Transport.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Device');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

use constant AVAILABILITY_ONLINE  => 1;
use constant AVAILABILITY_OFFLINE => 2;

sub make_base ( $mqtt, %extra )
{
	return App::OpenHAP::Tasmota::Device->new(
		aid         => 2,
		name        => 'Transport Test',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
		%extra,
	);
}

subtest '[MQTT-Transport §1][MQTT-Transport §1.1] topic prefixes' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);
	$base->subscribe_mqtt;

	my @subs = $mqtt->get_subscriptions;
	ok( ( grep {m{^tele/}} @subs ), 'subscribes under tele/ prefix' );
	ok( ( grep {m{^stat/}} @subs ), 'subscribes under stat/ prefix' );
	ok( !( grep {m{^cmnd/}} @subs ),
		'does not subscribe to cmnd/ (device-inbound prefix)' );

	$mqtt->clear_published;
	$base->query_status;
	my @published = $mqtt->get_published;
	ok( ( grep { $_->{topic} =~ m{^cmnd/} } @published ),
		'commands published under cmnd/ prefix' );
};

subtest '[MQTT-Transport §1.2] FullTopic pattern' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;

	# The builder speaks the default pattern, %prefix%/%topic%/,
	# and no other: OpenHAP requires the Tasmota default.
	my $default = make_base($mqtt);
	is( $default->_build_topic( 'cmnd', 'Power' ),
		'cmnd/device/Power', 'default FullTopic %prefix%/%topic%/' );
	is( $default->_build_topic( 'stat', 'RESULT' ),
		'stat/device/RESULT', 'default stat topic' );
	is( $default->_build_topic( 'tele', 'STATE' ),
		'tele/device/STATE', 'default tele topic' );
};

subtest '[MQTT-Transport §1.3] topic tokens' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);

	# The builder fills the %prefix% and %topic% positions of the
	# default pattern with the prefix and the device topic
	my $built = $base->_build_topic( 'tele', 'SENSOR' );
	is( $built, 'tele/device/SENSOR',
		'%topic% and %prefix% tokens substituted' );
};

subtest '[MQTT-Transport §1.4] LWT special topic' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);
	$base->subscribe_mqtt;

	ok( ( grep { $_ eq 'tele/device/LWT' } $mqtt->get_subscriptions ),
		'subscribed to tele/+/LWT' );

	$mqtt->simulate_message( 'tele/device/LWT', 'Online' );
	is( $base->{availability}, AVAILABILITY_ONLINE,
		'LWT Online marks device available' );
	ok( $base->is_online, 'is_online after LWT Online' );
};

subtest '[MQTT-Transport §2][MQTT-Transport §2.1] command topic and payload' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
	);

	$mqtt->clear_published;
	$heater->set_power(1);
	my ($cmd) = $mqtt->get_published;
	is( $cmd->{topic}, 'cmnd/device/Power',
		'command sent to cmnd/%topic%/<Command>' );
	is( $cmd->{payload}, 'ON', 'payload carries the command value' );
};

subtest '[MQTT-Transport §2.3] query pattern' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);
	$base->subscribe_mqtt;

	# On LWT Online, the accessory queries the device state with
	# Status 11
	$mqtt->clear_published;
	$mqtt->simulate_message( 'tele/device/LWT', 'Online' );
	ok(
		( grep {
			$_->{topic} eq 'cmnd/device/Status'
			    && $_->{payload} eq '11'
		} $mqtt->get_published ),
		'state queried via cmnd Status 11'
	);
};

subtest '[MQTT-Transport §2.4] bidirectional flow' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
	);
	$heater->subscribe_mqtt;

	# The command goes out on cmnd/. The state comes back in on
	# stat/.
	$mqtt->clear_published;
	$heater->set_power(1);
	ok( ( grep { $_->{topic} =~ m{^cmnd/} } $mqtt->get_published ),
		'HAP write flows out on cmnd/' );

	$mqtt->simulate_message( 'stat/device/RESULT', '{"POWER":"OFF"}' );
	is( $heater->{power_state}, 0,
		'[MQTT-Transport §2.2] device state flows back in on stat/' );
};

subtest 'SetOption4 responses on command-named topics' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;

	# SO4: responses on command-named topics instead of RESULT
	my $light = App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 3,
		name         => 'SO4 Light',
		mqtt_topic   => 'light',
		mqtt_client  => $mqtt,
		capabilities => App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER()
		    | App::OpenHAP::Tasmota::Lightbulb::CAP_COLOR()
		    | App::OpenHAP::Tasmota::Lightbulb::CAP_CT(),
	);
	$light->subscribe_mqtt;
	my @subs = $mqtt->get_subscriptions;
	for my $topic (qw(DIMMER HSBCOLOR CT)) {
		ok( ( grep { $_ eq "stat/light/$topic" } @subs ),
			"SetOption4: subscribed to stat/+/$topic" );
	}
};

subtest '[MQTT-Transport §4][MQTT-Transport §4.2] LWT Online/Offline handling' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);
	$base->subscribe_mqtt;

	$mqtt->simulate_message( 'tele/device/LWT', 'Online' );
	is( $base->{availability}, AVAILABILITY_ONLINE,
		'LWT Online sets availability' );

	$mqtt->simulate_message( 'tele/device/LWT', 'Offline' );
	is( $base->{availability}, AVAILABILITY_OFFLINE,
		'LWT Offline sets availability' );
	ok( !$base->is_online, 'device reported unavailable' );
};

subtest '[MQTT-Transport §5][MQTT-Transport §5.2] reconnection state refresh' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = make_base($mqtt);
	$base->subscribe_mqtt;

	# After an Offline/Online cycle, the accessory queries the state
	# again
	$mqtt->simulate_message( 'tele/device/LWT', 'Offline' );
	$mqtt->clear_published;
	$mqtt->simulate_message( 'tele/device/LWT', 'Online' );
	ok(
		( grep {
			$_->{topic} eq 'cmnd/device/Status'
			    && $_->{payload} eq '11'
		} $mqtt->get_published ),
		'Status 11 re-queried after reconnect'
	);
};

done_testing();
