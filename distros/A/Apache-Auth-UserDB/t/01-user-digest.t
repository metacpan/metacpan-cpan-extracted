# Tests for Apache::Auth::User::Digest

use warnings;
use strict;

use Test::More tests => 4;

# Initialization:
##############################################################################

BEGIN {
    use_ok('Apache::Auth::User::Digest');
}

use constant {
    TEST_REALM      => 'Test',
    TEST_USERNAME   => 'Julian Mehnle',
    TEST_PASSWORD   => 'foobar',
    TEST_PW_DIGEST  => 'ef4e1115f75e35811343a2207ba863a8'
};

# Create:
##############################################################################

{
    my $user = Apache::Auth::User::Digest->new(
        realm       => TEST_REALM,
        name        => TEST_USERNAME,
        password    => TEST_PASSWORD
    );
    isa_ok($user, 'Apache::Auth::User::Digest', 'Created user');
    
    is("$user", join(':', TEST_USERNAME, TEST_REALM), 'User object signature');
    
    is($user->password_digest, TEST_PW_DIGEST, 'Digest algorithm works');
}
