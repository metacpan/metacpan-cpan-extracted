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

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # aux()

    for (1..8){
        my $name = "aux$_";
        my $aux = $api->aux($name);

        is ref $aux, 'HASH', "aux() returns $name as an href";
        is keys %$aux, 6, "$name has proper key count";

        for (qw(id desc pin state override on_time)){
            is exists $aux->{$_}, 1, "$name has directive $_";
        }
    }

    my $aux = $api->aux('aux9');
    is $aux, undef, "only 8 auxs available";

    $aux = $api->aux('aux0');
    is $aux, undef, "aux0 doesn't exist";
}
{ # auxs()

    my $db_auxs = $db->auxs;
    my $api_auxs = $api->auxs;

    is keys %$api_auxs, 8, "eight auxs() total from auxs()";

    for my $db_k (keys %$db_auxs) {
        for (keys %{ $db_auxs->{$db_k} }) {
            is $db_auxs->{$db_k}{$_}, $api_auxs->{$db_k}{$_},
                "db and api return the same auxs() ($db_k => $_)";
        }
    }
}

{ # aux_id()

    # takes aux hash

    for (1..8){
        my $name = "aux$_";
        my $aux = $api->aux($name);
        my $id = $api->aux_id($aux);

        is $id, $name, "aux_id() returns proper ID for $name";


    }
}

{ # aux_state()

    for (1..8){
        my $aux_id = "aux$_";
        my $state = $api->aux_state($aux_id);

        is $state,
            0,
            "aux_state() returns correct default state value for $aux_id";

        $state = $api->aux_state($aux_id, 1);

        is $state, 1, "aux_state() correctly sets state for $aux_id";

        $state = $api->aux_state($aux_id, 0);

        is $state, 0, "aux_state() can re-set state for $aux_id";
    }

    my $ok = eval { $api->aux_state; 1; };

    is $ok, undef, "aux_state() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

{ #aux_time()

    my $time = time();

    for (1..8){
        my $id = "aux$_";

        is $api->aux_time($id), 0, "aux_time() has correct default for $id";

        $api->aux_time($id, $time);
    }

    sleep 1;

    for (1..8){
        my $id = "aux$_";
        my $elapsed = time() - $api->aux_time($id);
        ok $elapsed > 0, "aux_time() sets time correctly for $id";
        is $api->aux_time($id, 0), 0, "and resets it back again ok";
    }

    my $ok = eval { $api->aux_time(); 1; };

    is $ok, undef, "aux_time() dies if no aux id is sent in";
}

{ # aux_override()

    for (1..8){
        my $aux_id = "aux$_";
        my $o = $api->aux_override($aux_id);

        is
            $o,
            0,
            "aux_override() returns correct default override value for $aux_id";

        $o = $api->aux_override($aux_id, 1);

        is $o, 1, "aux_override() correctly sets override for $aux_id";

        $o = $api->aux_override($aux_id, 0);

        is $o, 0, "aux_override() can re-set override for $aux_id";
    }

    my $ok = eval { $api->aux_override; 1; };

    is $ok, undef, "aux_override() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

{ # aux_pin()

    for (1..8){
        my $aux_id = "aux$_";
        my $p = $api->aux_pin($aux_id);

        is $p, -1, "aux_pin() returns correct default pin value for $aux_id";

        $p = $api->aux_pin($aux_id, 1);

        is $p, 1, "aux_pin() correctly sets pin for $aux_id";

        $p = $api->aux_pin($aux_id, -1);

        is $p, -1, "aux_pin() can re-set pin for $aux_id";
    }

    my $ok = eval { $api->aux_pin; 1; };

    is $ok, undef, "aux_pin() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

unconfig();
#db_remove();
done_testing();

