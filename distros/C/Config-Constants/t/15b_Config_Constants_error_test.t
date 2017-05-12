#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use t::lib::Foo::Bar;

eval "use Config::Constants perl => File::Spec->catdir('t', 'confs', 'conf_error.pl')";
like($@, qr/^Unknown constant for 'Foo\:\:Bar' \-\> \(BAM\)/, '... got the right error');