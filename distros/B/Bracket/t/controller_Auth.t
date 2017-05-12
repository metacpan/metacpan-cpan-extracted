use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{CATALYST_CONFIG} = 't/var/bracket.yml';
    use_ok( 'Catalyst::Test', 'Bracket' );
    use_ok 'Bracket::Controller::Auth';
}

ok( request('/login')->is_success, 'login' );
ok( request('/register')->is_success, 'register' );
ok( request('/email_reset_password_link')->is_success, 'reset passwork email link' );
ok( request('/reset_password?reset_password_token=1234_101')->is_success, 'reset password confirmation' );

# These request require that a user exists
#ok( request('/logout')->is_success, 'Request logout' );
#ok( request('/change_password')->is_success, 'Request should succeed' );

done_testing();