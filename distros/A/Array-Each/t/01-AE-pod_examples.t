#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
use Array::Each;

# note, {{ }} convention used in place of indenting

{{
my $obj = Array::Each->new();

ok( defined $obj, "new() returned something" );
ok( $obj->isa('Array::Each'), "... and it's the right class" );
}}

{{
### test examples in POD
my @t;

# one array
my @x = qw( a b c d e );

my $one = Array::Each->new( \@x );
while( my( $x, $i ) = $one->each() ) {
    push @t, sprintf "%3d: %s\n", $i, $x;
}

is( (join'',@t), <<'__',
  0: a
  1: b
  2: c
  3: d
  4: e
__
    "one array" );
}}

{{
my @t;
my @x = qw( a b c d e );

# multiple arrays
my @y = ( 1,2,3,4,5 );

my $set = Array::Each->new( \@x, \@y );
while( my( $x, $y, $i ) = $set->each() ) {
    push @t, sprintf "%3d: %s %s\n", $i, $x, $y;
}

is( (join'',@t), <<'__',
  0: a 1
  1: b 2
  2: c 3
  3: d 4
  4: e 5
__
    "multiple arrays" );
}}

{{
my @t;

# groups of elements (note set=> parm syntax)
my @z = ( a=>1, b=>2, c=>3, d=>4, e=>5 );

my $hash_like = Array::Each->new( set=>[\@z], group=>2 );
while( my( $key, $val ) = $hash_like->each() ) {
    push @t, sprintf "%s => %s\n", $key, $val;
}

is( (join'',@t), <<'__',
a => 1
b => 2
c => 3
d => 4
e => 5
__
    "groups of elements" );
}}

{{
my @t;

push @t, "@$_\n" for permute( [1..5] );
is( (join'',@t), <<'__',
1 2
1 3
1 4
1 5
2 3
2 4
2 5
3 4
3 5
4 5
__
    "permute" );

sub permute {
    my $set1 = Array::Each->new( @_ );
    my @permutations;
    while ( my @s1 = $set1->each() ) {
        my $set2 = $set1->copy();
        while ( my @s2 = $set2->each() ) {
            # -1 because each() returns array index, too
            push @permutations,
                [ @s1[0..$#s1-1], @s2[0..$#s2-1] ];
        }
    }
    return @permutations
}
}}

{{
my @t;
my @x = qw( a b c d e );

my $obj = Array::Each->new( \@x );
while( defined( my $i = $obj->each() ) ) {
    push @t, sprintf "%3d\n", $i;
}
is( (join'',@t), <<'__',
  0
  1
  2
  3
  4
__
    "scalar each()" );
}}

{{
my $obj = Array::Each->new();  # iterator == 0
my $amount = 10;
$obj->set_iterator( $obj->get_iterator() + $amount );
is( $obj->get_iterator(), 10, "incr iterator by amount" );
}}

{{
my @x = qw( a b c d e );
my @y = ( 1,2,3,4,5 );
my $obj = Array::Each->new();
my @array_refs = $obj->set_set( \@x, \@y );
my $num = $obj->set_set( @array_refs );
is( "@array_refs", "@{[\@x,\@y]}", "set_set return (1)");
is( $num, 2, "set_set return (2)");
}}

{{
my @x = qw( a b c d e );
my @y = ( 1,2,3,4,5 );
my $obj = Array::Each->new( set=>[\@x, \@y], group=>5, stop=>99, bound=>0 );
my @a = $obj->each;
my $i = $obj->get_iterator;

is( @a, 11, "group (1)" );
is( $i, 5, "group (2)" );
is( "@a", "a b c d e 1 2 3 4 5 0", "group (3)" );
}}

__END__
