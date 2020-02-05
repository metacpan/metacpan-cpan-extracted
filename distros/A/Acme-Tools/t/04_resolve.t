# perl Makefile.PL && make && perl -Iblib/lib t/04_resolve.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 17;

if($ENV{ATDEBUG}){
  deb "Resolve: ".resolve(sub{my($x)=(@_); $x**2 - 4*$x -1},20,2)."\n";
  deb "Resolve: ".resolve(sub{my($x)=@_; $x**log($x)-$x},0,3)."\n";
  deb "Resolve: ".resolve(sub{$_[0]})." iters=$Acme::Tools::Resolve_iterations\n";
}

my $e;
ok(resolve(sub{my($x)=@_; $x**2 - 4*$x -21})      == -3   ,'first solution');
ok(($e=resolve(sub{ $_**2 - 4*$_ - 21 }))         == -3   ,"first solution with \$_ (=$e)");
ok(resolve(sub{$_**2 - 4*$_ -21},0,3)             == 7    ,'second solution, start 3');
ok(resolve(sub{my($x)=@_; $x**2 - 4*$x -21},0,2)  == 7    ,'second solution, start 2');
my $f=sub{ $_**2 - 4*$_ - 21 };
ok(do{my$r=resolve($f,0,2);                     $r== 7}   ,'second solution, start 2');
ok(resolve($f,0,2)                                == 7    ,'second solution, start 2');
ok(resolve($f,0,2)                                == 7    ,'second solution, start 2');
ok($Resolve_iterations                            >  1    ,"iterations=$Resolve_iterations");
ok($Resolve_last_estimate                         == 7    ,"last_estimate=$Resolve_last_estimate (should be 7)");
eval{  resolve(sub{1}) };  # 1=0
ok($@=~/Div by zero/);
ok(!defined $Resolve_iterations);
ok(!defined $Resolve_last_estimate);

my $c;
eval{$e=resolve(sub{$c++; sleep_fp(0.02); $_**2 - 4*$_ -21},0,.02,undef,undef,0.05)};
deb "x=$e, est=$Resolve_last_estimate, iters=$Resolve_iterations, time=$Resolve_time, c=$c -- $@\n";
ok($@=~/Could not resolve, perhaps too little time given/,'ok $@');

my$no=0;sub isr{is( ($e=$_[0]), $_[1], "r".(++$no).": e=$e, iters=$Resolve_iterations")}
isr( sprintf("%.12f",resolve(sub{3*$_ + $_**4 - 12})), '1.632498783713' ); #*)
isr( log(resolve(sub{ $_**log($_)-$_},0,2)), 1);
isr( resolve(sub{$_**2+7*$_-60},0,1),        5);
isr( resolve_equation("x^2+7x-60"),          5);

#*) http://www.quickmath.com/webMathematica3/quickmath/equations/solve/basic.jsp#c=solve_stepssolveequation&v1=3x%2Bx%5E4-12%3D0&v2=x
