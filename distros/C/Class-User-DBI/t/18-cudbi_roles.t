## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

BEGIN {
    use_ok('Class::User::DBI::Roles');
}

use DBIx::Connector;

can_ok(
    'Class::User::DBI::Roles',
    qw(  _db_conn           add_roles     configure_db
      delete_roles     exists_role   fetch_roles
      get_role_description             set_role_description
      new
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

subtest 'Test Class::User::DBI::Roles->new() -- Constructor.' => sub {
    dies_ok { Class::User::DBI::Roles->new() }
    'Constructor dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Roles->new( bless {}, 'Not::DBIx::Conn::Obj' );
    }
    'Conctructor dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Roles->new('DBIx::Connector');
    }
    'Constructor dies if passed a string instead of an object ref.';

    my $d = new_ok( 'Class::User::DBI::Roles', [$conn] );
    isa_ok( $d->{_db_conn}, 'DBIx::Connector',
        'Roles object has a DBIx::Connector object attribute.' );
    ok( exists $d->{roles}, 'Roles object has a "roles" attribute.' );
    is( ref $d->{roles},
        'HASH', 'Roles object\'s "roles" attribute is a hashref.' );

    done_testing();
};

subtest 'Test Class::User::DBI::Roles->configure_db() -- Database Config.' =>
  sub {
    dies_ok { Class::User::DBI::Roles->configure_db() }
    'configure_db(): dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Roles->configure_db( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'configure_db(): dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Roles->configure_db('DBIx::Connector');
    }
    'configure_db(): dies if passed a string instead of an object ref.';
    ok(
        Class::User::DBI::Roles->configure_db($conn),
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
        qr/CREATE TABLE cud_roles/,
        'configure_db(): The correct table was created.'
    );
    like( $table_creation_SQL, qr/role\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'role\' column was created.' );
    like(
        $table_creation_SQL,
        qr/description\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'description\' column was created.'
    );
    like( $table_creation_SQL, qr/PRIMARY\s+KEY\s*\(role\)/,
        'configure_db(): The primary key was created.' );
    done_testing();

  };

# We'll use this connector object for the rest of our tests.
my $d = Class::User::DBI::Roles->new($conn);

subtest 'Test add_roles() and exists_role().' => sub {
    ok( !$d->exists_role('tupitar'),
        'exists_role(): returns false for a non-existent role.' );
    dies_ok { $d->exists_role() }
    'exists_role(): throws an exception when role is undef.';
    dies_ok { $d->exists_role(q{}) }
    'exists_role(): throws an exception when role is empty.';
    my $role = [ 'tupitar', 'This user can tupitar.' ];
    $d->add_roles($role);
    ok( $d->exists_role('tupitar'),
        'add_role(): Added "tupitar". exists_role() returns true.' );
    my @multiple_privs = (
        [ 'tupitar2', 'This user can also tupitar.' ],
        [ 'tupitar3', 'And so can this one.' ],
        [ 'tupitar4', 'And he can too!' ],
    );
    $d->add_roles(@multiple_privs);
    is(
        scalar( grep { $d->exists_role($_) } qw( tupitar2 tupitar3 tupitar4 ) ),
        3,
        'add_roles(): successfully added 3 more roles.'
    );
    done_testing();
};

subtest 'Test delete_roles()' => sub {
    is( $d->delete_roles('tupitar'), 1, 'delete_roles(): Deleted one role.' );
    ok( !$d->exists_role('tupitar'),
        'delete_roles(): "tupitar" role is deleted.' );
    is( $d->delete_roles( 'tupitar2', 'tupitar3' ),
        2, 'delete_roles(): Deleted two roles.' );
    ok( !$d->exists_role('tupitar2'),
        'delete_roles(): "tupitar2" is deleted.' );
    ok( !$d->exists_role('tupitar3'),
        'delete_roles(): "tupitar3" is deleted.' );
    is( $d->delete_roles('tupitar3'),
        0, 'delete_roles(): Won\'t try to delete non-existent role.' );

    done_testing();
};

subtest 'Test fetch_roles().' => sub {
    $d->add_roles(
        [ 'tupitar2', 'He can tupitar again.' ],
        [ 'tupitar5', 'He can do a lot of tupitaring.' ],
    );
    my @privs = $d->fetch_roles;

    is( scalar @privs, 3, 'fetch_roles fetches correct number of roles.' );
    is( ref $privs[0], 'ARRAY', 'fetch_roles(): Return value is an AoA\'s.' );
    ok(
        ( any { $_->[0] eq 'tupitar2' } @privs ),
        'fetch_roles(): Found a correct role.'
    );
    ok(
        ( any { $_->[1] =~ /again/ } @privs ),
        'fetch_roles(): Descriptions load correctly.'
    );

    done_testing();
};

subtest 'Test get_role_description().' => sub {
    dies_ok { $d->get_role_description('gnarfle') }
    'get_role_description(): Throws an exception for ' . 'non-existent role.';
    dies_ok { $d->get_role_description() }
    'get_role_description(): Throws an exception ' . 'when missing param.';
    like(
        $d->get_role_description('tupitar2'),
        qr/tupitar again/,
        'get_role_description(): Returns the description ' . 'of a valid role.'
    );
    done_testing();
};

subtest 'Test set_role_description()' => sub {
    dies_ok { $d->set_role_description() }
    'set_role_description(): Dies if no role specified.';
    dies_ok { $d->set_role_description('gnarfle') }
    'set_role_description(): Dies if role doesn\t exist.';
    dies_ok { $d->set_role_description('tupitar2') }
    'set_role_description(): Dies if no description specified.';
    ok(
        $d->set_role_description( 'tupitar2', 'Not gnarfling.' ),
        'set_role_description(): Got a good return value'
    );
    like( $d->get_role_description('tupitar2'),
        qr/gnarfling/, 'set_role_description(): Description updated.' );
    done_testing();
};

done_testing();
