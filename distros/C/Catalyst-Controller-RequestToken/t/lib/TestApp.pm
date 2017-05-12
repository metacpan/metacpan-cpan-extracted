package TestApp;
use strict;
use warnings;

use Catalyst qw(-Debug Session Session::Store::Dummy Session::State::Cookie);
#use Catalyst qw(Session Session::Store::Dummy Session::State::Cookie);
__PACKAGE__->config('Controller::Simple' => {session_name => '__token', request_name => '__token'});
__PACKAGE__->setup;

1;
