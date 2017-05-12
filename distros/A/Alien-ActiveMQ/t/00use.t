#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;

use Test::More tests => 2;

use_ok('Alien::ActiveMQ');
eval { require "$Bin/../script/install-activemq"; };
ok !$@, 'Can require script/install-activemq' or warn $@;

