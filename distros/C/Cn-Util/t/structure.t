#!/usr/bin/env perl
# structure() / st(): the shape of a data structure, as text.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Cn::Util;

sub shape { structure($_[0], output => 'string', color => 0) }

is( shape({ a => 1, b => 'x' }), <<'END', 'a flat hash' );
HASH{2}
    a: number
    b: string
END

# --- A scalar ref keeps the depth it was found at. ---
# --- Its referent's children used to drop back to depth 1. ---
is( shape({ a => { ptr => \{ x => 1, y => 2 } } }), <<'END', 'hash under a scalar ref, nested in hashes' );
HASH{1}
    a: HASH{1}
        ptr: \ HASH{2}
            x: number
            y: number
END
is( shape([ \[1, 2] ]), <<'END', 'array under a scalar ref, inside an array' );
ARRAY[1]
    [*]: \ ARRAY[2]
        [*]: number
END
is( shape(\{ a => 1 }), <<'END', 'scalar ref at the top level' );
\ HASH{1}
    a: number
END
is( shape({ r => \\'s' }), <<'END', 'ref to a ref' );
HASH{1}
    r: \ \ string
END

my %h = (k => [1, 2]);
is( st(%h, output => 'string', color => 0), <<'END', 'st takes the variable itself' );
HASH{1}
    k: ARRAY[2]
        [*]: number
END

done_testing;
