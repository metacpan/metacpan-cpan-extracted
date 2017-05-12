package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::Cookie
    /;


extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->config->{captcha} = {
    session_name => 'captcha_string',
    gd_config => {
        width => 100,
        height => 50,
        lines => 5,
        gd_font => 'giant',
    },
    create => [qw/normal rect/],
    particle => [10],
    out => {force => 'jpeg'}
};


__PACKAGE__->setup;

1;
