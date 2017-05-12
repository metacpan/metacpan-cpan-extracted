package TestApp;
use warnings;
use strict;

use Catalyst;

__PACKAGE__->config(name => 'TestApp', home => '/some/dir');
__PACKAGE__->setup(qw/Session Session::State::Cookie Session::Store::FastMmap/);

1;
