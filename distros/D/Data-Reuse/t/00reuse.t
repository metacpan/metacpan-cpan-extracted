
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 60;
use strict;
use warnings;
 
# the module we need
use Data::Reuse qw( alias reuse );

# need to do dumps for checks
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deepcopy = 1;

sub is_ro { ok( Internals::SvREADONLY( $_[0] ), $_[1] ) } #is_ro

# undef values
reuse my $undef = \undef;
is( undef, $$undef );
is( \reuse( undef ),
    \reuse( undef ) );
is_ro( reuse( undef ) );

# scalar values
is( 1, reuse( 1 ) );
is( \reuse( 1 ),
    \reuse( 1 ) );
is_ro( reuse( 1 ) );

# scalar refs
is( 2, ${ reuse( \2 ) } );
is( \reuse( \2 ),
    \reuse( \2 ) );
is_ro( ${ reuse( \2 ) } );

# lists
reuse my @list = ( 3, 4 );
is( '3x4', join 'x', @list );
is( \reuse( 3 ), \$list[0] );
is( \reuse( 4 ), \$list[1] );
is_ro( $list[0] );
is_ro( $list[1] );
eval { $list[2] = 3 };
ok( !$@ );

# reuse list itself
reuse \@list;
eval { $list[3] = 4 };
like( $@, qr#^Modification of a read-only value attempted at# );

# list refs
reuse my $listref = [ 3, 4 ];
TODO: {
    local $TODO = "not sure why this doesn't work";
    is( \@{$listref}, \@list );
};
is( '3x4', join 'x', @{$listref} );
is( \reuse( 3 ), \$listref->[0] );
is( \reuse( 4 ), \$listref->[1] );
is( \reuse( [ 3, 4 ] ),
    \reuse( [ 3, 4 ] ) );
is_ro( reuse( [ 3, 4 ] )->[0] );
is_ro( reuse( [ 3, 4 ] )->[1] );
eval { $listref->[2] = 5 };
like( $@, qr#^Modification of a read-only value attempted at# );

# anonymous list refs
is( '3x4', join 'x', @{ reuse( [ 3, 4 ] ) } );
is( \reuse( [ 3, 4 ] ),
    \reuse( [ 3, 4 ] ) );
is_ro( reuse( [ 3, 4 ] )->[0] );
is_ro( reuse( [ 3, 4 ] )->[1] );

# hash refs
reuse my $hashref = { five => 5, six => 6 };
is( '5x6', join 'x', @$hashref{ qw(five six) } );
is( \reuse( 5 ), \$hashref->{five} );
is( \reuse( 6 ), \$hashref->{six} );
is( \reuse( { five => 5, six => 6 } ),
    \reuse( { five => 5, six => 6 } ) );
is( \reuse( { five => 5, six => 6 } ),
    \reuse( { six => 6, five => 5 } ) );
eval { $hashref->{seven} = 8 };
like( $@, qr#^Attempt to access disallowed key 'seven' in a restricted hash at# );

# possible mixups
isnt( \reuse( \1 ),
      \reuse( [1] ) );
isnt( \reuse( { one => 1, two => 2 } ),
      \reuse( [ one => 1, two => 2 ] ) );

# circular refs
my $foo = [];
my $bar = [$foo];
$foo->[0] = $bar;
eval {
    local $SIG{__WARN__} = sub { die "Too deep" };
    reuse $foo;
};
ok( !$@ );

# multilevel structures
reuse my $a123 = [ 1, [ 2, { three => 3 } ] ];
reuse my $b123 = [ 1, [ 2, { three => 3 } ] ];
isnt( $a123, $b123 );
is( Dumper($a123), Dumper($b123) );
my $z1= \reuse( [ 1, [ 2, { three => 3 } ] ] );
my $z2= \reuse( [ 1, [ 2, { three => 3 } ] ] );
is( $z1, $z2 );
is( Dumper($z1), Dumper($z2) );

my @x;
@x = ( 1, [ 1, \@x ] );
is( Dumper( \@x ), Dumper( reuse( \@x ) ) );
is( $x[0], $x[1]->[0] );
is( \$x[0], \$x[1]->[0] );

my @y;
@y = ( 1, [ 1, [ 1, \@y ] ] );
is( Dumper( \@y ), Dumper( reuse( \@y ) ) );
is( $y[0], $y[1]->[0] );
is( \$y[0], \$y[1]->[0] );
is( $y[0], $y[1]->[1]->[0] );
is( \$y[0], \$y[1]->[1]->[0] );

# common idioms
my @foo;
push    @foo, reuse [ 1 ];
unshift @foo, reuse [ 1 ];
isnt( \$foo[0], \$foo[1] );
is( \$foo[0]->[0], \$foo[1]->[0] );

my @list1 = ( 41, 42 );
my @list2 = ( 42, 41 );
isnt( \$list1[0], \$list2[1] );
isnt( \$list1[1], \$list2[0] );
reuse \@list1, \@list2;
is( \$list1[0], \$list2[1] );
is( \$list1[1], \$list2[0] );

reuse my $list1 = [ 41, 42 ];
reuse my $list2 = [ 42, 41 ];
isnt( \$list1, \$list2 );
is( \$list1->[0], \$list2->[1] );
is( \$list1->[1], \$list2->[0] );

alias my @list3 = reuse ( 51, 52 );
alias my @list4 = reuse ( 52, 51 );
is( \$list3[0], \$list4[1] );
is( \$list3[1], \$list4[0] );
