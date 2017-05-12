use strict;
use warnings;

use Test::More;
use Test::Exception;

use CatalystX::Controller::Auth;

my @methods = qw(

base
authenticated
not_authenticated
register
_send_register_email
 send_register_email
post_register
login
post_login
logout
post_logout
forgot_password
_send_password_reset_email
 send_password_reset_email
reset_password
post_reset_password
get
change_password
post_change_password

);

my $controller = CatalystX::Controller::Auth->new;

foreach my $method ( @methods )
{
	can_ok( $controller, $method );
}



done_testing();
