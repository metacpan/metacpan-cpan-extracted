## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use List::MoreUtils qw( any );

use Class::User::DBI;
use Class::User::DBI::Roles;
use Class::User::DBI::Privileges;
use Class::User::DBI::RolePrivileges;

# use Data::Dumper;

use DBIx::Connector;

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           Tables 'users', 'user_ips'.
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

my $appuser        = 'testuser';
my $appuser_ip_req = 'testuser_ip_req';
my $test_ip        = '192.168.0.198';
my $test_ip2       = '192.168.0.199';
my $appuser_pass   = 'Morerugs';

subtest 'Class::User::DBI use and can tests.' => sub {
    my $user = use_ok( 'Class::User::DBI', [ $conn, $appuser ] );
    can_ok(
        'Class::User::DBI', qw(
          _db_conn          _db_run         add_ips         add_user
          configure_db      delete_ips      delete_user     exists_user
          get_credentials get_valid_ips get_role        is_role
          list_users        load_profile    new             set_role
          set_email         update_password set_username
          userid            validate        validated
          )
    );
    done_testing();
};

# Prepare the database environment.
# Drop tables if they exist (in case we're testing against a non-memory
# test database.

$conn->run(
    fixup => sub {
        $_->do('DROP TABLE IF EXISTS users');
    }
);

$conn->run(
    fixup => sub {
        $_->do('DROP TABLE IF EXISTS user_ips');
    }
);

Class::User::DBI->configure_db($conn);
Class::User::DBI::UserDomains->configure_db($conn);
subtest "Tests for $appuser" => sub {

    my $user = Class::User::DBI->new( $conn, $appuser );
    if ( !$user->exists_user ) {
        $user->add_user(
            {
                userid   => $appuser,
                password => $appuser_pass,
                email    => 'fake@address.com',
                username => 'Test User',
            }
        );
    }

    isa_ok( $user, 'Class::User::DBI', 'new():         ' );

    is( $user->userid, $appuser, 'userid():     Returns correct user ID.' );
    is( $user->validated, 0,
        'validated():    Returns false if user has not been validated yet.' );
    isa_ok( $user->_db_conn, 'DBIx::Connector', '_db_conn():     ' );

    my $query_handle = $user->_db_run( 'SELECT * FROM users', () );
    isa_ok( $query_handle, 'DBI::st', '_db_run():  ' );

    my $rv = $user->get_credentials();

    is( ref($rv), 'HASH', 'get_credentials():   Returns a hashref.' );
    ok( exists( $rv->{valid_ips} ),
        'get_credentials():   valid_ips   field found.' );
    ok( exists( $rv->{ip_required} ),
        'get_credentials():   ip_required field found.' );
    ok( exists( $rv->{salt_hex} ),
        'get_credentials():   salt_hex    field found.' );
    ok( exists( $rv->{pass_hex} ),
        'get_credentials():  pass_hex    field found.' );
    ok( exists( $rv->{userid} ), 'get_credentials():  userid    field found.' );
    is( $rv->{userid}, $appuser, 'get_credentials():  Correct userid found.' );
    is( ref( $rv->{valid_ips} ),
        'ARRAY', 'get_credentials():  valid_ips contains aref.' );
    is( $rv->{ip_required} == 0 || $rv->{ip_required} == 1,
        1, 'get_credentials():  ip_required is a Boolean value.' );
    like( $rv->{salt_hex}, qr/^[[:xdigit:]]{128}$/x,
        'get_credentials():  salt_hex has 128 hex digits.' );
    like( $rv->{pass_hex}, qr/^[[:xdigit:]]{128}$/x,
        'get_credentials():  pass_hex has 128 hex digits.' );
    is( scalar( $user->get_valid_ips ),
        0, "get_valid_ips():  $appuser has no IP's." );
    is( $user->exists_user, 1, "exists_user(): $appuser exists in DB." );
    is( $user->validate('wrong pass'),
        0, 'validate: Reject incorrect password with 0.' );
    is( $user->validated, 0,
        'validated():   Flag still false after rejected validation.' );

    is( $user->validate($appuser_pass),
        1, "validate(): $appuser validates by password." );
    is( $user->validated, 1,
            'validated():   Flag set to true after successful call '
          . 'to validate()' );
    $user->validated(0);
    is( $user->validated, 0,
        'validated():   User validation flag may be flipped to not-validated.'
    );
    $user->validated(1);
    is( $user->validated, 0,
            'validated():   User validation flag may not be explicitly set '
          . 'true via accessor.' );
    my $load = $user->load_profile;
    is( ref($load), 'HASH', 'load_profile(): Returns a hashref.' );
    is( $load->{userid}, $appuser,
        'load_userid()->{userid}: Returns proper user ID.' );
    like( $load->{email}, qr/@/,
            'load_userid()->{email}: Returns something that looks like an '
          . 'email address.' );
    done_testing();
};

subtest "Tests for $appuser_ip_req." => sub {
    my $user = Class::User::DBI->new( $conn, $appuser_ip_req );
    if ( !$user->exists_user ) {
        $user->add_user(
            {
                username => 'Test User Requiring IP',
                email    => 'fake@address.com',
                ip_req   => 1,
                ips      => ['192.168.0.198'],
                password => $appuser_pass,
            }
        );
    }
    isa_ok( $user, 'Class::User::DBI', 'new():         ' );
    is( grep( { $_ eq $test_ip } $user->get_valid_ips ),
        1, 'get_valid_ips(): Found a known IP in the DB.' );
    is( $user->validate($appuser_pass),
        0, 'validate(): Reject user requiring IP if no IP is supplied.' );
    is( $user->validate( $appuser_pass, '127.0.0.1' ),
        0, 'validate(): Reject user requiring IP if wrong IP is supplied.' );
    is(
        $user->validate( 'wrong pass', $test_ip ),
        0,
        'validate(): Reject user requiring IP if incorrect pass '
          . 'with correct IP.'
    );
    is( $user->validate( $appuser_pass, $test_ip ),
        1, 'validate(): Accept user if correct password and correct IP.' );

    my (@found) = grep { $_ eq $test_ip2 } $user->get_valid_ips();

    if (@found) {
        $user->delete_ips(@found);
    }

    is( grep( { $_ eq $test_ip2 } $user->get_valid_ips() ),
        0, "add_ips() test:  Initial state: $test_ip2 not in database." );
    $user->add_ips($test_ip2);
    is( grep( { $_ eq $test_ip2 } $user->get_valid_ips() ),
        1, "add_ips() test:  $test_ip2 successfully added." );
    $user->delete_ips($test_ip2);
    is( grep( { $_ eq $test_ip2 } $user->get_valid_ips() ),
        0, "delete_ips():    $test_ip2 successfully deleted." );

    done_testing();
};

subtest 'add_user() tests.' => sub {
    my $user = Class::User::DBI->new( $conn, 'saeed' );
    my $id = $user->add_user(
        {
            password => 'Super Me!',
            ip_req   => 1,
            ips      => [ '192.168.0.100', '201.202.100.5' ],
            username => 'Mr Incredible',
            email    => 'im@the.best',
        }
    );
    is(
        $user->add_ips( '192.168.0.100', '201.202.100.5', '127.0.0.1' ),
        1,
        'add_ips(): Gracefully drop ip adds for ips that are already '
          . 'in the DB.'
    );
    is( $id, 'saeed', 'add_user():  Properly returns the user id.' );
    is( defined( $user->exists_user ), 1, 'New user was added.' );
    is( $user->validate('Super Me!'),
        0, 'New user fails to validate if ip_req set, and no IP given.' );
    is( $user->validate( 'Super Me!', '192.168.0.100' ),
        1, 'New user validates.' );
    is( $user->delete_user, 1, 'delete_user(): Returns truth for success.' );
    is( scalar $user->get_valid_ips,
        0, 'delete_user(): All IPs deleted for deleted user.' );
    is( $user->exists_user, 0,
        'exists_user(): Deleted user no longer exists in DB.' );
    is( $user->validated, 0,
        'validated(): deleted user is no longer validated.' );

    done_testing();
};

subtest 'set_email() tests.' => sub {
    my $user      = Class::User::DBI->new( $conn, $appuser );
    my $stats_ref = $user->load_profile;
    my $old_email = $stats_ref->{email};
    is( $old_email, 'fake@address.com',
        'load_profile(): found correct original email address.' );
    $user->set_email('newfake@address.com');
    $stats_ref = $user->load_profile;
    my $new_email = $stats_ref->{email};
    is( $new_email, 'newfake@address.com',
        'set_email(): Email address correctly altered.' );
    $user->set_email($old_email);    # Reset to original state.
    $user = Class::User::DBI->new( $conn, 'Invalid user' );
    dies_ok { $user->set_email('testing@test.test') }
    'set_email(): Dies if attempt to update email for invalid user.';
    done_testing();
};

subtest 'set_username() tests.' => sub {
    my $user      = Class::User::DBI->new( $conn, $appuser );
    my $stats_ref = $user->load_profile;
    my $old_name  = $stats_ref->{username};
    is( $old_name, 'Test User', 'load_profile() found correct user name.' );
    $user->set_username('Cool Test User');
    $stats_ref = $user->load_profile;
    my $new_name = $stats_ref->{username};
    is( $new_name, 'Cool Test User', 'set_username() set a new user name.' );
    $user->set_username($old_name);
    $user = Class::User::DBI->new( $conn, 'Invalid user' );
    dies_ok { $user->set_username('Bogus User') }
    'set_username(): Dies if trying to update invalid user.';
    done_testing();
};

subtest 'update_password() tests.' => sub {
    my $user = Class::User::DBI->new( $conn, 'passupdate_user' );
    my $userid = $user->add_user(
        {
            password => 'Pass1',
            ip_req   => 0,
            username => 'Password Updating User',
            email    => 'email@address.com',
        }
    );
    is( $user->validate('Pass1'), 1, 'New user validates.' );
    is( $user->update_password( 'Pass2', 'Pass1' ),
        'passupdate_user', 'Pass updated.' );
    my $user2 = Class::User::DBI->new( $conn, 'passupdate_user' );
    is( $user2->validate('Pass2'), 1,
        'User validates against new passphrase.' );
    $user2->delete_user;
    done_testing;
};

subtest 'list_users() tests.' => sub {
    my @users = Class::User::DBI->list_users($conn);
    is( scalar( grep { $_->[0] eq $appuser } @users ),
        1, 'Found our test user.' );
    is( scalar @users > 1, 1, 'Found more than one user.' );
    done_testing();
};

subtest 'Test role code.' => sub {
    ok( Class::User::DBI::Roles->configure_db($conn),
        'Configured a Roles table.' );
    my $r = new_ok( 'Class::User::DBI::Roles', [$conn] );
    ok( $r->add_roles( [ 'test_role', 'Users who can be testers.' ] ),
        'Got a good return value from add_roles().' );
    ok( $r->exists_role('test_role'), 'Added a test role.' );
    my $u = Class::User::DBI->new( $conn, $appuser );
    ok( !$u->is_role('test_role'),
        'is_role(): Properly detects improper (or no) role.' );
    ok( $u->set_role('test_role'), 'Got a good return value from set_role().' );
    ok( $u->is_role('test_role'),
        'add_role(): Correctly added the role.  is_role() found it.' );
    is( $u->get_role, 'test_role', 'The proper role was set.' );
    done_testing();
};

done_testing();

__END__
