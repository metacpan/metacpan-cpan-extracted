package Catalyst::Plugin::Session::State::Dummy;

use base 'Catalyst::Plugin::Session::State';
use MRO::Compat;

sub setup_session {
    my $c = shift;
    $c->maybe::next::method( @_ );

    $self->sessionid(1);
}

sub get_session_id { 1; }

1;

package TestApp;
use strict;

use Catalyst qw/
    Session Session::Store::Dummy Session::State::Cookie
    MessageStack
/;

TestApp->setup;

1;
