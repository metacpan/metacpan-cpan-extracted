#!/usr/bin/env perl
# structure() / st(): the shape of a data structure, as text.
#
# The expected text of the cases after "merging" below is what 0.024's
# structure() printed for them, before 0.0241 stopped copying the values it
# merges; that rewrite was to change no output.
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

# --- merging, as 0.024 printed it ---
is( shape([ { a => 1 }, 'q', undef, [ 2 ] ]), <<'END', 'values of different kinds become a union' );
ARRAY[4]
    [*]: UNION
        <ARRAY> ARRAY[1]
            [*]: number
        <HASH> HASH{1}
            a: number
        <null> null
        <string> string
END
is( shape([ { a => 1, b => 'x' }, { a => 2 } ]), <<'END', 'a key missing from some records is optional' );
ARRAY[2]
    [*]: HASH{2} (from 2 instances)
        a: number
        b?: string
END
my $cyc = { name => 'root' };
$cyc->{self} = $cyc;
is( shape($cyc), <<'END', 'a hash that contains itself' );
HASH{2}
    name: string
    self: (cycle)
END
# A reference to something already being described further out is not
# followed again.  Up to 0.0242 it was always called a cycle; it is one only
# when it leads back to the container that holds it.
{
	my $shared = { x => 1 };
	my $holder = { child => $shared };
	is( shape([ $holder, $shared ]), <<'END', 'a hash shared by two places is shown above, not a cycle' );
ARRAY[2]
    [*]: HASH{2} (from 2 instances)
        child?: (shown above)
        x?: number
END
	$shared->{back} = $holder;
	is( shape([ $holder, $shared ]), <<'END', 'two hashes that refer to each other are a cycle both ways' );
ARRAY[2]
    [*]: HASH{3} (from 2 instances)
        back?: (cycle)
        child?: (cycle)
        x?: number
END
	delete $shared->{back};
	# $shared's loop through its own "me" must not make $holder's "child" a cycle.
	$shared->{me} = $shared;
	is( shape([ $holder, $shared ]), <<'END', 'a loop under another key does not make a shared hash a cycle' );
ARRAY[2]
    [*]: HASH{3} (from 2 instances)
        child?: (shown above)
        me?: (cycle)
        x?: number
END
	my ($p, $q, $r) = ({}, {}, { n => 1 });
	$p->{c} = $r;
	$q->{c} = $q;
	is( shape([ $p, $q, $r ]), <<'END', 'a place holding both kinds shows both' );
ARRAY[3]
    [*]: HASH{2} (from 3 instances)
        c?: (cycle)|(shown above)
        n?: number
END
	my $x = [];
	push @$x, $x;
	is( shape($x), "ARRAY[1]\n    [*]: (cycle)\n", 'an array that contains itself' );
	my $s;
	$s = \$s;
	is( shape(\$s), "\\ (cycle)\n", 'a scalar reference to itself' );
	# 5,000 nodes, past the 100 levels at which a recursive search would warn
	# "Deep recursion" and so die under FATAL warnings.
	my $head = { n => 0 };
	my $node = $head;
	for my $i (1 .. 5000) {
		$node->{next} = { n => $i, prev => $node };
		$node = $node->{next};
	}
	my $deep = $head;
	$deep = $deep->{next} for 1 .. 4998;
	$deep->{back_to_head} = $head;
	like( structure($head, output => 'string', color => 0, max_depth => 3), qr/prev: \(cycle\)/,
		'a 5,000-node linked list is searched for loops without recursion' );
}
is( shape([ [], [ 1, 'x' ], [ 3 ] ]), <<'END', 'arrays of different lengths merge their elements' );
ARRAY[3]
    [*]: ARRAY[0-2] (from 3 instances)
        [*]: UNION
            <number> number
            <string> string
END
is( shape([ bless({ a => 1 }, 'Foo'), { a => 2 } ]), <<'END', 'a blessed hash is not merged with a plain one' );
ARRAY[2]
    [*]: UNION
        <Foo=HASH> Foo=HASH{1}
            a: number
        <HASH> HASH{1}
            a: number
END
is( structure({ map { ("k$_" => { v => $_ }) } 1 .. 5 }, output => 'string', color => 0, hash_max => 4), <<'END', 'a hash wider than hash_max merges its values' );
HASH{5} (keys merged)
    <*>: HASH{1} (from 5 instances)
        v: number
END
is( structure({ a => { b => { c => 1 } } }, output => 'string', color => 0, max_depth => 2), <<'END', 'max_depth stops the descent' );
HASH{1}
    a: HASH{1}
        b: (...)
END

# 0.023 died with "Use of uninitialized value" from the line that read it.
ok( !eval { structure({}, output => 'string', color => undef); 1 }, 'color => undef dies' );
like( $@, qr/color must be defined/, '...with its own message' );

done_testing;
