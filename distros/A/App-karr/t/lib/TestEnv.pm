package TestEnv;
use strict;
use warnings;

# k288: a test process must not inherit the developer's own KARR_CLAIM --
# every command that takes --claim defaults to it (ADR 0005), the skill has
# every agent export it first thing, and a suite that only passes under an
# unset KARR_CLAIM fails for exactly the people it tells to set one. Deleting
# it here, at load time, covers both a dispatched in-process command object
# and a spawned bin/karr child, since both read it from this same %ENV. A
# test that wants KARR_CLAIM sets it itself, after loading this module
# (typically `local $ENV{KARR_CLAIM} = '...'` inside one subtest).
delete $ENV{KARR_CLAIM};

1;
