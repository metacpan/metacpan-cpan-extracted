use strict;
use warnings;
use Test::More tests => 1;
use Catalyst::Plugin::Session::State::Cookie;

ok !Catalyst::Plugin::Session::State::Cookie->can('new'), 'No new method';

