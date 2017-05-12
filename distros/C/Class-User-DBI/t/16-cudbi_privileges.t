## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

BEGIN {
    use_ok('Class::User::DBI::Privileges');
}

use DBIx::Connector;

can_ok(
    'Class::User::DBI::Privileges',
    qw(  _db_conn           add_privileges     configure_db
      delete_privileges  exists_privilege   fetch_privileges
      get_privilege_description             set_privilege_description
      new
      )
);

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           cud_privileges
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

subtest 'Test Class::User::DBI::Privileges->new() -- Constructor.' => sub {
    dies_ok { Class::User::DBI::Privileges->new() }
    'Constructor dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Privileges->new( bless {}, 'Not::DBIx::Conn::Obj' );
    }
    'Conctructor dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Privileges->configure_db('DBIx::Connector');
    }
    'Constructor dies if passed a string instead of an object ref.';

    my $p = new_ok( 'Class::User::DBI::Privileges', [$conn] );
    isa_ok( $p->{_db_conn}, 'DBIx::Connector',
        'Privileges object has a DBIx::Connector object attribute.' );
    ok( exists $p->{privileges},
        'Privileges object has a "privileges" attribute.' );
    is( ref $p->{privileges},
        'HASH', 'Privileges object\'s "privileges" attribute is a hashref.' );

    done_testing();
};

subtest
  'Test Class::User::DBI::Privileges->configure_db() -- Database Config.' =>
  sub {
    dies_ok { Class::User::DBI::Privileges->configure_db() }
    'configure_db(): dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Privileges->configure_db( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'configure_db(): dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Privileges->new('DBIx::Connector');
    }
    'configure_db(): dies if passed a string instead of an object ref.';
    ok(
        Class::User::DBI::Privileges->configure_db($conn),
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
        qr/CREATE TABLE cud_privileges/,
        'configure_db(): The correct table was created.'
    );
    like(
        $table_creation_SQL,
        qr/privilege\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'privilege\' column was created.'
    );
    like(
        $table_creation_SQL,
        qr/description\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'description\' column was created.'
    );
    like(
        $table_creation_SQL,
        qr/PRIMARY\s+KEY\s*\(privilege\)/,
        'configure_db(): The primary key was created.'
    );
    done_testing();

  };

# We'll use this connector object for the rest of our tests.
my $p = Class::User::DBI::Privileges->new($conn);

subtest 'Test add_privileges() and exists_privilege().' => sub {
    ok( !$p->exists_privilege('tupitar'),
        'exists_privilege(): returns false for a non-existent privilege.' );
    dies_ok { $p->exists_privilege() }
    'exists_privilege(): throws an exception when privilege is undef.';
    dies_ok { $p->exists_privilege(q{}) }
    'exists_privilege(): throws an exception when privilege is empty.';
    my $privilege = [ 'tupitar', 'This user can tupitar.' ];
    $p->add_privileges($privilege);
    ok( $p->exists_privilege('tupitar'),
        'add_privilege(): Added "tupitar". exists_privilege() returns true.' );
    my @multiple_privs = (
        [ 'tupitar2', 'This user can also tupitar.' ],
        [ 'tupitar3', 'And so can this one.' ],
        [ 'tupitar4', 'And he can too!' ],
    );
    $p->add_privileges(@multiple_privs);
    is(
        scalar(
            grep { $p->exists_privilege($_) } qw( tupitar2 tupitar3 tupitar4 )
        ),
        3,
        'add_privileges(): successfully added 3 more privileges.'
    );
    done_testing();
};

subtest 'Test delete_privileges()' => sub {
    is( $p->delete_privileges('tupitar'),
        1, 'delete_privileges(): Deleted one privilege.' );
    ok( !$p->exists_privilege('tupitar'),
        'delete_privileges(): "tupitar" privilege is deleted.' );
    is( $p->delete_privileges( 'tupitar2', 'tupitar3' ),
        2, 'delete_privileges(): Deleted two privileges.' );
    ok( !$p->exists_privilege('tupitar2'),
        'delete_privileges(): "tupitar2" is deleted.' );
    ok( !$p->exists_privilege('tupitar3'),
        'delete_privileges(): "tupitar3" is deleted.' );
    is( $p->delete_privileges('tupitar3'),
        0,
        'delete_privileges(): Won\'t try to delete non-existent privilege.' );

    done_testing();
};

subtest 'Test fetch_privileges().' => sub {
    $p->add_privileges(
        [ 'tupitar2', 'He can tupitar again.' ],
        [ 'tupitar5', 'He can do a lot of tupitaring.' ],
    );
    my @privs = $p->fetch_privileges;

    is( scalar @privs,
        3, 'fetch_privileges fetches correct number of privileges.' );
    is( ref $privs[0],
        'ARRAY', 'fetch_privileges(): Return value is an AoA\'s.' );
    ok(
        ( any { $_->[0] eq 'tupitar2' } @privs ),
        'fetch_privileges(): Found a correct privilege.'
    );
    ok( ( any { $_->[1] =~ /again/ } @privs ),
        'fetch_privileges(): Descriptions load correctly.' );

    done_testing();
};

subtest 'Test get_privilege_description().' => sub {
    dies_ok { $p->get_privilege_description('gnarfle') }
    'get_privilege_description(): Throws an exception for '
      . 'non-existent privilege.';
    dies_ok { $p->get_privilege_description() }
    'get_privilege_description(): Throws an exception ' . 'when missing param.';
    like(
        $p->get_privilege_description('tupitar2'),
        qr/tupitar again/,
        'get_privilege_description(): Returns the description '
          . 'of a valid privilege.'
    );
    done_testing();
};

subtest 'Test set_privilege_description()' => sub {
    dies_ok { $p->set_privilege_description() }
    'set_privilege_description(): Dies if no privilege specified.';
    dies_ok { $p->set_privilege_description('gnarfle') }
    'set_privilege_description(): Dies if privilege doesn\t exist.';
    dies_ok { $p->set_privilege_description('tupitar2') }
    'set_privilege_description(): Dies if no description specified.';
    ok(
        $p->set_privilege_description( 'tupitar2', 'Not gnarfling.' ),
        'set_privilege_description(): Got a good return value'
    );
    like( $p->get_privilege_description('tupitar2'),
        qr/gnarfling/, 'set_privilege_description(): Description updated.' );
    done_testing();
};

done_testing();
