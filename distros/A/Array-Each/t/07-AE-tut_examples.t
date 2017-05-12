#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
use Array::Each;

# Testing tutorial examples

# note: {{ }} notation used in place of indenting

{{
my %h2;

 my %h = ( a=>1, b=>2, c=>3, d=>4, e=>5 );
 while( my( $k, $v ) = each %h ) {
     # ... do something with $k and $v ...
     $h2{$k} = $v;
 }

is_deeply( \%h, \%h2, "hash" );
}}


{{
my $x = '';

 my @k = qw( a b c d e );
 my @v = qw( 1 2 3 4 5 );
 for my $i ( 0 .. $#k ) {
     my( $k, $v ) = ( $k[$i], $v[$i] );
     # ... do something with $k and $v (and maybe $i) ...
     $x .= ">$k$v$i";
 }

is( $x, ">a10>b21>c32>d43>e54", "parallel array(1)" );
}}


{{
my $x = '';

 use Array::Each;
 my @k = qw( a b c d e );
 my @v = qw( 1 2 3 4 5 );
 my $obj = Array::Each->new( \@k, \@v );
 while( my( $k, $v, $i ) = $obj->each ) {
     # ... do something with $k and $v (and maybe $i) ...
     $x .= ">$k$v$i";

 }
is( $x, ">a10>b21>c32>d43>e54", "parallel array(2)" );

$x = '';
 while( my( $k, $v ) = $obj->each ) {
     # ... do something with $k and $v ...
     $x .= ">$k$v";
 }
is( $x, ">a1>b2>c3>d4>e5", "parallel array(3)" );
}}


{{
my $x = '';

 my @k = qw( a b c d e );
 my @v = qw( 1 2 3 4 5 );
 my @p = qw( - + ~ = : ); 
 my $obj = Array::Each->new( \@k, \@v, \@p );
 while( my( $k, $v, $p, $i ) = $obj->each ) {
     # ... do something with $k, $v, and $p (and maybe $i) ...
     $x .= ">$k$v$p$i";
 }

is( $x, ">a1-0>b2+1>c3~2>d4=3>e5:4", "parallel array(4)" );
}}

{{
my $x = '';

 # pairs
 my @a = ( a=>1, b=>2, c=>3, d=>4, e=>5 );
 my $hash_like = Array::Each->new( set=>[\@a], group=>2 );
 while( my( $k, $v, $i ) = $hash_like->each ) {
     # ... do something with $k and $v ...
     # note that $i is successively, 0, 2, 4, 6, 8
     $x .= ">$k$v$i";
 }

is( $x, ">a10>b22>c34>d46>e58", "pairs" );
}}

{{
my $x = '';

 # triplets
 my @a = ( a=>1,'-', b=>2,'+', c=>3,'~', d=>4,'=', e=>5,':' );
 my $tre = Array::Each->new( set=>[\@a], group=>3 );
 while( my( $k, $v, $p, $i ) = $tre->each ) {
     # ... do something with $k, $v, and $p ...
     # note that $i is successively, 0, 3, 6, 9, 12
     $x .= ">$k$v$p$i";
 }

is( $x, ">a1-0>b2+3>c3~6>d4=9>e5:12", "triplets" );
}}

{{
my $x = '';

 # destructive    
 my @n = ( 1..20 );
 while( my @a = splice( @n, 0, 5 ) ) {
     # ... do something with @a ...
     $x .= ">@a";
 }

is( $x, ">1 2 3 4 5>6 7 8 9 10>11 12 13 14 15>16 17 18 19 20",
    "destructive splice" );
}}

{{
my $x = '';

 # non-destructive    
 my @n = ( 1..20 );
 my @n2 = @n;  # sacrificial copy
 while( my @a = splice( @n2, 0, 5 ) ) {
     # ... do something with @a ...
     $x .= ">@a";
 }

is( $x, ">1 2 3 4 5>6 7 8 9 10>11 12 13 14 15>16 17 18 19 20",
    "non-destructive splice" );
}}


{{
my $x = '';

 my @n = ( 1..20 );
 my $obj = Array::Each->new( set=>[\@n], group=>5 );
 while( my @a = $obj->each ) {
     my $i = pop @a;  # because each returns index, too
     # ... do something with @a ...
     $x .= ">@a";
 }

is( $x, ">1 2 3 4 5>6 7 8 9 10>11 12 13 14 15>16 17 18 19 20",
    "\$obj->each" );

}}

{{
my $x = '';

 my @a = ( [d=>4], a=>1, b=>2, c=>3, d=>4 );
 my $obj = Array::Each->new( set=>[\@a],
     iterator=>1, rewind=>1, group=>2 );
 while( my( $k, $v ) = $obj->each ) {
     $x .= "$k => $v\n";
 }
 push @a, @{$a[0]} = ( e=>5 );
 while( my( $k, $v ) = $obj->each ) {
     $x .= "$k => $v\n";
 }

is( $x, <<'__',
a => 1
b => 2
c => 3
d => 4
a => 1
b => 2
c => 3
d => 4
e => 5
__
    "iterator & rewind" );
}}

{{
my $x = '';

 my @a = ( 'a' .. 'm' );
 my $obj = Array::Each->new( set=>[\@a],
    group=>3, undef=>'&nbsp;', count=>1 );
 $x .= qq{<table border="1">\n};
 while( my @row = $obj->each ) {
     $x .= sprintf "<tr> <td>%d.</td> ", pop @row;
     $x .= join( '', map( "<td>$_</td> ", @row ) ) . "</tr>\n";
 }
 $x .= "</table>\n";

is( $x, <<'__',
<table border="1">
<tr> <td>1.</td> <td>a</td> <td>b</td> <td>c</td> </tr>
<tr> <td>2.</td> <td>d</td> <td>e</td> <td>f</td> </tr>
<tr> <td>3.</td> <td>g</td> <td>h</td> <td>i</td> </tr>
<tr> <td>4.</td> <td>j</td> <td>k</td> <td>l</td> </tr>
<tr> <td>5.</td> <td>m</td> <td>&nbsp;</td> <td>&nbsp;</td> </tr>
</table>
__
    "group & undef" );
}}

{{
my $x;

 my @a = ( [ 1..5 ], [ 1..8 ], [ 7..18 ], );
 my $cols = @a;    
 my $fmt = " %4d." .   " %5d" x $cols . "\n";  
 my $div = ' 'x6   . ' -----' x $cols . "\n";
 my $tot = ' 'x6   .   " %5d" x $cols . "\n";  
 my @totals;
 my $obj = Array::Each->new( set=>[@a],
     bound=>0, undef=>0, count=>1 );
 while( my @row = $obj->each ) {
     my $count = pop @row; 
     $x .= sprintf $fmt, $count, @row;
     @totals = map { $totals[$_] += $row[$_] } ( 0 .. $#row )
 }
 $x .= $div;
 $x .= sprintf $tot, @totals;                  

is( $x, <<'__',
    1.     1     1     7
    2.     2     2     8
    3.     3     3     9
    4.     4     4    10
    5.     5     5    11
    6.     0     6    12
    7.     0     7    13
    8.     0     8    14
    9.     0     0    15
   10.     0     0    16
   11.     0     0    17
   12.     0     0    18
       ----- ----- -----
          15    36   150
__
    "bound & undef" );
}}

__END__
