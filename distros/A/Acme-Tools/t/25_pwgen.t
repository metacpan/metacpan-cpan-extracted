# make test
# perl Makefile.PL; make; perl -Iblib/lib t/25_pwgen.t

BEGIN{require 't/common.pl'}
use Test::More tests => 11;

sub tstr{sprintf("    (%d trials, %.5f sec)",$Acme::Tools::Pwgen_trials, $Acme::Tools::Pwgen_sec)}
#my $i=0; sub Acme::Tools::time_fp{++$i}

do{
  local $Acme::Tools::Pwgen_max_sec=0.001;
  eval{pwgen(3)}; ok($@=~/pwgen.*25_pwgen.t/,"pwgen croak works: ".trim($@));
  local $Acme::Tools::Pwgen_max_trials=3;
  eval{pwgen(3)}; ok($@=~/pwgen.*after 3 .*25_pwgen.t/,"pwgen croak works: ".trim($@));
};

ok(length(pwgen())==8, 'default len 8');

my $n=300;
$Acme::Tools::Pwgen_max_sec=1;
sub test{/^[a-z0-9]/i and /[A-Z]/ and /[a-z]/ and /\d/ and /[\,\-\.\/\&\%\_\!]/};
my @pw=grep test(), pwgen(0,$n);
ok(@pw==$n, "pwgen ok ".@pw.tstr());

$n=50;
@pw=grep/^[A-Z]{20}$/,pwgen(20,$n,'A-Z');
ok(@pw==$n, "pwgen ok ".@pw);

$n=50;
@pw=grep/^[A-Z\d]{8}$/&&!/\D\D/,pwgen(8,$n,'A-Z0-9',qr/[ABC]/,qr/\d/,sub{!/\D\D/});
ok(@pw==$n, "pwgen ok ".@pw.tstr());
print serialize(\@pw,'pw') if @pw<$n;

sub ok50{ok(@pw==50,"".(shift()||'50        ').tstr())}
@pw=grep/^\D\D\d\d$/,    map pwgen(4,1,'A-Z0-9',qr/^[A-Z]{2}\d\d$/), 1..50;    ok50("last of 50");
@pw=grep/^\D\D\d\d$/,    pwgen(4,50,'A-Z0-9',sub{/^[A-Z]{2}\d\d$/});           ok50();
@pw=grep/^[A-C]{2}\d\d$/,pwgen(4,50,'A-C0-3',qr/^[A-C]{2}\d\d$/);              ok50();
@pw=grep Acme::Tools::pwgendefreq(),grep/^[A-O]/,pwgen(8,50,'','',qr/^[A-O]/); ok50();
@pw=grep Acme::Tools::pwgendefreq(),grep!/[a-z]{3}/i,pwgen(8,50,'','',sub{!/[a-z]{3}/i}); ok50();
