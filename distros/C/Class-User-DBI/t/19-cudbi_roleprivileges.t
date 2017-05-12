## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

use Data::Dumper;

BEGIN {
    use_ok('Class::User::DBI::RolePrivileges');
}

use Class::User::DBI::Roles;
use Class::User::DBI::Privileges;

use DBIx::Connector;

can_ok(
    'Class::User::DBI::RolePrivileges',
    qw(  _db_conn           new             add_privileges
      delete_privileges  has_privilege   fetch_privileges
      get_role           configure_db
      )
);

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           cud_roles
#           By default, tests are run against an in-memory database. (safe)
# YOU HAVE BEEN WARNED.

# SQLite database settings.
my $dsn     = 'dbi:SQLite:dbname=:memory:';
my $db_user = q{};
my $db_pass = q{};

# mysql database settings.
# my $database = 'cudbi_test';
# my $dsn      = "dbi:mysql:database=$database";
# my $db_user  = 'tester';
# my $db_pass  = 'testers_pass';

my $conn = DBIx::Connector->new(
    $dsn, $db_user, $db_pass,
    {
        RaiseError => 1,
        AutoCommit => 1,
    }
);

# Configure the database.  We already know that we can configure the roles
# and privileges tables, so we'll only test the roleprivs table.

subtest
  'Test Class::User::DBI::RolePrivileges->configure_db() -- Database Config.' =>
  sub {
    dies_ok { Class::User::DBI::RolePrivileges->configure_db() }
    'configure_db(): dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::RolePrivileges->configure_db( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'configure_db(): dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::RolePrivileges->configure_db('DBIx::Connector');
    }
    'configure_db(): dies if passed a string instead of an object ref.';
    ok(
        Class::User::DBI::RolePrivileges->configure_db($conn),
        'configure_db(): Got a good return value.'
    );
    my $sth = $conn->run(
        fixup => sub {
            my $sub_sth = $_->prepare('SELECT sql FROM sqlite_master');
            $sub_sth->execute();
            return $sub_sth;
        }
    );
    my $table_creation_SQL = ( $sth->fetchrow_array )[0];
    like(
        $table_creation_SQL,
        qr/CREATE TABLE cud_roleprivs/,
        'configure_db(): The correct table was created.'
    );
    like( $table_creation_SQL, qr/role\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'role\' column was created.' );
    like(
        $table_creation_SQL,
        qr/privilege\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'privilege\' column was created.'
    );
    like(
        $table_creation_SQL,
        qr/PRIMARY\s+KEY\s*\(role,privilege\)/,
        'configure_db(): The primary key was created.'
    );
    done_testing();

  };

# Set up some temporary database tables for the Roles and Privileges classes.
Class::User::DBI::Roles->configure_db($conn);
Class::User::DBI::Privileges->configure_db($conn);

# Set up some roles and privileges to test.
my $r = Class::User::DBI::Roles->new($conn);
$r->add_roles(
    [ 'goofers_off', 'The group of goof-offs' ],
    [ 'workers',     'The group that works hard' ],
    [ 'warriers',    'The group that makes war' ],
);

my $p = Class::User::DBI::Privileges->new($conn);
$p->add_privileges(
    [ 'goof_around', 'The privilege to goof around' ],
    [ 'work',        'The privilege to work.' ],
    [ 'party',       'The right to paarrrrr-teee' ],
    [ 'play_hard',   'Those who work hard play hard' ],
    [ 'make_war',    'The right to make war.' ],
);

subtest 'Test Class::User::DBI::RolePrivileges->new() -- Constructor.' => sub {

    dies_ok { Class::User::DBI::RolePrivileges->new() }
    'Constructor dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::RolePrivileges->new( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'Conctructor dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::RolePrivileges->new('DBIx::Connector');
    }
    'Constructor dies if passed a string instead of an object ref.';
    dies_ok {
        Class::User::DBI::RolePrivileges->new( $conn, 'partier' );
    }
    'Constructor dies if passed an invalid role.';
    dies_ok {
        Class::User::DBI::RolePrivileges->new($conn);
    }
    'Constructor dies if not passed a role.';
    dies_ok {
        Class::User::DBI::RolePrivileges->new( $conn, [] );
    }
    'Constructor dies if passed a reference instead of a role.';

    my $rp = new_ok( 'Class::User::DBI::RolePrivileges', [ $conn, 'workers' ] );
    isa_ok( $rp->{_db_conn}, 'DBIx::Connector',
        'RolePrivileges object has a DBIx::Connector object attribute.' );
    ok( exists $rp->{role}, 'RolePrivileges object has a "role" attribute.' );
    done_testing();
};

subtest 'Test add_privileges() and has_privilege().' => sub {
    my $rp = Class::User::DBI::RolePrivileges->new( $conn, 'workers' );
    ok( !$rp->has_privilege('work'),
            'has_privilege(): returns false for a privilege '
          . 'the group doesn\t have.' );
    dies_ok { $rp->has_privilege() }
    'has_privilege(): throws an exception when privilege is undef.';
    dies_ok { $rp->has_privilege(q{}) }
    'has_privilege(): throws an exception when privilege is empty.';
    is( $rp->add_privileges(), 0,
        'add_priviliges(): When none are added, return value is 0.' );
    is( $rp->add_privileges( 'work', 'play_hard' ),
        2,
        'add_privileges(): When two privileges are added, return value is 2.' );
    ok( $rp->has_privilege('work'),
        'add_privileges(): Successfully added "work" privilege.' );
    ok( $rp->has_privilege('play_hard'),
        'add_privileges(): Successfully added "play_hard" privilege.' );
    is( $rp->add_privileges('tupitar'), 0,
        'add_privileges(): Returns 0 and refuses to add an invalid privilege.'
    );
    ok( !$rp->has_privilege('tupitar'),
        'add_privileges(): Didn\'t add "tupitar" (invalid privilege).' );

    done_testing();
};

subtest 'Test delete_privileges().' => sub {
    my $rp = Class::User::DBI::RolePrivileges->new( $conn, 'workers' );
    ok(
        $rp->has_privilege('play_hard'),
        'has_privilege(): verifies a privilege.'
    );
    is( $rp->delete_privileges('play_hard'),
        1, 'delete_privilege(): Good return value for delete.' );
    ok(
        !$rp->has_privilege('play_hard'),
        'delete_privilege(): Delete confirmed.'
    );
    is( $rp->delete_privileges('play_hard'),
        0, 'delete_privilege(): Refuses to delete a non-role privilege.' );
    done_testing();
};

subtest 'Test fetch_privileges().' => sub {
    my $rp = Class::User::DBI::RolePrivileges->new( $conn, 'workers' );
    is( scalar $rp->fetch_privileges,
        1, 'fetch_privileges(): Found one privilege.' );
    $rp->add_privileges( 'play_hard', 'make_war', 'party' );
    my @privs = $rp->fetch_privileges;
    is( scalar @privs, 4, 'fetch_privileges(): Found four privileges.' );
    ok( ( any { $_ eq 'make_war' } @privs ),
        'fetch_privileges(): Identified a valid privilege.' );
    $rp->delete_privileges( 'play_hard', 'make_war', 'party', 'work' );
    @privs = $rp->fetch_privileges;
    is( scalar @privs,
        0, 'fetch_privileges(): Returns empty list if no privs.' );
    done_testing();
};

done_testing();
