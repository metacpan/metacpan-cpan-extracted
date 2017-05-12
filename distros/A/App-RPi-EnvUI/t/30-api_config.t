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

{ # config_control()

    my @directives = qw(
        temp_limit humidity_limit temp_aux_on_time humidity_aux_on_time
        temp_aux humidity_aux light_aux
        );

    my @values = qw(
        80 20 1800 1800 aux1 aux2 aux3
        );

    is @directives, @values, "directives match number of values";

    my $i = 0;

    for (@directives){
        my $value = $api->_config_control($_);
        is $value, $values[$i], "control $_ has value $values[$i] by default";
        $i++;
    }
}

{ # config_core()

    my @directives = qw(
        event_fetch_timer event_action_timer event_display_timer
        sensor_pin testing time_zone
        );

    my @values = qw(
        15 3 4 -1 0 America/Edmonton
        );

    my $i = 0;

    for (@directives){
        my $value = $api->_config_core($_);
        is $value, $values[$i], "core $_ has value $values[$i] by default";
        $i++;
    }

    my $db_obj = $api->db();
    $api->{db} = undef;

    my $ok = eval { $api->_config_core; 1; };
    is $ok, undef, "_config_core() dies if the db object is undef";
    like $@, qr/DB object is not defined/, "...and spits the proper error";

    $api->db($db_obj);

    is
        $api->_config_core('time_zone'),
        'America/Edmonton',
        "...and when the db object is put back, all is well";

    # $want param missing

    $ok = eval { $api->_config_core; 1; };
    is $ok, undef, "_config_core requires a \$want param";
    like $@, qr/requires a \$want param/, "...and spits proper error msg";
}

{ # config_light()

    my @directives = qw(
        on_at on_hours on_time off_time toggle enable
        );

    my @values = qw(
        18:00 12 0 0 disabled 0
        );

    is @directives, @values, "config_light() test is set up equally";

    my $c = $api->_config_light;

    is ref $c, 'HASH', "_config_light() returns a hashref w/o params";
    is keys %$c, 6, "...and has proper count of keys";

    for my $k (keys %$c){
        my $ok = grep {$_ eq $k} @directives;
        is $ok, 1, "$k is a directive";
    }

    for my $d (@directives){
        is exists $c->{$d}, 1, "$d directive exists in conf";
    }

    my $i = 0;

    for (@directives){
        my $value = $api->_config_light($_);
        if ($_ eq 'on_in'){
            is
                $value,
                '00:00',
                "_config_light() on_in value is properly set from the default";
            $i++;
            next;
        }
        is $value, $values[$i], "light $_ has value $values[$i] by default";
        $i++;
    }

    $db->update('light', 'value', -1, 'id', 'on_hours');
    my $ok = eval { $api->_config_light; 1; };
    is $ok, undef, "_config_light() dies if on_hours < 0";
    like $@, qr/between 0 and 24/, "...and the error is sane";

    $db->update('light', 'value', 25, 'id', 'on_hours');
    $ok = eval { $api->_config_light; 1; };
    is $ok, undef, "_config_light() dies if on_hours > 24";
    like $@, qr/between 0 and 24/, "...and the error is sane";

    $db->update('light', 'value', 'aaa', 'id', 'on_hours');
    $ok = eval { $api->_config_light; 1; };
    is $ok, undef, "_config_light() dies if on_hours has letters";
    like $@, qr/between 0 and 24/, "...and the error is sane";

    $db->update('light', 'value', '22.5', 'id', 'on_hours');
    $ok = eval { $api->_config_light; 1; };
    is $ok, undef, "_config_light() dies if on_hours has a decimal";
    like $@, qr/between 0 and 24/, "...and the error is sane";


    $db->update('light', 'value', $c->{on_hours}, 'id', 'on_hours');
    is $api->_config_light('on_hours'), 12, "on_hours back to default ok";

}

unconfig();
db_remove();
done_testing();

