package MyApp;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Crypt::SaltedHash;
use My::Schema;

# so that the config takes effect first
BEGIN { 
    set plugins => {
        DBIC => {
            default => {
                dsn => 'dbi:SQLite::memory:',
                schema_class => 'My::Schema',
            },
        },
        'Auth::Extensible' => {
            disable_roles => 0,
            realms => {
                users => {
                    provider        => 'DBIC',
                    users_resultset => 'Users',
                    password_check  => 'check_secret',
                },
            },
        },
    };

    set session => 'Simple';

    set show_errors => 0;
#    set logger => 'console';
}

use Dancer::Plugin::Auth::Extensible;

get '/init' => sub {
    
    schema->deploy;

    my $user = rset('Users')->create({ username => 'bob', secret => 'please' });

    my $role = rset('Roles')->create({ role => 'overlord' });

    $user->add_to_roles($role, {});
};

get '/authenticate/:user/:password' => sub {
    my( $success, $realm ) = authenticate_user( ( map { param($_) } qw/ user password / ),
        'users' );

    if( $success ) {
        session logged_in_user => params->{user};
        session logged_in_user_realm => $realm;
    }

    return $success;
};

get '/roles' => sub {
    return join ':', user_roles;
};

1;
