#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Class::User::DBI::Roles;
use Class::User::DBI::Privileges;
use Class::User::DBI::Domains;
use Class::User::DBI::RolePrivileges;
use Class::User::DBI::UserDomains;
use Class::User::DBI;

use DBIx::Connector;

use Data::Dumper;

# SQLite database settings.
my $dsn     = 'dbi:SQLite:dbname=:memory:';
my $db_user = q{};
my $db_pass = q{};

my $conn = DBIx::Connector->new(
    $dsn, $db_user, $db_pass,
    {
        RaiseError => 1,
        AutoCommit => 1,
    }
);

my @classes = qw(
  Class::User::DBI::Roles
  Class::User::DBI::Privileges
  Class::User::DBI::Domains
  Class::User::DBI::RolePrivileges
  Class::User::DBI::UserDomains
  Class::User::DBI
);

foreach my $class (@classes) {
    ok( $class->configure_db($conn), "Configured table for $class." );
}

# Create some roles.

my $r = new_ok( 'Class::User::DBI::Roles', [$conn] );

ok(
    $r->add_roles(
        [ 'workers',    'Those who work' ],
        [ 'players',    'Those who play' ],
        [ 'principles', 'Those who care' ]
    ),
    'Added roles.'
);

# Create some privileges.

my $p = new_ok( 'Class::User::DBI::Privileges', [$conn] );

ok(
    $p->add_privileges(
        [ 'work',       'The right to work' ],
        [ 'work_hard',  'The right to work hard' ],
        [ 'play',       'The right to play' ],
        [ 'worry',      'The right to worry' ],
        [ 'administer', 'The right to administer' ],
        [ 'watch',      'The right to watch' ],
        [ 'rest',       'The right to rest' ]
    ),
    'Added a bunch of privileges.'
);

# Assign some privileges to roles.
my ( $wkrp, $plrp, $prrp );

is(
    ref( $wkrp = Class::User::DBI::RolePrivileges->new( $conn, 'workers' ) ),
    'Class::User::DBI::RolePrivileges',
    'Created a role-privileges object for "workers" role.'
);
is(
    ref( $plrp = Class::User::DBI::RolePrivileges->new( $conn, 'players' ) ),
    'Class::User::DBI::RolePrivileges',
    'Created a role-privileges object for "players" role.'
);
is(
    ref( $prrp = Class::User::DBI::RolePrivileges->new( $conn, 'principles' ) ),
    'Class::User::DBI::RolePrivileges',
    'Created a role-privileges object for "principles" role.'
);

ok( $wkrp->add_privileges( 'work', 'work_hard' ),
    'Added privileges for "workers"' );
ok( $plrp->add_privileges( 'play', 'rest' ), 'Added privileges for "players"' );
ok( $prrp->add_privileges( 'worry', 'work_hard', 'play', 'administer' ),
    'Added privileges for "principles"' );

# Create some domains.

my $d = new_ok( 'Class::User::DBI::Domains', [$conn] );

is(
    $d->add_domains(
        [ 'east',  'The Eastern territories' ],
        [ 'west',  'The Western territories' ],
        [ 'north', 'The Northern territories' ],
        [ 'south', 'The Southern territories' ],
    ),
    4,
    'Created four domains.'
);

# Now add a user.
my $user = new_ok( 'Class::User::DBI', [ $conn, 'kahn' ] );

ok(
    $user->add_user(
        {
            password => 'The rain in Spain falls mainly on the planes.',
            ip_req   => 1,
            username => 'Ghengis Kahn',
            email    => 'wreker@havoc.net',
            ips      => [ '192.168.0.1', '127.0.0.1' ],
            role     => 'principles',
            domains  => [qw( east west north south )],
        }
    ),
    'Added user "kahn".'
);

ok( $user->exists_user, "Kahn exists." );

ok(
    $user->validate(
        'The rain in Spain falls mainly on the planes.',
        '192.168.0.1'
    ),
    'He validates.'
);

ok( $user->user_domains->has_domain('north'), 'He has a "north" domain.' );

my @domains = $user->user_domains->fetch_domains;

is( scalar @domains, 4, 'He has four domains.' );

ok( $user->is_role('principles'), 'He has the "principles" role.' );
ok( $user->role_privileges->has_privilege('play'),
    'He has the "play" privilege.' );
ok(
    !$user->role_privileges->has_privilege('watch'),
    'He doesn\'t have the "watch" privilege.'
);

my $profile;

is( ref( $profile = $user->load_profile ),
    'HASH', 'load_profile returns a hashref.' );

foreach my $key (qw( username email domains role privileges )) {
    ok( exists $profile->{$key}, "$key profile attribute exists." );
}

my $credentials;

is( ref( $credentials = $user->get_credentials ),
    'HASH', 'get_credentials returns a hashref.' );

foreach my $key (qw( valid_ips ip_required salt_hex userid pass_hex )) {
    ok( exists $credentials->{$key}, "$key credentials attribute exists." );
}

ok( $user->delete_user, 'User deleted.' );

ok( !$user->validated, 'User is no longer valid.' );

ok( !$user->exists_user, 'User no longer exists.' );

done_testing();
