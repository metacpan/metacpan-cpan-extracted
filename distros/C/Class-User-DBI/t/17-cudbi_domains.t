## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

BEGIN {
    use_ok('Class::User::DBI::Domains');
}

use DBIx::Connector;

can_ok(
    'Class::User::DBI::Domains',
    qw(  _db_conn           add_domains     configure_db
      delete_domains     exists_domain   fetch_domains
      get_domain_description             set_domain_description
      new
      )
);

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           cud_domains
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

subtest 'Test Class::User::DBI::Domains->new() -- Constructor.' => sub {
    dies_ok { Class::User::DBI::Domains->new() }
    'Constructor dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Domains->new( bless {}, 'Not::DBIx::Conn::Obj' );
    }
    'Conctructor dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Domains->new('DBIx::Connector');
    }
    'Constructor dies if passed a string instead of an object ref.';

    my $d = new_ok( 'Class::User::DBI::Domains', [$conn] );
    isa_ok( $d->{_db_conn}, 'DBIx::Connector',
        'Domains object has a DBIx::Connector object attribute.' );
    ok( exists $d->{domains}, 'Domains object has a "domains" attribute.' );
    is( ref $d->{domains},
        'HASH', 'Domains object\'s "domains" attribute is a hashref.' );

    done_testing();
};

subtest 'Test Class::User::DBI::Domains->configure_db() -- Database Config.' =>
  sub {
    dies_ok { Class::User::DBI::Domains->configure_db() }
    'configure_db(): dies if not passed a DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Domains->configure_db( bless {},
            'Not::DBIx::Conn::Obj' );
    }
    'configure_db(): dies if passed a non-DBIx::Connector object.';
    dies_ok {
        Class::User::DBI::Domains->configure_db('DBIx::Connector');
    }
    'configure_db(): dies if passed a string instead of an object ref.';
    ok(
        Class::User::DBI::Domains->configure_db($conn),
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
        qr/CREATE TABLE cud_domains/,
        'configure_db(): The correct table was created.'
    );
    like( $table_creation_SQL, qr/domain\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'domain\' column was created.' );
    like(
        $table_creation_SQL,
        qr/description\s+VARCHAR\(\d+\)/,
        'configure_db(): The \'description\' column was created.'
    );
    like(
        $table_creation_SQL,
        qr/PRIMARY\s+KEY\s*\(domain\)/,
        'configure_db(): The primary key was created.'
    );
    done_testing();

  };

# We'll use this connector object for the rest of our tests.
my $d = Class::User::DBI::Domains->new($conn);

subtest 'Test add_domains() and exists_domain().' => sub {
    ok( !$d->exists_domain('tupitar'),
        'exists_domain(): returns false for a non-existent domain.' );
    dies_ok { $d->exists_domain() }
    'exists_domain(): throws an exception when domain is undef.';
    dies_ok { $d->exists_domain(q{}) }
    'exists_domain(): throws an exception when domain is empty.';
    my $domain = [ 'tupitar', 'This user can tupitar.' ];
    $d->add_domains($domain);
    ok( $d->exists_domain('tupitar'),
        'add_domain(): Added "tupitar". exists_domain() returns true.' );
    my @multiple_privs = (
        [ 'tupitar2', 'This user can also tupitar.' ],
        [ 'tupitar3', 'And so can this one.' ],
        [ 'tupitar4', 'And he can too!' ],
    );
    $d->add_domains(@multiple_privs);
    is(
        scalar(
            grep { $d->exists_domain($_) } qw( tupitar2 tupitar3 tupitar4 )
        ),
        3,
        'add_domains(): successfully added 3 more domains.'
    );
    done_testing();
};

subtest 'Test delete_domains()' => sub {
    is( $d->delete_domains('tupitar'),
        1, 'delete_domains(): Deleted one domain.' );
    ok( !$d->exists_domain('tupitar'),
        'delete_domains(): "tupitar" domain is deleted.' );
    is( $d->delete_domains( 'tupitar2', 'tupitar3' ),
        2, 'delete_domains(): Deleted two domains.' );
    ok( !$d->exists_domain('tupitar2'),
        'delete_domains(): "tupitar2" is deleted.' );
    ok( !$d->exists_domain('tupitar3'),
        'delete_domains(): "tupitar3" is deleted.' );
    is( $d->delete_domains('tupitar3'),
        0, 'delete_domains(): Won\'t try to delete non-existent domain.' );

    done_testing();
};

subtest 'Test fetch_domains().' => sub {
    $d->add_domains(
        [ 'tupitar2', 'He can tupitar again.' ],
        [ 'tupitar5', 'He can do a lot of tupitaring.' ],
    );
    my @privs = $d->fetch_domains;

    is( scalar @privs, 3, 'fetch_domains fetches correct number of domains.' );
    is( ref $privs[0], 'ARRAY', 'fetch_domains(): Return value is an AoA\'s.' );
    ok(
        ( any { $_->[0] eq 'tupitar2' } @privs ),
        'fetch_domains(): Found a correct domain.'
    );
    ok(
        ( any { $_->[1] =~ /again/ } @privs ),
        'fetch_domains(): Descriptions load correctly.'
    );

    done_testing();
};

subtest 'Test get_domain_description().' => sub {
    dies_ok { $d->get_domain_description('gnarfle') }
    'get_domain_description(): Throws an exception for '
      . 'non-existent domain.';
    dies_ok { $d->get_domain_description() }
    'get_domain_description(): Throws an exception ' . 'when missing param.';
    like(
        $d->get_domain_description('tupitar2'),
        qr/tupitar again/,
        'get_domain_description(): Returns the description '
          . 'of a valid domain.'
    );
    done_testing();
};

subtest 'Test set_domain_description()' => sub {
    dies_ok { $d->set_domain_description() }
    'set_domain_description(): Dies if no domain specified.';
    dies_ok { $d->set_domain_description('gnarfle') }
    'set_domain_description(): Dies if domain doesn\t exist.';
    dies_ok { $d->set_domain_description('tupitar2') }
    'set_domain_description(): Dies if no description specified.';
    ok(
        $d->set_domain_description( 'tupitar2', 'Not gnarfling.' ),
        'set_domain_description(): Got a good return value'
    );
    like( $d->get_domain_description('tupitar2'),
        qr/gnarfling/, 'set_domain_description(): Description updated.' );
    done_testing();
};

done_testing();
