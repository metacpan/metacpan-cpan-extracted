# make;perl -Iblib/lib t/43_egrep.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 5;
my(@a,@r);
sub okk{ is(join(', ',@r),shift,shift) }

@a = 1..20;
@r = egrep { $_ % 3 == 0 } @a;   # grep is sufficient for this
okk('3, 6, 9, 12, 15, 18');

@a=2..44;
@r = egrep { $prev =~/4$/ or $next =~/2$/ } @a; okk('5, 11, 15, 21, 25, 31, 35, 41');
@r = egrep { $prevr=~/4$/ or $nextr=~/2$/ } @a; okk('2, 5, 11, 15, 21, 25, 31, 35, 41, 44');

@r = egrep { $i%7==0 } @a; okk('2, 9, 16, 23, 30, 37, 44');
@r = egrep { $n%7==0 } @a; okk('8, 15, 22, 29, 36, 43');
