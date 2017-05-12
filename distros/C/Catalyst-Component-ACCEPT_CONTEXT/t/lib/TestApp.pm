# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp;
use strict;
use warnings;

use Catalyst;
TestApp->config(foo => 'baz');
TestApp->setup;
1;

