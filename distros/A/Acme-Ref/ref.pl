#!/usr/bin/perl -w

use strict;
use Acme::Ref qw/deref/;

my $h = { yomomma => q!so fat! };

print deref("$h")->{yomomma};

my $val = deref("HASH(0x0)");
# doesnt die, returns undef


