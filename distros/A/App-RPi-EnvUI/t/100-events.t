use strict;
use warnings;

BEGIN {
    use lib 't/';
    use TestBase;
    config();
    db_create();
}

use App::RPi::EnvUI::API;
use App::RPi::EnvUI::DB;
use App::RPi::EnvUI::Event;
use Data::Dumper;
use Mock::Sub no_warnings => 1;
use Test::More;

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    test_mock => 1,
    config_file => 't/envui.json'
);
my $evt = App::RPi::EnvUI::Event->new(testing => 1);

my $db = App::RPi::EnvUI::DB->new(testing => 1);
$api->db($db);

my $mock = Mock::Sub->new;

my $temp_sub = $mock->mock(
    'RPi::DHT11::temp',
    return_value => 80
);

my $hum_sub = $mock->mock(
    'RPi::DHT11::humidity',
    return_value => 20
);

is ref $evt, 'App::RPi::EnvUI::Event', "new() returns a proper object";
is $api->testing, 1, "testing param to new() ok";

#FIXME: add tests to test overrides for hum and temp

# mock out some subs that rely on external C libraries

# set the event timers

$db->update('core', 'value', 1, 'id', 'event_fetch_timer');
my $f = $api->_config_core('event_fetch_timer');
is $f, 1, "event_fetch_timer set ok for testing";

$db->update('core', 'value', 1, 'id', 'event_action_timer');
my $a = $api->_config_core('event_action_timer');
is $a, 1, "event_action_timer set ok for testing";

# configure pins

my $taux = $api->env_temp_aux;
my $tpin = $api->aux_pin($taux, 0);
is $tpin, 0, "set temp aux to pin for testing ok";

my $haux = $api->env_humidity_aux;
my $hpin = $api->aux_pin($haux, 0);
is $hpin, 0, "set humidity aux to pin for testing ok";

{ # read_sensor()

    $temp_sub->return_value(99);
    $hum_sub->return_value(99);

    my @env = $api->read_sensor;

    is @env, 2, "mocked read_sensor() returns proper count of values";
    is $env[0], 99, "first elem of return ok (temp)";
    is $env[1], 99, "second elem of return ok (humidity)";
}

{ # env_to_db()

    $temp_sub->return_value(99);
    $hum_sub->return_value(99);

    my $event = $evt->env_to_db;
    $api->{events}{env_to_db} = $event;

    $event->start;
    sleep 1;
    $event->stop;

    my $env = $api->env;

    is $env->{temp}, 99, "temp val ok in env_to_db() event";
    is $env->{humidity}, 99, "hum val ok in env_to_db() event";
}

{ # another env_to_db()

    $temp_sub->return_value(80);
    $hum_sub->return_value(20);

    my $event = $evt->env_to_db( $api );
    $api->{events}{env_to_db} = $event;

    $event->start;
    sleep 1;
    $event->stop;

    my $env = $api->env;

    is $env->{temp}, 80, "temp val ok in env_to_db() event after update";
    is $env->{humidity}, 20, "hum val ok in env_to_db() event after update";
}

{ # env_to_db() check all fields

    $temp_sub->return_value(80);
    $hum_sub->return_value(20);

    my $event = $evt->env_to_db($api);
    $api->{events}{env_to_db} = $event;

    $event->start;
    sleep 1;
    $event->stop;

    my $env = $api->env;

    is keys %$env, 5, "the correct number of keys in the return ok";

    is $env->{temp}, 80, "temp val ok in env_to_db() event after update";
    is $env->{humidity}, 20, "hum val ok in env_to_db() event after update";
}

{ # env_action (temp below limit)

    my $event = $evt->env_action($api);

    $db->insert_env(79, 21);

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($taux),
        0,
        "env_action() doesn't trigger temp state if < limit";
}

{ # env_action() temp above limit

    my $event = $evt->env_action($api);
    $db->insert_env(99, 21);

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($taux),
        1,
        "env_action() triggers temp state if > limit";
}

{ # env_action() temp above but override

    my $event = $evt->env_action($api);
    $db->insert_env(99, 21);

    $api->aux_state($taux, 0);
    $api->aux_override($taux, 1);
    is $api->aux_override($taux), 1, "temp aux override on for testing";

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($taux),
        0,
        "env_action() doesn't change temp pin state if override";


    $api->aux_override($taux, 0);
    is $api->aux_override($taux), 0, "temp aux override reset to default";
}

{ # env_action (humidity above limit)

    my $event = $evt->env_action($api);

    $db->insert_env(79, 21);

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($haux),
        0,
        "env_action() doesn't trigger humidity state if > limit";
}

{ # env_action() humidity above limit

    my $event = $evt->env_action;
    $db->insert_env(99, 1);

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($haux),
        1,
        "env_action() triggers humidity state if < limit";
}

{ # env_action() humidity above but override

    my $event = $evt->env_action;
    $db->insert_env(99, 21);

    $api->aux_state($haux, 0);
    $api->aux_override($haux, 1);
    is $api->aux_override($haux), 1, "humidity aux override on for testing";

    $event->start;
    sleep 1;
    $event->stop;

    is
        $api->aux_state($haux),
        0,
        "env_action() doesn't change humidity pin state if override";

    $api->aux_override($haux, 0);
    is $api->aux_override($haux), 0, "humidity aux override reset to default";
}

unconfig();
db_remove();
done_testing();

