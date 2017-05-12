use strict;
use Test::More;

my @modules = qw(DateTime::Format::Japanese);

plan (tests => scalar @modules);

use_ok($_) for @modules;
