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
use Crypt::SaltedHash;
use Data::Dumper;
use Mock::Sub no_warnings => 1;
use Test::More;

#FIXME: add tests to test overrides for hum and temp

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # read_sensor()

    my @env = $api->read_sensor;

    is @env, 2, "mocked read_sensor() returns proper count of values";
    is $env[0], 80, "first elem of return ok (temp)";
    is $env[1], 20, "second elem of return ok (humidity)";

    # sensor not defined

    my $sensor = $api->{sensor};
    $api->{sensor} = undef;

    my $ok = eval { $api->read_sensor; 1; };

    is $ok, undef, "without a sensor object, we die";
    like $@, qr/is not defined/, "...and coughs the proper error message";

    $api->{sensor} = $sensor;

    $ok = eval { $api->read_sensor; 1; };

    is $ok, 1, "re-assigned the sensor object ok";

}

{ # bool()

    my $ok = eval { $api->_bool; 1; };
    is $ok, undef, "bool() dies if a param isn't sent in";
    like $@, qr/'true' or 'false'/, "...and the error is correct";

    is $api->_bool('true'), 1, "bool('true') ok";
    is $api->_bool('false'), 0, "bool('false') ok";

}

{ # _reset()

    for (1..8){
        my $id = "aux$_";
        $api->aux_time($id, 99);
        my $time = $api->aux_time($id);
        ok $time > 0, "_reset() test setup ok for $id";
    }

    $api->_reset;

    for (1..8){
        my $id = "aux$_";
        my $time = $api->aux_time($id);
        is $time, 0, "_reset() sets $id back to 0 on_time";
    }
}

{ # _prod_mode()

    my $m = Mock::Sub->new;

    my $dht_new_sub = $m->mock(
        'RPi::DHT11::new',
        return_value => bless {}, 'RPi::DHT11'
    );

    $api->_prod_mode;

    is $dht_new_sub->called, 1, "RPi::DHT11->new is called by _prod_mode()";
    is ref $api->sensor, 'RPi::DHT11', "_prod_mode() generates a sensor";
}

{ # config file not found

    unconfig();

    is -e 't/envui.json', undef, "for testing, config file has been removed ok";

    my $ok = eval { App::RPi::EnvUI::API->new(testing => 1); 1; };

    is $ok, undef, "we die if a config file is not found";
    like $@, qr/config file .*? not found/, "...the error message is sane";

    config();
}

{ # passwd()

    my $pw = 'admin';
    my $enc = $api->passwd($pw);

    my $csh = Crypt::SaltedHash->new(algorithm => 'SHA1');
    is $csh->validate($enc, $pw), 1, "passwd() returns an ok crypted pw";

    my $ok = eval { $api->passwd; 1; };
    is $ok, undef, "passwd() requires a password sent in";
    like $@, qr/plain text password/, "...and error is ok";
}

{ # auth()

    my $un = 'admin';
    my $pw = 'admin';

    my $ok = $api->auth($un, $pw);

    is $ok, 1, "auth() ok with successful login";

    $ok = $api->auth($un, 'blah');

    is $ok, '', "auth() fails with invalid pw";

    $ok = $api->auth('nouser', 'pass');

    is $ok, '', "auth() fails with invalid username";

    $ok = eval { $api->auth; 1; };
    is $ok, undef, "auth() dies if username not sent in";
    like $@, qr/requires a username/, "...and the error is ok";

    $ok = eval { $api->auth('admin'); 1; };
    is $ok, undef, "auth() dies if password not sent in";
    like $@, qr/requires a password/, "...and the error is ok";
}

{ # user

    my $ok = eval { $api->user; 1; };
    is $ok, undef, "user() dies if a username isn't sent in";
    like $@, qr/requires a username/, "...and the error is sane";

    my $u = $api->user('admin');
    is ref $u, 'HASH', "user() returns a hash reference";

    is $u->{user}, 'admin', "...and has a 'user' field";
    like $u->{pass}, qr/{SSHA/, "...and has a 'pass' field";

    $u = $api->user('blah');
    is $u->{user}, 'blah', "user() returns properly even if user doesn't exist";
    is $u->{pass}, '', "...and the 'pass' field is empty";
}
unconfig();
db_remove();
done_testing();

