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
use Mock::Sub no_warnings => 1;
use Test::More;

#FIXME: add tests to test overrides for hum and temp

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

my $db = App::RPi::EnvUI::DB->new(testing => 1);

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # env()

    my $ret = $api->env(99, 1);

    is $ret->{temp}, 99, "env() w/ params sets temp properly";
    is $ret->{humidity}, 1, "env() w/params sets humidity properly";

    $ret = $api->env;

    is $ret->{temp}, 99, "env() w/o params returns temp ok";
    is $ret->{humidity}, 1, "env() w/o params returns humidity ok";

    $api->env(50, 50);
    $ret = $api->env;

    is
        $ret->{temp},
        50,
        "env() does the right thing after another update (temp)";
    is
        $ret->{humidity},
        50,
        "env() does the right thing after another update (hum)";

    my $ok = eval { $api->env(50), 1; };
    is $ok, undef, "env() dies if neither 0 or exactly 2 args sent in";
    like $@, qr/requires either/, "...and the error message is correct";

    for (qw(1.1 99h hello !!)){

        $ok = eval { $api->env($_, 99); 1; };
        is $ok, undef, "env() dies if temp arg isn't a number\n";
        like $@, qr/must be an integer/, "...and for temp, error is ok";

        $ok = eval { $api->env(99, $_); 1; };
        is $ok, undef, "env() dies if humidity arg isn't a number\n";
        like $@, qr/must be an integer/, "...and for humidity, error is ok";
    }
}

{ # no return from env()

    my $m = Mock::Sub->new;
    my $db_sub = $m->mock(
        'App::RPi::EnvUI::DB::env',
        return_value => undef
    );

    my $ret = $api->env;
    unmock $db_sub;

    is ref $ret, 'HASH', "env() returns a hashref with the db() mocked";

    is keys %$ret, 3, "...and has proper key count";
    is $ret->{temp}, -1, "if the stats table is empty, temp returned is -1";
    is $ret->{humidity}, -1, "if the stats table is empty, hum returned is -1";
}

{ # temp(), humidity()

    for (1..50){
        $api->env($_, $_);
        is $api->temp, $_, "env() update to $_, temp() returns ok";
        is $api->humidity, $_, "env() update to $_, humidity() returns ok";
    }

}

unconfig();
db_remove();
done_testing();

