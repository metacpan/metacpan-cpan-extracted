use strict;
use warnings;

use Test::More tests => 2+4+4+5+7+6+3;
BEGIN { use_ok('Code::DRY') };
require_ok('Code::DRY');

#########################

can_ok('Code::DRY', 'build_suffixarray_and_lcp');
can_ok('Code::DRY', 'reduce_lcp_to_nonoverlapping_lengths');
can_ok('Code::DRY', 'get_offset_at');
can_ok('Code::DRY', 'get_isa_at');
can_ok('Code::DRY', 'get_len_at');
can_ok('Code::DRY', 'get_size');
can_ok('Code::DRY', '__free_all');

is(Code::DRY::get_size(), 0, "initial get_size() gives 0");
is(Code::DRY::get_offset_at(0), 0xffffffff, "initial get_offset_at() gives ~0");
is(Code::DRY::get_len_at(0), 0xffffffff, "initial get_len_at() gives ~0");
is(Code::DRY::get_isa_at(0), 0xffffffff, "initial get_isa_at() gives ~0");

Code::DRY::__free_all();

is(Code::DRY::get_size(), 0, "get_size() after __free_all gives 0");
is(Code::DRY::get_offset_at(0), 0xffffffff, "get_offset_at() after __free_all gives ~0");
is(Code::DRY::get_len_at(0), 0xffffffff, "get_len_at() after __free_all gives ~0");
is(Code::DRY::get_isa_at(0), 0xffffffff, "get_isa_at() after __free_all gives ~0");

my ($SA, $LCP, $ISA);
my $teststring = 'aba';
is(Code::DRY::build_suffixarray_and_lcp($teststring), 0, "build the suffix array for '$teststring' succeeds");

is(Code::DRY::get_size(), length $teststring, "get_size() gives the right size back");

# 2:    a
# 0:    aba
# 1:    ba
 
$SA = [ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($SA, [2, 0, 1], "the content of the suffix array is correct");

# 1  0:    aba
# 2  1:    ba
# 0  2:    a

$ISA = [ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($ISA, [1, 2, 0], "the content of the inverse suffix array is correct");

# 0    ()
# 1    (a)
# 0    ()

TODO: { local $TODO = 'a trivial case that does not work yet';
$LCP = [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($LCP, [0, 1, 0], "the content of the longest common prefix array is correct");
}

$teststring = 'mississippi';
is(Code::DRY::build_suffixarray_and_lcp($teststring), 0, "build the suffix array for '$teststring' succeeds");

is(Code::DRY::get_size(), length $teststring, "get_size() gives the right size back");

#10:    i
# 7:    ippi
# 4:    issippi
# 1:    ississippi
# 0:    mississippi
# 9:    pi
# 8:    ppi
# 6:    sippi
# 3:    sissippi
# 5:    ssippi
# 2:    ssissippi
 
$SA = [ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($SA, [10, 7, 4, 1, 0, 9, 8, 6, 3, 5, 2], "the content of the suffix array is correct");

#  4  0:    mississippi
#  3  1:    ississippi
# 10  2:    ssissippi
#  8  3:    sissippi
#  2  4:    issippi
#  9  5:    ssippi
#  7  6:    sippi
#  1  7:    ippi
#  6  8:    ppi
#  5  9:    pi
#  0 10:    i
 
$ISA = [ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($ISA, [4, 3, 10, 8, 2, 9, 7, 1, 6, 5, 0], "the content of the inverse suffix array is correct");

# 0    ()
# 1    (i)
# 1    (i)
# 4    (issi) overlapping
# 0    ()
# 0    ()
# 1    (p)
# 0    ()
# 2    (si)
# 1    (s)
# 3    (ssi)

$LCP = [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($LCP, [0, 1, 1, 4, 0, 0, 1, 0, 2, 1, 3], "the content of the longest common prefix array is correct (overlapping)");

Code::DRY::reduce_lcp_to_nonoverlapping_lengths();

# 0    ()
# 1    (i)
# 1    (i)
# 3    (iss) non overlapping
# 0    ()
# 0    ()
# 1    (p)
# 0    ()
# 2    (si)
# 1    (s)
# 3    (ssi)

$LCP= [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($LCP, [0, 1, 1, 3, 0, 0, 1, 0, 2, 1, 3], "the content of the longest common prefix array is correct (nonoverlapping)");

Code::DRY::__free_all();
is(Code::DRY::get_size(), 0, 'get_size() == 0 after __free_all()');
is(Code::DRY::get_offset_at(0), 0xffffffff, 'empty suffix array after __free_all()');
is(Code::DRY::get_len_at(0), 0xffffffff, 'empty longest-common-prefix array after __free_all()');

