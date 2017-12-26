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

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

my $db = App::RPi::EnvUI::DB->new(testing => 1);

my $aux = $api->_config_control('light_aux');
my $init = \$App::RPi::EnvUI::API::light_initialized;
my $on_at = \$App::RPi::EnvUI::API::light_on_at;
my $on_hours = \$App::RPi::EnvUI::API::light_on_hours;
my $dt_now = \$App::RPi::EnvUI::API::dt_now_test;
my $dt_on = \$App::RPi::EnvUI::API::dt_light_on;
my $dt_off = \$App::RPi::EnvUI::API::dt_light_off;

{ # light should be off for the test

    is
        $api->aux_state($aux),
        0,
        "light aux is currently in state off";
}

{ # on_hours == 0 and == 24

    # 24

    $$init = 0;

    $db->update('light', 'value', 24, 'id', 'on_hours');
    $api->action_light;
    is $api->aux_state($aux), 1, "when on_hours is 24, light goes on";
    is $App::RPi::EnvUI::API::pm_sub->called, 1, "pin_mode() called";
    is $App::RPi::EnvUI::API::wp_sub->called, 1, "write_pin() called";

    $App::RPi::EnvUI::API::pm_sub->reset;
    $App::RPi::EnvUI::API::wp_sub->reset;

    is $App::RPi::EnvUI::API::pm_sub->called, 0, "pin_mode() reset";
    is $App::RPi::EnvUI::API::wp_sub->called, 0, "write_pin() reset";

    # 24 state on

    $$init = 0;

    $db->update('light', 'value', 24, 'id', 'on_hours');
    $api->action_light;
    is $api->aux_state($aux), 1, "when on_hours is 24, light goes on";
    is $App::RPi::EnvUI::API::pm_sub->called, 0, "pin_mode() not called if 24 hrs and state";
    is $App::RPi::EnvUI::API::wp_sub->called, 0, "write_pin() not called if 24 hrs and state";

    $App::RPi::EnvUI::API::pm_sub->reset;
    $App::RPi::EnvUI::API::wp_sub->reset;

    is $App::RPi::EnvUI::API::pm_sub->called, 0, "pin_mode() reset";
    is $App::RPi::EnvUI::API::wp_sub->called, 0, "write_pin() reset";

    $$init = 0;

    $db->update('light', 'value', 0, 'id', 'on_hours');
    $api->action_light;
    is $api->aux_state($aux), 0, "when on_hours is 0, light goes off if on";
    is $App::RPi::EnvUI::API::pm_sub->called, 1, "pin_mode() *is* called";
    is $App::RPi::EnvUI::API::wp_sub->called, 1, "write_pin() *is* called";

    $App::RPi::EnvUI::API::pm_sub->reset;
    $App::RPi::EnvUI::API::wp_sub->reset;

    is $App::RPi::EnvUI::API::pm_sub->called, 0, "pin_mode() reset";
    is $App::RPi::EnvUI::API::wp_sub->called, 0, "write_pin() reset";

    $api->aux_state($aux, 0);

    $$init = 0;

    $api->action_light;
    is $api->aux_state($aux), 0, "when on_hours is 0, light stays off";
    is $App::RPi::EnvUI::API::pm_sub->called, 0, "pin_mode() *not* called";
    is $App::RPi::EnvUI::API::wp_sub->called, 0, "write_pin() *not* called";

    $db->update('light', 'value', 12, 'id', 'on_hours');
    is $api->_config_light('on_hours'), 12, "on_hours reset back to default ok";
}

{ # on/off same day to see if the datetime is set correctly

    $api->aux_state($aux, 0);
    $$init = 0;
    $api->action_light;

    $$on_at = '01:00';
    $$on_hours = 12;

    $$dt_now = DateTime->now->set_time_zone('local');
    $$dt_now->set_hour(1);
    $$dt_now->set_minute(0);
    $$dt_now->set_second(0);

    $$dt_on = $$dt_now->clone;
    $$dt_now->add(minutes => 3);

    $$dt_off = $$dt_on->clone;
    $$dt_off->add(hours => $$on_hours);

    $api->action_light;

    is $api->aux_state($aux), 1, "lamp is on";

    $$dt_now->set_hour(13);
    $$dt_now->set_minute(2);

    $api->action_light;

    is $api->aux_state($aux), 0, "lamp is off";

    # tomorrow on

    $$dt_now = DateTime->now->set_time_zone('local');
    $$dt_now->set_hour(1);
    $$dt_now->set_minute(0);
    $$dt_now->set_second(0);
    $$dt_now->add(hours => 24);
    $$dt_now->add(minutes => 3);

    $api->action_light;

    is $api->aux_state($aux), 1, "lamp is on when on/off time is in the same 24 hrs";
    # print "now: $$dt_now | on: $$dt_on | off: $$dt_off\n";

    # tomorrow off

    $$dt_now->set_hour(13);

    $api->action_light;

    is $api->aux_state($aux), 0, "lamp is off when on/off time is in the same 24 hrs";
    # print "now: $$dt_now | on: $$dt_on | off: $$dt_off\n";
}

unconfig();
db_remove();
done_testing();

