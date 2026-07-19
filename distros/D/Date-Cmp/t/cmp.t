#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Date::Cmp;

cmp_ok(Date::Cmp::datecmp('30 SEP 1943', '4 AUG 1955'), '<', 0, 'before works');
cmp_ok(Date::Cmp::datecmp('BET 1830 AND 1832', '1830-02-06'), '==', 0, 'range works');
cmp_ok(Date::Cmp::datecmp('bef 1 Jun 1965', 1969), '<', 0, 'before year works LHS');
cmp_ok(Date::Cmp::datecmp('1929/06/26', 1939), '<', 0, 'slashes in dates works');
cmp_ok(Date::Cmp::datecmp('26 Aug 1744', '1673-02-22T00:00:00'), '>', 0, 'Zulu times work');
cmp_ok(Date::Cmp::datecmp(1891, 'Oct/Nov/Dec 1892'), '<', 0, 'Month range works');
cmp_ok(Date::Cmp::datecmp(1939, 'bef 1 Jun 1965'), '<', 0, 'before year works RHS');
cmp_ok(Date::Cmp::datecmp('16/11/1689', '1659-07-01'), '>', 0, 'different formats can be compared');
cmp_ok(Date::Cmp::datecmp({ date => '16/11/1689' }, { date => '1659-07-01' }), '>', 0, 'different formats can be compared');

# Regression: DateTime object on LHS must not crash when RHS is a year range.
# '1 Jan 1996' is parsed into a DateTime object by DFG because its first 3-4
# digit sequence (1996) equals the range start, bypassing the early-exit fast
# path, and then reaching the range comparisons before the object was unwrapped.
cmp_ok(Date::Cmp::datecmp('1 Jan 1996', '1996-2000'),    '==', 0, 'DateTime LHS within dash range');
cmp_ok(Date::Cmp::datecmp('1 Jan 1996', 'BET 1996 AND 2000'), '==', 0, 'DateTime LHS within BET range');
cmp_ok(Date::Cmp::datecmp('1 Jan 1994', '1996-2000'),    '<',  0, 'DateTime LHS before dash range');
cmp_ok(Date::Cmp::datecmp('1 Jan 2001', '1996-2000'),    '>',  0, 'DateTime LHS after dash range');

done_testing();
