use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use DBD::SQLite ();";
    plan skip_all => 'DBD::SQLite required to run this test' if $@;

    eval "use SQL::Translator ();";
    plan skip_all => 'SQL::Translator required to run this test' if $@;

    plan( tests => 11 );
}

use lib 't/lib';
use TestSchema;

# setup
my $schema = TestSchema->connect( "dbi:SQLite:dbname=:memory:", undef, undef );
$schema->deploy;

my @users = qw/root toor daemon operator bin tty/;
my @roles = qw/admin superuser user/;

@users = $schema->populate( 'User' => [ ['login'] => ( map { [$_] } @users ) ] );
@roles = $schema->populate( 'Role' => [ ['name']  => ( map { [$_] } @roles ) ] );

my $u          = 1;
my @user_roles = ();
foreach my $user (@users) {
    my $r = 0;
    foreach my $role (@roles) {
        next if $r >= $u;
        push @user_roles, [ $user->id, $role->id ];
        $r++;
    }
    $u++;
    $u = 1 if $u > scalar @roles;
}

@user_roles = $schema->populate( 'UserRole' => [ [qw/user_id role_id/] => @user_roles ] );

{
    my $rs = $schema->resultset('User')->search(
        {},
        {
            prefetch => { user_role => [qw/role/] },
            order_by => 'me.id ASC'
        }
    )->hashref_array;

    is_deeply(
        $rs,
        [
            {
                'id'        => '1',
                'login'     => 'root',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '1'
                    }
                ]
            },
            {
                'id'        => '2',
                'login'     => 'toor',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '2'
                    },
                    {
                        'role' => {
                            'id'   => '2',
                            'name' => 'superuser'
                        },
                        'role_id' => '2',
                        'user_id' => '2'
                    }
                ]
            },
            {
                'id'        => '3',
                'login'     => 'daemon',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '3'
                    },
                    {
                        'role' => {
                            'id'   => '2',
                            'name' => 'superuser'
                        },
                        'role_id' => '2',
                        'user_id' => '3'
                    },
                    {
                        'role' => {
                            'id'   => '3',
                            'name' => 'user'
                        },
                        'role_id' => '3',
                        'user_id' => '3'
                    }
                ]
            },
            {
                'id'        => '4',
                'login'     => 'operator',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '4'
                    }
                ]
            },
            {
                'id'        => '5',
                'login'     => 'bin',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '5'
                    },
                    {
                        'role' => {
                            'id'   => '2',
                            'name' => 'superuser'
                        },
                        'role_id' => '2',
                        'user_id' => '5'
                    }
                ]
            },
            {
                'id'        => '6',
                'login'     => 'tty',
                'user_role' => [
                    {
                        'role' => {
                            'id'   => '1',
                            'name' => 'admin'
                        },
                        'role_id' => '1',
                        'user_id' => '6'
                    },
                    {
                        'role' => {
                            'id'   => '2',
                            'name' => 'superuser'
                        },
                        'role_id' => '2',
                        'user_id' => '6'
                    },
                    {
                        'role' => {
                            'id'   => '3',
                            'name' => 'user'
                        },
                        'role_id' => '3',
                        'user_id' => '6'
                    }
                ]
            }
        ],
        'hashref_array'
    );
}

{
    my @rs = $schema->resultset('User')->search( {}, { order_by => 'me.id ASC' } )->hashref_array;
    is_deeply(
        \@rs,
        [
            {
                'id'    => '1',
                'login' => 'root'
            },
            {
                'id'    => '2',
                'login' => 'toor'
            },
            {
                'id'    => '3',
                'login' => 'daemon'
            },
            {
                'id'    => '4',
                'login' => 'operator'
            },
            {
                'id'    => '5',
                'login' => 'bin'
            },
            {
                'id'    => '6',
                'login' => 'tty'
            }
        ]
    );
}

{
    my $rs = $schema->resultset('User')->search(
        {},
        {
            prefetch => { user_role => [qw/role/] },
            order_by => 'me.id DESC'
        }
    )->hashref_rs->next;
    is_deeply(
        $rs,
        {
            'id'        => '6',
            'login'     => 'tty',
            'user_role' => [
                {
                    'role' => {
                        'id'   => '1',
                        'name' => 'admin'
                    },
                    'role_id' => '1',
                    'user_id' => '6'
                },
                {
                    'role' => {
                        'id'   => '2',
                        'name' => 'superuser'
                    },
                    'role_id' => '2',
                    'user_id' => '6'
                },
                {
                    'role' => {
                        'id'   => '3',
                        'name' => 'user'
                    },
                    'role_id' => '3',
                    'user_id' => '6'
                }
            ]
        },
        'hashref_rs->next'
    );
}

{
    my $expected_users = [
        {
            'id'    => '1',
            'login' => 'root'
        },
        {
            'id'    => '2',
            'login' => 'toor'
        },
        {
            'id'    => '3',
            'login' => 'daemon'
        },
        {
            'id'    => '4',
            'login' => 'operator'
        },
        {
            'id'    => '5',
            'login' => 'bin'
        },
        {
            'id'    => '6',
            'login' => 'tty'
        }
    ];
    my $rs = $schema->resultset('User')->search( {}, { order_by => 'me.id ASC' } )->hashref_rs;
    while ( my $row = $rs->next ) {
        my $user = shift(@$expected_users);
        is_deeply( $row, $user, "hashref_rs in while loop, user: " . $user->{login} );
    }
}

{
    my $first_row = $schema->resultset('User')->search( { login => 'root' } )->hashref_first;
    is_deeply(
        $first_row,
        {
            'id'    => '1',
            'login' => 'root'
        },
        "hashref_first"
    );
}

{
    my $hashref = $schema->resultset('User')->search( {}, { order_by => 'me.id ASC' } )->hashref_pk;
    is_deeply(
        $hashref,
        {
            1 => {
                'id'    => '1',
                'login' => 'root'
            },
            2 => {
                'id'    => '2',
                'login' => 'toor'
            },
            3 => {
                'id'    => '3',
                'login' => 'daemon'
            },
            4 => {
                'id'    => '4',
                'login' => 'operator'
            },
            5 => {
                'id'    => '5',
                'login' => 'bin'
            },
            6 => {
                'id'    => '6',
                'login' => 'tty'
            }
        },
        'hashref_pk'
    );
}
