# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::Simple tests => 3;
use Attribute::Curried;
ok(1, 'loaded');

sub add :Curry(2) {
    $_[0] + $_[1]
}

*add2 = add(2);
my @ans = map { add2($_) } 1..3;
ok( $ans[0] == 3 && $ans[1] == 4 && $ans[2] == 5, "(@ans)" );

sub bracket :Curry(3) {
    join '', @_[1,0,2];
}

sub flip :Curry(3) {
    $_[0]->(@_[2,1]);
}

my @xs = map { bracket $_ } 1..3;
my $i = 0;
my @ys = map { ++$i == 2 ? $_ : flip $_ } @xs;
my $res = join('', map { $_->('<', '>') } @ys);

ok( $res eq '>1<<2>>3<', $res );
