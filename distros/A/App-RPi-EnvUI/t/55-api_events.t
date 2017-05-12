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

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

my $m = Mock::Sub->new;

my $env_to_db_sub = $m->mock(
    'App::RPi::EnvUI::Event::env_to_db',
    return_value => bless {}, 'App::RPi::EnvUI::Event'
);

my $env_action_sub = $m->mock(
    'App::RPi::EnvUI::Event::env_action',
    return_value => bless {}, 'App::RPi::EnvUI::Event'
);

my $start_sub = $m->mock(
    'App::RPi::EnvUI::Event::start',
);

{ # events()

    $api->events;

    is $env_to_db_sub->called, 1, "events() calls Event::env_to_db()";
    is $env_action_sub->called, 1, "events() calls Event::env_action()";
    is $start_sub->called_count, 2, "events() calls start() ok times";


    is keys %{ $api->{events} }, 2, "\$api->{events} has correct key count";

    for ('env_to_db', 'env_action'){
        is exists $api->{events}{$_}, 1, "$_ is a key in events";
    }

    is
        ref $api->{events}{env_to_db},
        'App::RPi::EnvUI::Event',
        "env_to_db key is a correct object";

    is
        ref $api->{events}{env_action},
        'App::RPi::EnvUI::Event',
        "env_action key is a correct object";
}

unconfig();
db_remove();
done_testing();

