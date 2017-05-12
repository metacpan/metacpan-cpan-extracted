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

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # action_humidity()

    my $id = $api->_config_control('humidity_aux');
    my $limit = $api->_config_control('humidity_limit');
    my $override = $api->aux_override($id);
    my $min_run = $api->_config_control('humidity_aux_on_time');
    my $aux_time = $api->aux_time($id);

    # aux should be off

    is $id, 'aux2', "test hum aux id ok";
    is $limit, 20, "test hum limit ok";
    is $override, 0, "test hum override ok";
    is $min_run, 1800, "test hum min_run before ok";
    is $aux_time, 0, "test hum aux_time ok";
    is $api->aux_state($id), 0, "humidity aux is off";

    # on w/o override

    $api->action_humidity($id, 19);

    sleep 1;

    #print "*** " . $api->aux_time($id) . "\n";

    ok $api->aux_time($id) > 0, "hum on aux_time ok";
    is $api->aux_state($id), 1, "hum aux is on w/o override";

    # hum > limit, but min_time not expired to turn back off

    $api->aux_time($id, time() - 1680); # 28 mins

    $api->action_humidity($id, 99);
    ok
        $api->aux_time($id) > 0,
        "hum on aux_time ok when hum < limit but min_time not reached";
    is
        $api->aux_state($id),
        1,
        "hum aux is on w/o override when hum < limit but min_time not reached";

    # hum equal to limit exactly, min_time expired

    $api->aux_time($id, time() - 1850); # 30 mins, 50 seconds

    $api->action_humidity($id, 20);
    is $api->aux_time($id),  0, "hum on aux_time ok when hum==limit";
    is $api->aux_state($id), 0, "hum aux is on w/o override when hum==limit";

    $api->action_humidity($id, 99);
    is
        $api->aux_time($id),
        0,
        "hum on aux_time ok when hum > limit and min_time expired";
    is
        $api->aux_state($id),
        0,
        "hum aux is on w/o override when hum > limit and min_time expired";

    # override is on

    $api->aux_override($id, 1);
    is $api->aux_override($id), 1, "humidity override on for test";
    $api->action_humidity($id, 1);
    is $api->aux_state($id), 0, "humidity low, override on, pin stays off";
    is $api->aux_time($id), 0, "humidity low, override on, on time not set";

    $api->aux_override($id, 0);
    is $api->aux_override($id), 0, "humidity reset to off";

}

{ # action_temp()

    my $id = $api->_config_control('temp_aux');
    my $limit = $api->_config_control('temp_limit');
    my $override = $api->aux_override($id);
    my $min_run = $api->_config_control('temp_aux_on_time');
    my $aux_time = $api->aux_time($id);

    # aux should be off

    is $id, 'aux1', "test temp aux id ok";
    is $limit, 80, "test temp limit ok";
    is $override, 0, "test temp override ok";
    is $min_run, 1800, "test temp min_run before ok";
    is $aux_time, 0, "test temp aux_time ok";
    is $api->aux_state($id), 0, "temp aux is off";

    # on w/o override

    $api->action_temp($id, 81);

    sleep 1;

    ok $api->aux_time($id) > 0, "temp on aux_time ok";
    is $api->aux_state($id), 1, "temp aux is on w/o override";

    # temp > limit, but min_time not expired to turn back off

    $api->aux_time($id, time() - 1680); # 28 mins

    $api->action_temp($id, 1);
    ok
        $api->aux_time($id) > 0,
        "temp on aux_time ok when temp < limit but min_time not reached";
    is
        $api->aux_state($id),
        1,
        "temp aux is on w/o override when temp<limit but min_time not reached";

    # temp equal to limit exactly, min_time expired

    $api->aux_time($id, time() - 1805);

    $api->action_temp($id, 80);
    is $api->aux_time($id),  0, "temp on aux_time ok when temp==limit";
    is $api->aux_state($id), 0, "temp aux is on w/o override when temp==limit";

    $api->action_temp($id, 1);
    is
        $api->aux_time($id),
        0,
        "temp on aux_time ok when temp > limit and min_time expired";
    is
        $api->aux_state($id),
        0,
        "temp aux is on w/o override when temp > limit and min_time expired";

     # override is on

    $api->aux_override($id, 1);
    is $api->aux_override($id), 1, "temp override on for test";

    $api->action_temp($id, 99);

    is $api->aux_state($id), 0, "temp low, override on, pin stays off";
    is $api->aux_time($id), 0, "temp low, override on, on time not set";

    $api->aux_override($id, 0);
    is $api->aux_override($id), 0, "temp reset to off";
}

unconfig();
db_remove();
done_testing();

