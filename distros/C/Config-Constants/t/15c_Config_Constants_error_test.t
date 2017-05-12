#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

eval "use Config::Constants xml => File::Spec->catdir('t', 'confs', 'conf_error.xml')";
like($@, qr/You have reached the max include depth/, '... got the right error');