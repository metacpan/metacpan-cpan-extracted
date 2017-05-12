# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 1 }

use strict;

use Test;

# Test 1:
eval "use Class::Class";
ok (not $@);
