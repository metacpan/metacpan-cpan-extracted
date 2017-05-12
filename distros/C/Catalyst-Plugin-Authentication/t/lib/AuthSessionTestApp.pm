package User::SessionRestoring;
use base qw/Catalyst::Authentication::User::Hash/;

sub for_session { $_[0]->id }
sub store { $_[0]->{store} }

package AuthSessionTestApp;
use strict;
use warnings;
use base qw/Catalyst/;

use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::Cookie

    Authentication
    Authentication::Store::Minimal
    Authentication::Credential::Password
/;

our $users = {
    foo => User::SessionRestoring->new(
        id => 'foo',
        password => "s3cr3t",
    ),
};

__PACKAGE__->config(authentication => {users => $users});

__PACKAGE__->setup;

$users->{foo}{store} = __PACKAGE__->default_auth_store;

1;

