use strict;
use warnings;

use Test::More tests => 2+8+5+5+5+13+6+3;
sub latest_version { return '0.04' }
BEGIN { use_ok('Code::DRY', latest_version()) };
require_ok('Code::DRY');

#########################

can_ok('Code::DRY', 'build_suffixarray_and_lcp');
can_ok('Code::DRY', 'reduce_lcp_to_nonoverlapping_lengths');
can_ok('Code::DRY', 'get_offset_at');
can_ok('Code::DRY', 'get_isa_at');
can_ok('Code::DRY', 'get_len_at');
can_ok('Code::DRY', 'get_size');
can_ok('Code::DRY', 'get_substr_from_input');
can_ok('Code::DRY', '__free_all');

is(Code::DRY::get_size(), 0, "initial get_size() gives 0");
is(Code::DRY::get_offset_at(0), 0xffffffff, "initial get_offset_at() gives ~0");
is(Code::DRY::get_len_at(0), 0xffffffff, "initial get_len_at() gives ~0");
is(Code::DRY::get_isa_at(0), 0xffffffff, "initial get_isa_at() gives ~0");
is(Code::DRY::get_substr_from_input(0,0), undef, "initial get_substr_from_input() gives undef");

Code::DRY::__free_all();

is(Code::DRY::get_size(), 0, "get_size() after __free_all gives 0");
is(Code::DRY::get_offset_at(0), 0xffffffff, "get_offset_at() after __free_all gives ~0");
is(Code::DRY::get_len_at(0), 0xffffffff, "get_len_at() after __free_all gives ~0");
is(Code::DRY::get_isa_at(0), 0xffffffff, "get_isa_at() after __free_all gives ~0");
is(Code::DRY::get_substr_from_input(0,0), undef, "get_substr_from_input() after __free_all gives undef");

my ($SA, $LCP, $ISA);
my $teststring = 'aba';
my $teststring2 = $teststring;
is(Code::DRY::build_suffixarray_and_lcp($teststring2), 0, "build the suffix array for '$teststring2' succeeds");
#TODO: encapsulate the input string (without copying (move-semantics) and memory leaks)
#$teststring2 = 'Code-DRY-teststring';
undef $teststring2;

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

$LCP = [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)];
is_deeply($LCP, [0, 1, 0], "the content of the longest common prefix array is correct");

is(Code::DRY::get_substr_from_input(1,1), 'b', "get_substr_from_input(secondCharacter,1) after build_suffixarray_and_lcp gives second character");
is(Code::DRY::get_substr_from_input(3,0), '', "get_substr_from_input(behindEndOfString, 0) gives empty string");
is(Code::DRY::get_substr_from_input(2,1), 'a', "get_substr_from_input(lastCharOfString, 1) gives last character");
is(Code::DRY::get_substr_from_input(2,2), 'a', "get_substr_from_input(lastCharOfString, 2) gives last character");
is(Code::DRY::get_substr_from_input(-1,0), '', "get_substr_from_input(-1,0) gives empty string");
is(Code::DRY::get_substr_from_input(-2,1), 'b', "get_substr_from_input(secondCharacter,1) after build_suffixarray_and_lcp gives second character");
is(Code::DRY::get_substr_from_input(-1,1), 'a', "get_substr_from_input(lastCharOfString, 1) gives last character");
is(Code::DRY::get_substr_from_input(-1,2), 'a', "get_substr_from_input(lastCharOfString, 2) gives last character");
is(Code::DRY::get_substr_from_input(0,-1), 'ab', "get_substr_from_input(0, -1) gives string without last character");
is(Code::DRY::get_substr_from_input(0,-2), 'a', "get_substr_from_input(0, -2) gives string without last two characters");
is(Code::DRY::get_substr_from_input(-2,-1), 'ba', "get_substr_from_input(-2, -1) gives string without first character");
is(Code::DRY::get_substr_from_input(-2), 'ba', "get_substr_from_input(-2) gives string without first character");
is(Code::DRY::get_substr_from_input(), 'aba', "get_substr_from_input() gives complete string");


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

