package Provider::NoGetUserDetails;

use Carp qw(croak);
use Moo;
use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

sub authenticate_user {
    my ($self, $username, $password) = @_;
    return 1 if $username eq 'dave' && $password eq 'beer';
    return 0;
}

1;
