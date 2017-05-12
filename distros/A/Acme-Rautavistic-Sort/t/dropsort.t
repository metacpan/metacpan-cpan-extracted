#!perl -T

use strict;
use warnings;

use Test::More tests => 28;
use Acme::Rautavistic::Sort ':all';

# plan tests => 11;

is_deeply([ dropsort(qw(3 2 3 1 5)) ], [ qw( 3 3 5) ], "double elements");
is_deeply([ dropsort(qw(3 1 2 )) ], [ qw( 3 ) ], "from very high to small, then a bit higher again");
is_deeply([ dropsort(qw(0 0 )) ], [ qw( 0 0 ) ], "0 is true");
is_deeply([ dropsort(qw(ultimate zomtec ultimate )) ], [ qw( ultimate zomtec ) ], 'alpha sort');

is_deeply([ dropsort(undef, undef) ], [ undef, undef ], 'undefs are valid');
is_deeply([ dropsort(undef, 1, undef ) ], [ undef, 1 ], 'undef lt 1' );
is_deeply([ dropsort(undef, 0, undef ) ], [ undef, 0 ], 'undef lt 0' );
is_deeply([ dropsort(undef, 1, undef, 2 ) ], [ undef, 1, 2 ], 'multiple undefs in ascending line');
is_deeply([ dropsort(undef, 1, undef, 0 ) ], [ undef, 1 ], 'multiple undefs in descending line' );
is_deeply([ dropsort(undef, 1, 2 ) ], [ undef, 1, 2 ], 'undef, 1, 2' );
is_deeply([ dropsort(undef, 2, 1 ) ], [ undef, 2 ], 'undef lt 2, 2 gt 1');
is_deeply([ dropsort(undef, 'zaffe', undef ) ], [ undef, 'zaffe' ], 'undef lt alpha text');

is_deeply([ dropsort(qw(3 2 4 1 5)) ], [ qw( 3 4 5) ], 'yet another line');
is_deeply([ dropsort(qw(3 4 5 6 7 8)) ], [ qw(3 4 5 6 7 8) ], 'already sorted');
is_deeply([ dropsort(qw(9 8 7 6 5 4)) ], [ qw(9 ) ], 'already reverse sorted');
is_deeply([ dropsort(qw(2)) ], [ qw(2) ], 'single value');
is_deeply([ dropsort() ], [ ], 'empty list');

is_deeply([ dropsort(qw(cc bb dd aa ee))], [qw(cc dd ee) ], 'alpha sort' );
is_deeply([ dropsort(qw(aa bb cc dd ee ff)) ], [ qw(aa bb cc dd ee ff) ], 'already sorted alpha' );
is_deeply([ dropsort(qw(ii hh gg ff ee dd)) ], [ qw(ii) ], 'already reverse sorted alpha' );
is_deeply([ dropsort(qw(bb)) ], [ qw(bb) ], 'single alpha' );

is_deeply([dropsort (undef, 1, 2, 5, 3, 4)], [ undef, 1, 2, 5 ], 'undef, the leader');
is_deeply([dropsort (1, 2, 5, 3, 4, undef)], [ 1, 2, 5 ], 'undef does not follow');
is_deeply([dropsort (1, 2, undef, 5, 3, 4, undef)], [ 1, 2, 5 ], 'undef in the middle attack');
is_deeply([undef], [ undef ], 'single undef');

#no warnings;

no warnings 'uninitialized';
my @res = dropsortx { $a <=> $b } 1, 11, 2;
is_deeply(\@res, [ 1, 11 ], 'numeric' ); # sic!, we are *drop* sort ...
@res = dropsortx { $a cmp $b } 1, 11, 2;
is_deeply(\@res, [ 1, 11, 2 ], 'explicitely alpha numeric' );
@res = dropsort 1, 11, 2;
is_deeply(\@res, [ 1, 11, 2 ], 'default alpha numeric' );

# -------------- Benchmarks -----------------------

__END__

# use Benchmark qw(:all) ;

# my @bigarray = map { rand } 1..30_000;
# print "Anzahl: ", (scalar dropsort5 @bigarray), "\n";
# timethese(200, {
#                 'dropsort1' => sub { dropsort1 @bigarray },
#                 'dropsort2' => sub { dropsort2 @bigarray },
#                 'dropsort3' => sub { dropsort3 @bigarray },
#                 'dropsort4' => sub { dropsort4 @bigarray },
#                 'dropsort5' => sub { dropsort5 @bigarray },
#                 'dropsortx' => sub { dropsortx @bigarray },
#                });
