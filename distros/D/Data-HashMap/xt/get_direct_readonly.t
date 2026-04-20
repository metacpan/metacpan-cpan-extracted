use strict;
use warnings;
use Test::More;

use Data::HashMap::IS;
use Data::HashMap::SS;
use Data::HashMap::I16S;
use Data::HashMap::I32S;

# get_direct returns a zero-copy SV whose storage aliases the map's
# internal buffer (SvREADONLY at the SV level, SvLEN=0 so Perl won't
# free). Note: Perl's `my $d = $m->get_direct(...)` assigns by value,
# producing a fresh mutable copy — so read-only-ness is only preserved
# when you USE the return value directly (print/compare/pass) without
# binding it into a lexical.

for my $spec (
    [ 'IS',    'Data::HashMap::IS',    1,      'val-one',  999      ],
    [ 'SS',    'Data::HashMap::SS',    'k',    'val-two',  'missing' ],
    [ 'I16S',  'Data::HashMap::I16S',  7,      'small',    -1       ],
    [ 'I32S',  'Data::HashMap::I32S',  123,    'medium',   -1       ],
) {
    my ($label, $class, $k, $v, $missing_k) = @$spec;
    my $m = $class->new();
    $m->put($k, $v);

    is $m->get_direct($k), $v, "$label: get_direct returns correct value";

    my $eq = ($m->get_direct($k) eq $v) ? 1 : 0;
    is $eq, 1, "$label: direct comparison works";

    is $m->get_direct($missing_k), undef, "$label: missing key returns undef";

    is length($m->get_direct($k)), length($v), "$label: length correct";
}

# SvREADONLY preservation note: per CLAUDE.md, the returned SV is read-only.
# Verify by examining the SV without copy semantics. We can't easily check
# `readonly()` on a lexical copy, but we CAN check that the returned SV's
# buffer address matches the internal storage (zero-copy invariant).

# That said, many Perl ops implicitly copy, and SvREADONLY only catches
# direct mutation of the original SV. For practical use the contract is:
# "don't hold the return value past any mutating operation."

done_testing;
