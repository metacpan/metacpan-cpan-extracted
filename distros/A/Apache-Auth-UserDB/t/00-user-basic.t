# Tests for Apache::Auth::User::Basic

use warnings;
use strict;

use Test::More tests => 5;

# Initialization:
##############################################################################

BEGIN {
    use_ok('Apache::Auth::User::Basic');
}

use constant {
    TEST_USERNAME   => 'Julian Mehnle',
    TEST_PASSWORD   => 'foobar'
};

# Create:
##############################################################################

{
    my $user = Apache::Auth::User::Basic->new(
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD
    );
    isa_ok($user, 'Apache::Auth::User::Basic', 'Created user');
    
    is("$user", TEST_USERNAME, 'User object signature');
    
    my $password_digest = $user->password_digest;
    like($password_digest, qr/^[.\/0-9A-Za-z]{13}$/, 'Crypt algorithm is standard DES crypt');
    
    is(crypt(TEST_PASSWORD, $password_digest), $password_digest, 'Crypt algorithm works');
}
