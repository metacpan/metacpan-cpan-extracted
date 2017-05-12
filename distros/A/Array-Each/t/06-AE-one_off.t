#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 16;
use Array::Each;

# go: create a test string
use constant NOWARN=>0;
sub go {
    my( $obj, $n, $warn ) = @_;
    $n ||= 1;  # num loops
    $warn = defined $warn ? $warn : 1;
    local $" = '';
    my $r = '';
    if( $warn ) {
        for(1..$n){while(my(@a)=$obj->each){$r.=">@a"}}}
    else { no warnings 'uninitialized';
        for(1..$n){while(my(@a)=$obj->each){$r.=">@a"}}}
    $r;
}

# Testing one-off cases for iterator, rewind, group, stop

my @x = qw( a b c d e );
my @y = ( 1..9 );
my $obj;

$obj = Array::Each->new( set=>[\@x, \@y], bound=>0 );

my $maxi = $obj->set_iterator( @x > @y ? $#x : $#y );
is( go($obj,1,NOWARN),
    '>98',
    "iterator at end" );

$obj->set_iterator( $maxi-1 );
is( go($obj,1,NOWARN),
    '>87>98',
    "iterator before end" );

$obj->set_iterator( $maxi+1 );
is( go($obj,1,NOWARN),
    '',
    "iterator past end" );

$obj->set_iterator( $maxi+1 );
is( go($obj,2,NOWARN),
    '>a10>b21>c32>d43>e54>65>76>87>98',
    "iterator past end, but rewound to 0" );

$obj->set_rewind( $obj->set_iterator( $maxi ) );
is( go($obj,2,NOWARN),
    '>98>98',
    "iterator and rewind at end" );

$obj->set_rewind( $obj->set_iterator( $maxi-1 ) );
is( go($obj,2,NOWARN),
    '>87>98>87>98',
    "iterator and rewind before end" );

$obj->set_rewind( $obj->set_iterator( $maxi+1 ) );
is( go($obj,2,NOWARN),
    '',
    "iterator and rewind past end" );

$obj = Array::Each->new( set=>[\@x, \@y], bound=>0 );
my $maxsz = $obj->set_group( @x > @y ? @x+0 : @y+0 );
is( go($obj,2,NOWARN),
    '>abcde1234567890>abcde1234567890',
    "group same size as largest array" );

$obj->set_group( $maxsz-1 );
is( go($obj,2,NOWARN),
    '>abcde123456780>98>abcde123456780>98',
    "group smaller than largest array" );

$obj->set_group( $maxsz+1 );
is( go($obj,2,NOWARN),
    '>abcde1234567890>abcde1234567890',
    "group larger than largest array" );

$obj = Array::Each->new( set=>[\@x, \@y] );
my $mini = $obj->set_stop( @x < @y ? $#x : $#y );
is( go($obj,2),
    '>a10>b21>c32>d43>e54>a10>b21>c32>d43>e54',
    "stop at end of smallest array" );

$obj->set_stop( $mini-1 );
is( go($obj,2),
    '>a10>b21>c32>d43>a10>b21>c32>d43',
    "stop before end of smallest array" );

$obj->set_stop( $mini+1 );
is( go($obj,2),
    '>a10>b21>c32>d43>e54>a10>b21>c32>d43>e54',
    "stop past end of smallest array" );

$obj = Array::Each->new( set=>[\@x, \@y], bound=>0, undef=>'_' );
$obj->set_stop( $maxi );
is( go($obj,1),
    '>a10>b21>c32>d43>e54>_65>_76>_87>_98',
    "stop at end of largest array" );

$obj->set_stop( $maxi-1 );
is( go($obj,1),
    '>a10>b21>c32>d43>e54>_65>_76>_87',
    "stop before end of largest array" );

$obj->set_stop( $maxi+1 );
is( go($obj,1),
    '>a10>b21>c32>d43>e54>_65>_76>_87>_98>__9',
    "stop past end of largest array" );

__END__
