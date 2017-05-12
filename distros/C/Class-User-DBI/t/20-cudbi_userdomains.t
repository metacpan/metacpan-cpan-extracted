## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

use Data::Dumper;

BEGIN {
    use_ok('Class::User::DBI::UserDomains');
}

use Class::User::DBI;
use Class::User::DBI::Domains;

use DBIx::Connector;

can_ok(
    'Class::User::DBI::UserDomains',
    qw(  _db_conn           new             add_domains
      delete_domains     has_domain      fetch_domains
      get_userid         configure_db
      )
);

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           cud_userids
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

# Configure the database.  We already know that we can configure the userids
# and domains tables, so we'll only test the userdomains table.

subtest
  'Test Class::User::DBI::UserDomains->configure_db() -- Database Config.' =>
  sub {
    dies_ok { Class::User::DBI::UserDomains->configure_db() }
    'configure_db(): dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::UserDomains->configure_db( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'configure_db(): dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::UserDomains->configure_db('DBIx::Connector');
    }
    'configure_db(): dies if passed a string instead of an object ref.';
    ok(
        Class::User::DBI::UserDomains->configure_db($conn),
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
        qr/CREATE TABLE cud_userdomains/,
        'configure_db(): The correct table was created.'
    );
    like( $table_creation_SQL, qr/userid\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'userid\' column was created.' );
    like( $table_creation_SQL, qr/domain\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'domain\' column was created.' );
    like(
        $table_creation_SQL,
        qr/PRIMARY\s+KEY\s*\(userid,domain\)/,
        'configure_db(): The primary key was created.'
    );
    done_testing();

  };

# Set up some temporary database tables for the Users and Domains classes.
Class::User::DBI->configure_db($conn);
Class::User::DBI::Domains->configure_db($conn);

# Set up some userids and domains to test.
my $d = Class::User::DBI::Domains->new($conn);
ok(
    $d->add_domains(
        [ 'west',  'Wicked Witch of the West\'s domain' ],
        [ 'east',  'Wicked Witch of the East\'s domain' ],
        [ 'north', 'Good Witch of the North\'s domain' ],
        [ 'south', 'Good Witch of the South\'s domain' ],
    ),
    'Added some domains to test.'
);

# $userinfo = { username=>...,   email=>..., ip_req=>...,
#               ips_aref=>[...], role=>...,  password=>... };
my $u = Class::User::DBI->new( $conn, 'testuser' );

ok(
    $u->add_user(
        {
            username => 'The Test User',
            email    => 'test@email.com',
            ip_req   => 0,
            role     => undef,
            password => 'testpass',
        }
    ),
    'Added a test user.'
);
ok( $u->exists_user, 'Newly added "testuser" was created.' );

subtest 'Test Class::User::DBI::UserDomains->new() -- Constructor.' => sub {

    dies_ok { Class::User::DBI::UserDomains->new() }
    'Constructor dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::UserDomains->new( bless {}, 'Not::DBIx::Conn::Obj' );
    }
    'Conctructor dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::UserDomains->new('DBIx::Connector');
    }
    'Constructor dies if passed a string instead of an object ref.';
    dies_ok {
        Class::User::DBI::UserDomains->new( $conn, 'partier_uid' );
    }
    'Constructor dies if passed an invalid userid.';
    dies_ok {
        Class::User::DBI::UserDomains->new($conn);
    }
    'Constructor dies if not passed a userid.';
    dies_ok {
        Class::User::DBI::UserDomains->new( $conn, [] );
    }
    'Constructor dies if passed a reference instead of a userid.';

    my $ud = new_ok( 'Class::User::DBI::UserDomains', [ $conn, 'testuser' ] );
    isa_ok( $ud->{_db_conn}, 'DBIx::Connector',
        'UserDomains object has a DBIx::Connector object attribute.' );
    ok( exists $ud->{userid}, 'UserDomains object has a "userid" attribute.' );
    done_testing();
};

subtest 'Test add_domains() and has_domain().' => sub {
    my $ud = Class::User::DBI::UserDomains->new( $conn, 'testuser' );
    ok( !$ud->has_domain('oz'),
            'has_domain(): returns false for a domain '
          . 'the user doesn\'t have.' );
    dies_ok { $ud->has_domain() }
    'has_domain(): throws an exception when domain is undef.';
    dies_ok { $ud->has_domain(q{}) }
    'has_domain(): throws an exception when domain is empty.';
    is( $ud->add_domains(), 0,
        'add_domains(): When none are added, return value is 0.' );
    is( $ud->add_domains( 'east', 'west' ),
        2, 'add_domains(): When two domains are added, return value is 2.' );
    ok( $ud->has_domain('east'),
        'add_domains(): Successfully added "east" domain.' );
    ok( $ud->has_domain('west'),
        'add_domains(): Successfully added "west" domain.' );
    is( $ud->add_domains('tupitar'),
        0, 'add_domains(): Returns 0 and refuses to add an invalid domain.' );
    ok( !$ud->has_domain('tupitar'),
        'add_domains(): Didn\'t add "tupitar" (invalid domain).' );

    done_testing();
};

subtest 'Test delete_domains().' => sub {
    my $ud = Class::User::DBI::UserDomains->new( $conn, 'testuser' );
    ok( $ud->has_domain('east'), 'has_domain(): verifies a domain.' );
    is( $ud->delete_domains('east'),
        1, 'delete_domain(): Good return value for delete.' );
    ok( !$ud->has_domain('east'), 'delete_domain(): Delete confirmed.' );
    is( $ud->delete_domains('east'),
        0, 'delete_domain(): Refuses to delete a non-userid domain.' );
    done_testing();
};

subtest 'Test fetch_domains().' => sub {
    my $ud = Class::User::DBI::UserDomains->new( $conn, 'testuser' );
    is( scalar $ud->fetch_domains, 1, 'fetch_domains(): Found one domain.' );
    $ud->add_domains( 'play_hard', 'make_war', 'party' );
    my @doms = $ud->fetch_domains;
    is( scalar @doms, 1, 'fetch_domains(): Found one domain.' );
    ok( ( any { $_ eq 'west' } @doms ),
        'fetch_domains(): Identified a valid domain.' );
    $ud->delete_domains( 'north', 'south', 'east', 'west' );
    @doms = $ud->fetch_domains;
    is( scalar @doms, 0, 'fetch_domains(): Returns empty list if no privs.' );
    done_testing();
};

done_testing();
