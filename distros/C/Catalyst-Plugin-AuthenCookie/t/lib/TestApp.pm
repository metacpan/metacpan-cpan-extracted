package TestApp;

use strict;
use warnings;

use Catalyst qw( AuthenCookie );

__PACKAGE__->config()->{authen_cookie} =
    { mac_secret => 'the knife' };

__PACKAGE__->setup();


sub login : Global
{
    my $self = shift;
    my $c    = shift;

    $c->set_authen_cookie( value => { user_id => 42 } );

    return;
}

sub long_login : Global
{
    my $self = shift;
    my $c    = shift;

    $c->set_authen_cookie( value   => { user_id => 42 },
                           expires => '03-Mar-2020 00:00:00 GMT',
                         );

    return;
}

sub logout : Global
{
    my $self = shift;
    my $c    = shift;

    $c->unset_authen_cookie();

    return;
}

sub user_id : Global
{
    my $self = shift;
    my $c    = shift;

    my $cookie = $c->authen_cookie_value();

    $c->response()->body( $cookie ? $cookie->{user_id} : 'none' );

    return;
}

1;
