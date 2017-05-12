#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::Constants perl => File::Spec->catdir('t', 'confs', 'conf_error.pl');

eval "use t::lib::Foo::Bar";
like($@, qr/^Unchecked constants found in config for 'Foo\:\:Bar' \-\> \(BAM\)/, '... got the right error');