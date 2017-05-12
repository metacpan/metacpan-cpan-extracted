package Provider::Exploding;

use Carp qw(croak);
use Moo;
use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

sub authenticate_user {
    croak "KABOOM authenticate_user";
}

sub get_user_details {
    croak "KABOOM get_user_details";
}

#get_user_roles

sub create_user {
    shift;return {@_};
}

#get_user_by_code
#set_user_details

sub set_user_password {
    croak "KABOOM set_user_password";
}

#password_expired

1;
