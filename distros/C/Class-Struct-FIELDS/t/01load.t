# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 1 }

require 5.005_64;
use strict;
use warnings;

use Test;

# Struct creation tests.

# Test 1:
eval "use Class::Struct::FIELDS v0.9";
ok (not $@) or warn $@;

use Class::Struct::FIELDS;
