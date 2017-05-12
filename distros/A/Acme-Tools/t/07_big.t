#perl Makefile.PL;make;perl -Iblib/lib t/07_big.t
BEGIN{require 't/common.pl'}
BEGIN{our $T=15}
use Test::More tests => $T;
eval{big(1)};
exit if $@ and print "<<$@>>\n" and map ok(1),1..$T; #Math::BigInt or Math::BigFloat is missing

my $num1 = big(3);      #returns a new Math::BigInt-object
my $num2 = big('3.0');  #returns a new Math::BigFloat-object
my $num3 = big(3.0);    #returns a new Math::BigInt-object
my $num4 = big(3.1);    #returns a new Math::BigFloat-object
my $num5 = big('2/7');  #returns a new Math::BigRat-object
my($int1,$float1,$int2,$float2) = big(3,'3.0',3.0,3.1); #returns the four new numbers, as the above four lines

ok( ref($num1) eq 'Math::BigInt',   'ref eq Math::BigInt');
ok( ref($num2) eq 'Math::BigFloat', 'ref eq Math::BigFloat');
ok( ref($num3) eq 'Math::BigInt',   'ref eq Math::BigInt');
ok( ref($num4) eq 'Math::BigFloat', 'ref eq Math::BigFloat');
ok( ref($num5) eq 'Math::BigRat',   'ref eq Math::BigRat');

ok( big(2)**200 eq "1606938044258990275541962092341162602522202993782792835301376" ,'2**200');
ok( 2**big(200) eq "1606938044258990275541962092341162602522202993782792835301376" ,'2**200');

ok( 1/big(7)   == 0 );       # 0      because of integer arithmetics
ok( 1/big(7.0) == 0 );       # 0      because of integer arithmetics

bigscale(40);                # jic default 40 differs in future
ok( 1/big('7.0') eq '0.1428571428571428571428571428571428571429' );
ok( 1/bigf(7)    eq '0.1428571428571428571428571428571428571429' );

bigscale(60);                # increase precesion from the default 40
ok( 1/bigf(7)    eq '0.142857142857142857142857142857142857142857142857142857142857' );

eval{bigscale()};    ok( $@=~/bigscale requires/ );
eval{bigscale(1,2)}; ok( $@=~/bigscale requires/ );

ok( bigr('1/41')+1 eq '42/41' ); #hm
print "".(2+bigr('1/41'))."\n";
printf "$_:   %$_   %$_   %$_   %$_\n",1/41,bigr('1/41'),2+bigr('1/41'),1/41 for qw/s e f g E F G/;

#se ~kjetilsk/test/test_pi.pl
