use strict;
use warnings;

use Test::More;
use Test::Exception;

use CatalystX::Controller::Auth;

my @methods = qw(

form_handler

view
realm

login_id_field
login_id_db_field
db_id_field

enable_register
enable_sending_register_email

register_template
login_template
change_password_template
forgot_password_template
reset_password_template

register_successful_message
register_exists_failed_message
login_required_message
already_logged_in_message
login_successful_message
logout_successful_message
login_failed_message
password_changed_message
password_reset_message
forgot_password_id_unknown

auto_login_after_register

action_after_register
action_after_login
action_after_change_password

forgot_password_email_view
forgot_password_email_from
forgot_password_email_subject
forgot_password_email_template_plain

register_email_view
register_email_from
register_email_subject
register_email_template_plain

token_salt

);

my $controller = CatalystX::Controller::Auth->new;

foreach my $method ( @methods )
{
	can_ok( $controller, $method );
}



done_testing();
