#!perl

# B::Generate.pm comments used to say "MUST FIX CONSTANTS", 2x, with *emphasis*.
# Whats more, OP_LIST value has changed over releases.
# So we better test for it.
# This is not required anymore. We keep this test just for reference.

# 1st test is baseline, not even using/testing B::Generate.  This
# insures that we get failure reports until we get right
# release-dependent values, which we reverify using B-Gen in 2nd test

# 2nd test uses a constant declared inside B::Generate, which was
# formerly hard-coded, but now calls B::opnumber().
# The test is rather pedantic

use Test::More tests => 4;
use_ok 'B';
use_ok 'B::Generate';

my $ref = B::opnumber("list");
my $check = &B::OP::OP_LIST;
my $check2 = B::OP::OP_LIST();

# the constness isnt seen w/o hints (&,())
my $check3 = B::OP::OP_LIST;

ok ($ref == $check, "B & B-Gen agree that OP_LIST == $ref");
ok ($ref == $check2, "B & B-Gen agree that OP_LIST == $ref");


__END__

