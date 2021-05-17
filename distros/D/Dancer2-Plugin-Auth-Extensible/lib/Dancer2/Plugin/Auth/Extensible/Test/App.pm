package Dancer2::Plugin::Auth::Extensible::Test::App;

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Test::App - Dancer2 app for testing providers

=cut

our $VERSION = '0.710';

use strict;
use warnings;
use Test::More;
use Test::Deep qw(bag cmp_deeply);
use Test::Fatal;
use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::Auth::Extensible;
use Scalar::Util qw(blessed);
use YAML ();

set session => 'simple';
set logger => 'capture';
set log => 'debug';
set show_errors => 1;

# nasty shared global makes it easy to pass data between app and test script
our $data = {};

config->{plugins}->{"Auth::Extensible"}->{password_reset_send_email} =
  __PACKAGE__ . "::email_send";
config->{plugins}->{"Auth::Extensible"}->{welcome_send} =
  __PACKAGE__ . "::email_send";

sub email_send {
    my ( $plugin, %args ) = @_;
    $data = { %args, called => 1 };
}

# we need the plugin object and a provider for provider tests
my $plugin = app->with_plugin('Auth::Extensible');
my $provider = $plugin->auth_provider('config1');

my @provider_can = ();

push @provider_can, 'record_lastlogin' if $plugin->config->{record_lastlogin};

config->{plugins}->{"Auth::Extensible"}->{reset_password_handler} = 1
  if $provider->can('get_user_by_code');

#
# IMPORTANT NOTE
#
# We use "isnt exception {...}, undef, ..." a lot which is REALLY BAD
# practice. This should only ever be done in provider tests since we cannot
# be sure what exception message a provider returns and we do NOT mandate
# specific messages so we can only test if something died.
#
# When writing new provider tests please always test first with a "like /qr/"
# instead and then once the tests are all working against one provider switch
# them to the bad "isnt undef" style so they are portable.
#

subtest 'Provider authenticate_user tests' => sub {
    my $ret;
    push @provider_can, 'authenticate_user';

    isnt exception { $ret = $provider->authenticate_user(); },
      undef,
      "authenticate_user with no args dies.";

    isnt exception { $ret = $provider->authenticate_user(''); },
      undef,
      "authenticate_user with empty username and no password dies.";

    isnt exception { $ret = $provider->authenticate_user(undef, ''); },
      undef,
      "authenticate_user with undef username and empty password dies.";

    is exception { $ret = $provider->authenticate_user('', ''); },
      undef,
      "authenticate_user with empty username and empty password lives.";
    ok !$ret, "... and returns a false value.";

    is exception { $ret = $provider->authenticate_user('unknown', 'beer'); },
      undef,
      "authenticate_user with unknown user lives.";
    ok !$ret, "... and returns a false value.";

    is exception { $ret = $provider->authenticate_user('dave', 'notcorrect'); },
      undef,
      "authenticate_user with known user and bad password lives.";
    ok !$ret, "... and returns a false value.";

    is exception { $ret = $provider->authenticate_user('dave', 'beer'); },
      undef,
      "authenticate_user with known user and good password.";
    ok $ret, "... and returns a true value.";
};

SKIP: {
    skip "Provider has no get_user_details method", 1
      unless $provider->can('get_user_details');

    subtest 'Provider get_user_details tests' => sub {
        my $ret;

        push @provider_can, 'get_user_details';

        isnt exception { $ret = $provider->get_user_details(); },
          undef,
          "get_user_details with no args dies.";

        is exception { $ret = $provider->get_user_details(''); },
          undef,
          "get_user_details with empty username lives.";
        ok !$ret, "... and returns a false value.";

        is exception { $ret = $provider->get_user_details('unknown'); },
          undef,
          "get_user_details with unknown user lives.";
        ok !$ret, "... and returns a false value.";

        is exception { $ret = $provider->get_user_details('dave'); },
          undef,
          "get_user_details with known user lives.";
        ok $ret, "... and returns a true value";
        ok blessed($ret) || ref($ret) eq 'HASH',
          "... which is either an object or a hash reference"
          or diag explain $ret;
        is blessed($ret) ? $ret->name : $ret->{name}, 'David Precious',
          "... and user's name is David Precious.";
    };
}

SKIP: {
    skip "Provider has no get_user_roles method", 1
      unless $provider->can('get_user_roles');

    subtest 'Provider get_user_roles tests' => sub {
        my $ret;

        push @provider_can, 'get_user_roles';

        isnt exception { $ret = $provider->get_user_roles(); },
          undef,
          "get_user_roles with no args dies.";

        is exception { $ret = $provider->get_user_roles(''); }, undef,
          "get_user_roles with empty username lives";
        ok !$ret, "... and returns false value.";

        is exception { $ret = $provider->get_user_roles('unknown'); }, undef,
          "get_user_roles with unknown user lives";
        ok !$ret, "... and returns false value.";

        is exception { $ret = $provider->get_user_roles('dave'); }, undef,
          "get_user_roles with known user \"dave\" lives";
        ok $ret, "... and returns true value";
        is ref($ret), 'ARRAY', "... which is an array reference";
        cmp_deeply $ret, bag( "BeerDrinker", "Motorcyclist" ),
          "... and dave is a BeerDrinker and Motorcyclist.";
    };
}

SKIP: {
    skip "Provider has no create_user method", 1
      unless $provider->can('create_user');

    subtest 'Provider create_user tests' => sub {
        my $ret;

        push @provider_can, 'create_user';

        isnt exception { $ret = $provider->create_user(); },
          undef,
          "create_user with no args dies.";

        isnt exception { $ret = $provider->create_user(username => ''); },
          undef,
          "create_user with empty username dies.";

        isnt exception { $ret = $provider->create_user(username => 'dave'); },
          undef,
          "create_user with existing username dies.";

        is exception {
            $ret = $provider->get_user_details('provider_create_user');
        },
          undef,
          "get_user_details \"provider_create_user\" lives";
        ok !defined $ret, "... and does not return a user.";

        is exception {
            $ret = $provider->create_user(
                username => 'provider_create_user',
                name     => 'Create User'
            );
        },
          undef,
          "create_user \"provider_create_user\" lives";

        ok defined $ret, "... and returns a user";
        is blessed($ret) ? $ret->name : $ret->{name}, "Create User",
          "... and user's name is correct.";

        is exception {
            $ret = $provider->get_user_details('provider_create_user');
        },
          undef,
          "get_user_details \"provider_create_user\" lives";
        ok defined $ret, "... and now *does* return a user.";
        is blessed($ret) ? $ret->name : $ret->{name}, "Create User",
          "... and user's name is correct.";
    };
}

SKIP: {
    skip "Provider has no set_user_details method", 1
      unless $provider->can('set_user_details');

    subtest 'Provider set_user_details tests' => sub {
        my $ret;

        push @provider_can, 'set_user_details';

        isnt exception { $ret = $provider->set_user_details(); },
          undef,
          "set_user_details with no args dies.";

        isnt exception { $ret = $provider->set_user_details(''); },
          undef,
          "set_user_details with empty username dies.";

        is exception {
            $ret = $provider->create_user(
                username => 'provider_set_user_details',
                name     => 'Initial Name'
            );
        },
          undef,
          "Create a user for testing lives";

        is exception {
            $ret = $provider->get_user_details('provider_set_user_details')
        },
          undef,
          "... and get_user_details on new user lives";

        is blessed($ret) ? $ret->name : $ret->{name}, 'Initial Name',
          "... and user has expected name.";

        is exception {
            $ret = $provider->set_user_details( 'provider_set_user_details',
                name => 'New Name', );
        },
          undef,
          "Using set_user_details to change user's name lives";

        is blessed($ret) ? $ret->name : $ret->{name}, 'New Name',
          "... and returned user has expected name.";

        is exception {
            $ret = $provider->get_user_details('provider_set_user_details')
        },
          undef,
          "... and get_user_details on new user lives";

        is blessed($ret) ? $ret->name : $ret->{name}, 'New Name',
          "... and returned user has expected name.";
    };
}

SKIP: {
    skip "Provider has no get_user_by_code method", 1
      unless $provider->can('get_user_by_code');

    subtest 'Provider get_user_by_code tests' => sub {
        my $ret;

        push @provider_can, 'get_user_by_code';

        isnt exception { $ret = $provider->get_user_by_code(); },
          undef,
          "get_user_by_code with no args dies.";

        isnt exception { $ret = $provider->get_user_by_code(''); },
          undef,
          "get_user_by_code with empty code dies.";

        is exception { $ret = $provider->get_user_by_code('nosuchcode'); },
          undef,
          "get_user_by_code with non-existant code lives";
        ok !defined $ret, "... and returns undef.";

        is exception {
            $ret = $provider->create_user(
                username      => 'provider_get_user_by_code',
                pw_reset_code => '01234567890get_user_by_code',
            );
        },
          undef,
          "Create a user for testing lives";

        is exception {
            $ret = $provider->get_user_by_code('01234567890get_user_by_code');
        },
          undef,
          "get_user_by_code with non-existant code lives";
        ok defined $ret, "... and returns something true";

        is $ret, 'provider_get_user_by_code',
          "... and returned username is correct.";
    };
}

SKIP: {
    skip "Provider has no set_user_password method", 1
      unless $provider->can('set_user_password');

    subtest 'Provider set_user_password tests' => sub {
        my $ret;

        push @provider_can, 'set_user_password';

        isnt exception { $ret = $provider->set_user_password(); },
          undef,
          "set_user_password with no args dies.";

        isnt exception { $ret = $provider->set_user_password(''); },
          undef,
          "set_user_password with username but undef password dies";

        isnt exception { $ret = $provider->set_user_password( undef, '' ); },
          undef,
          "set_user_password with password but undef username dies";

        is exception {
            $ret =
              $provider->create_user( username => 'provider_set_user_password' )
        },
          undef,
          "Create a user for testing lives";

        is exception {
            $ret = $provider->set_user_password( 'provider_set_user_password',
                'aNicePassword' )
        },
        undef, "set_user_password for our new user lives";

        is exception {
            $ret = $provider->authenticate_user( 'provider_set_user_password',
                'aNicePassword' )
        },
        undef, "... and authenticate_user with correct password lives";
        ok $ret, "... and authenticate_user passes (returns true)";

        is exception {
            $ret = $provider->authenticate_user( 'provider_set_user_password',
                'badpwd' )
        },
        undef, "... and whilst authenticate_user with bad password lives";
        ok !$ret, "... it returns false.";
    };
}

SKIP: {
    skip "Provider has no password_expired method", 1
      unless $provider->can('password_expired');

    subtest 'Provider password_expired tests' => sub {
        my $ret;

        push @provider_can, 'password_expired';

        isnt exception { $ret = $provider->password_expired(); },
          undef,
          "password_expired with no args dies.";

        is exception {
            $ret =
              $provider->create_user( username => 'provider_password_expired' )
        },
          undef,
          "Create a user for testing lives";

        is exception {
            $ret = $provider->password_expired($ret)
        },
          undef,
          "... and password_expired for user lives";

        ok $ret, "... and password is expired since it has never been set.";

        is exception {
            $ret = $provider->set_user_password( 'provider_password_expired',
                'password' )
        },
          undef,
          "Setting password for user lives";

        is exception {
            $ret = $provider->password_expired($ret)
        },
          undef,
          "... and password_expired for user lives";

        ok !$ret, "... and password is now *not* expired.";

        is exception {
            $ret = $provider->set_user_details( 'provider_password_expired',
                pw_changed => DateTime->now->subtract( weeks => 1 ) )
        },
          undef,
          "Set pw_changed to one week ago lives and so now password is expired";

        is exception {
            $ret = $provider->password_expired($ret)
        },
          undef,
          "... and password_expired for user lives";

        ok $ret, "... and password *is* now expired since expiry is 2 days.";

    };
}

subtest "Plugin coverage testing" => sub {
    # DO NOT use this for testing things that can be tested elsewhere since
    # these tests are purely to catch the code paths that we can't get to
    # any other way.

    like exception { $plugin->realm() }, qr/realm name not provided/,
      "Calling realm method with no args dies";

    like exception { $plugin->realm('') }, qr/realm name not provided/,
      "... and calling it with single empty arg dies.";

    foreach my $username ( undef, +{}, '', 'username' ) {
        foreach my $password ( undef, +{}, '', 'password' ) {
            my $ret = $plugin->authenticate_user( $username, $password );
            is $ret, 0,
                "Checking authenticate_user with username/password: "
              . mydumper($username) . "/"
              . mydumper($password);
        }
    }
};

sub mydumper {
    my $val = shift;
    !defined $val && return '(undef)';
    ref($val) ne '' && return ref($val);
    $val eq '' && return '(empty)';
    $val;
};

# hooks

hook before_authenticate_user => sub {
    debug "before_authenticate_user", to_json( shift, { canonical => 1 } );
};
hook after_authenticate_user => sub {
    debug "after_authenticate_user", to_json( shift, { canonical => 1 } );
};
hook before_create_user => sub {
    debug "before_create_user", to_json( shift, { canonical => 1 } );
};
hook after_create_user => sub {
    my ( $username, $user, $errors ) = @_;
    my $ret = $user ? 1 : 0;
    debug "after_create_user,$username,$ret,",scalar @$errors ? 'yes' : 'no';
};

# and finally the routes for the main plugin tests

get '/provider_can' => sub {
    send_as YAML => \@provider_can;
};

get '/' => sub {
    "Index always accessible";
};

post '/authenticate_user' => sub {
    my $params = body_parameters->as_hashref;
    my @ret = authenticate_user( $params->{username}, $params->{password},
        $params->{realm} );
    send_as YAML => \@ret;
};

post '/create_user' => sub {
    my $params = body_parameters->as_hashref;
    my $user   = create_user %$params;
    return $user ? 1 : 0;
};

post '/get_user_details' => sub {
    my $params = body_parameters->as_hashref;
    my $user = get_user_details $params->{username}, $params->{realm};
    if ( blessed($user) ) {
        if ( $user->isa('DBIx::Class::Row')) {
            $user = +{ $user->get_columns };
        }
        else {
            # assume some kind of hash-backed object
            $user = \%$user;
        }
    }
    return $user ? send_as YAML => $user : 0;
};

get '/session_data' => sub {
    my $session = session->data;
    send_as YAML => $session;
};

get '/logged_in_user_lastlogin' => sub {
    my $dt = logged_in_user_lastlogin;
    if ( ref($dt) eq 'DateTime' ) {
        return $dt->ymd;
    }
    return 'not set';
};

get '/logged_in_user' => sub {
    my $user = logged_in_user;
    if ( blessed($user) ) {
        if ( $user->isa('DBIx::Class::Row')) {
            $user = +{ $user->get_columns };
        }
        else {
            # assume some kind of hash-backed object
            $user = \%$user;
        }
    }
    send_as YAML => $user ? $user : 'none';
};

get '/logged_in_user_twice' => sub {
    logged_in_user; # retrieve
    my $user = logged_in_user; # should now be stashed in var
    if ( blessed($user) ) {
        if ( $user->isa('DBIx::Class::Row')) {
            $user = +{ $user->get_columns };
        }
        else {
            # assume some kind of hash-backed object
            $user = \%$user;
        }
    }
    send_as YAML => $user ? $user : 'none';
};

get '/loggedin' => require_login sub  {
    "You are logged in";
};

get qr{/regex/(.+)} => require_login sub {
    return "Matched";
};

get '/require_login_no_sub' => require_login;

get '/require_login_not_coderef' => require_login { a => 1 };

get '/roles' => require_login sub {
    my $roles = user_roles() || [];
    return join ',', sort @$roles;
};

get '/roles/:user' => require_login sub {
    my $user = param 'user';
    return join ',', sort @{ user_roles($user) };
};

get '/roles/:user/:realm' => require_login sub {
    my $user = param 'user';
    my $realm = param 'realm';
    return join ',', sort @{ user_roles($user, $realm) };
};

get '/user_roles' => sub {
    return join ',', sort @{ user_roles() };
};

get '/beer' => require_role BeerDrinker => sub {
    "You can have a beer";
};

get '/piss' => require_role BearGrylls => sub {
    "You can drink piss";
};

get '/piss/regex' => require_role qr/beer/i => sub {
    "You can drink piss now";
};

get '/anyrole' => require_any_role ['Foo','BeerDrinker'] => sub {
    "Matching one of multiple roles works";
};

get '/allroles' => require_all_roles ['BeerDrinker', 'Motorcyclist'] => sub {
    "Matching multiple required roles works";
};

get '/not_allroles' => require_all_roles ['BeerDrinker', 'BadRole'] => sub {
    "Matching multiple required roles should fail";
};

get '/does_dave_drink_beer' => sub {
    return user_has_role('dave', 'BeerDrinker');
};

get '/does_dave_drink_cider' => sub {
    return user_has_role('dave', 'CiderDrinker');
};

get '/does_undef_drink_beer' => sub {
    return user_has_role(undef, 'BeerDrinker');
};

get '/user_password' => sub {
    return user_password params('query');
};
post '/user_password' => sub {
    return user_password %{ body_parameters->as_hashref };
};

get '/update_current_user' => sub {
    my $user = update_current_user name => "I love cider";
    if ( blessed($user) ) {
        if ( $user->isa('DBIx::Class::Row')) {
            $user = +{ $user->get_columns };
        }
        else {
            # assume some kind of hash-backed object
            $user = \%$user;
        }
    }
    YAML::Dump $user;
};

get '/update_user_name/:realm' => sub {
    my $realm = param 'realm';
    YAML::Dump update_user 'mark', realm => $realm, name => "Wiltshire Apples $realm";
};

post '/update_user' => sub {
    my $params = body_parameters->as_hashref;
    my $username = delete $params->{username};
    send_as YAML => update_user $username, %$params;
};

get '/get_user_mark/:realm' => sub {
    my $realm = param 'realm';
    content_type 'text/x-yaml';
    my $user = get_user_details 'mark', $realm;
    if ( blessed($user) ) {
        if ( $user->isa('DBIx::Class::Row')) {
            $user = +{ $user->get_columns };
        }
        else {
            # assume some kind of hash-backed object
            $user = \%$user;
        }
    }
    YAML::Dump $user;
};

post '/auth_provider' => sub {
    $plugin->auth_provider( body_parameters->get('realm') );
    return;
};

get '/logged_in_user_password_expired' => sub {
    my $ret = logged_in_user_password_expired;
    return $ret ? 'yes' : 'no';
};

1;
