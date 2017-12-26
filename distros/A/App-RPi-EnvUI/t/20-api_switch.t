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
use Data::Dumper;
use Test::More;

#FIXME: add tests to test overrides for hum and temp

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

my $db = App::RPi::EnvUI::DB->new(testing => 1);

my $read_pin_sub = $App::RPi::EnvUI::API::rp_sub;

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # read_sensor()
    my @env = $api->read_sensor;

    is @env, 2, "mocked read_sensor() returns proper count of values";
    is $env[0], 80, "first elem of return ok (temp)";
    is $env[1], 20, "second elem of return ok (humidity)";
}

{ # switch()

    for (1..8){
        my $id = "aux$_";
        $api->aux_pin($id, 0);
        $read_pin_sub->return_value(0);

        my $ret = $api->switch($id);

        is $api->aux_pin($id), 0, "aux $id pin set to 0";

        is $App::RPi::EnvUI::API::wp_sub->called, 0, "switch(): wp not called if pin isn't -1 and no state change";
        is $ret, undef, "switch(): if pin isn't -1, we don't call write_pin() if no state change, $id";

        $api->aux_pin($id, -1);

        is $api->aux_pin($id), -1, "successfully reset $id pin to -1";
    }

    $App::RPi::EnvUI::API::wp_sub->reset;

    for (1..8){
        my $id = "aux$_";
        my $ret = $api->switch($id);

        is
            $App::RPi::EnvUI::API::wp_sub->called,
            0,
            "switch(): write_pin() not called if pin state is -1: $id";
        is $ret, '', "switch(): if pin is -1, we don't call write_pin(), $id";
    }

    # state is on, turning off

    for (1..8){
        my $id = "aux$_";

        is $api->aux_pin($id, 0), 0, "$id pin set to 0 for test";
        is $api->aux_state($id, 1), 1, "$id state set to 1 for test";

        $read_pin_sub->return_value(1);
        $api->switch($id);

        is $api->aux_state($id), 1, "with state=1, switch() turns it on";

        $read_pin_sub->return_value(0);
        is $api->aux_pin($id, -1), -1, "$id pin set to -1";
        is $api->aux_state($id, 0), 0, "$id state set to 0";
    }
}

unconfig();
db_remove();
done_testing();
