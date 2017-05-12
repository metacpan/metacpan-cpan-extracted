# Tests for Apache::Auth::UserDB::Digest

use warnings;
use strict;

use Test::More tests => 9;

# Initialization:
##############################################################################

BEGIN {
    use_ok('Apache::Auth::UserDB::File::Digest');
}

use constant {
    USERDB_FILE     => '/tmp/apache-auth-userdb-test.htdigest',
    TEST_REALM      => 'Test',
    TEST_REALM2     => 'Test2',
    TEST_USERNAME   => 'Julian Mehnle',
    TEST_PASSWORD   => 'foobar'
};

# Create and write:
##############################################################################

{
    my $userdb = Apache::Auth::UserDB::File::Digest->new(
        file_name   => USERDB_FILE
    );
    isa_ok($userdb, 'Apache::Auth::UserDB::File::Digest', 'Created userdb');
    
    my $user = Apache::Auth::User::Digest->new(
        realm       => TEST_REALM,
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD
    );
    $userdb->add_user($user);
    is($userdb->users, 1, '1 created user in userdb');
    
    ok($userdb->commit(), 'Committed userdb');
}

# Open, read, and write:
##############################################################################

{
    my $userdb = Apache::Auth::UserDB::File::Digest->open(
        file_name   => USERDB_FILE
    );
    isa_ok($userdb, 'Apache::Auth::UserDB::File::Digest', 'Re-opened userdb');
    
    is($userdb->users, 1, '1 re-read user in userdb');
    
    my $user = Apache::Auth::User::Digest->new(
        realm       => TEST_REALM2,
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD
    );
    $userdb->add_user($user);
    is($userdb->users, 2, '2 users in userdb after adding 1 user');
    
    $user = Apache::Auth::User::Digest->new(
        realm       => TEST_REALM,
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD
    );
    $userdb->add_user($user);
    is($userdb->users, 2, '2 users in userdb after replacing 1 user');
    
    ok($userdb->commit(), 'Committed userdb');
}

unlink(USERDB_FILE);
