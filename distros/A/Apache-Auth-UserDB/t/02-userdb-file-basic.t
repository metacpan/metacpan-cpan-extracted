# Tests for Apache::Auth::UserDB::Basic

use warnings;
use strict;

use Test::More tests => 8;

# Initialization:
##############################################################################

BEGIN {
    use_ok('Apache::Auth::UserDB::File::Basic');
}

use constant {
    USERDB_FILE     => '/tmp/apache-auth-userdb-test.htpasswd',
    TEST_USERNAME   => 'Julian Mehnle',
    TEST_PASSWORD   => 'foobar',
    TEST_PASSWORD2  => 'zippo'
};

# Create and write:
##############################################################################

{
    my $userdb = Apache::Auth::UserDB::File::Basic->new(
        file_name   => USERDB_FILE
    );
    isa_ok($userdb, 'Apache::Auth::UserDB::File::Basic', 'Created userdb');
    
    my $user = Apache::Auth::User::Basic->new(
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
    my $userdb = Apache::Auth::UserDB::File::Basic->open(
        file_name   => USERDB_FILE
    );
    isa_ok($userdb, 'Apache::Auth::UserDB::File::Basic', 'Re-opened userdb');
    
    is($userdb->users, 1, '1 re-read user in userdb');
    
    my $user = Apache::Auth::User::Basic->new(
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD2
    );
    $userdb->add_user($user);
    is($userdb->users, 1, '1 user in userdb after replacing 1 user');
    
    ok($userdb->commit(), 'Committed userdb');
}

unlink(USERDB_FILE);
