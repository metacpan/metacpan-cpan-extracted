# make test
# perl Makefile.PL; make; perl -Iblib/lib t/30_cnttbl.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 2;

#---------- test 1
my $tbl=cnttbl({Norway=>5214890,Sweden=>9845155,Denmark=>5699220,Finland=>5496907,Iceland=>331310});
#print $tbl;
ok($tbl eq <<"END");
Iceland   331310   1.25%
Norway   5214890  19.61%
Finland  5496907  20.67%
Denmark  5699220  21.44%
Sweden   9845155  37.03%
SUM     26587482 100.00%
END

#---------- test 2
my %sales=(
  Toyota=>{Prius=>19,RAV=>12,Auris=>18,Avensis=>7},
  Volvo=>{V40=>14, XC90=>4},
  Nissan=>{Leaf=>19,Qashqai=>17},
  Tesla=>{ModelS=>8}
);
#exit;#todo
#print cnttbl(\%sales);
ok(cnttbl(\%sales) eq <<"END");
Nissan Qashqai 17  47.22%
Nissan Leaf    19  52.78%
Nissan SUM     36 100.00%
Tesla  ModelS 8 100.00%
Tesla  SUM    8 100.00%
Toyota Avensis  7  12.50%
Toyota RAV     12  21.43%
Toyota Auris   18  32.14%
Toyota Prius   19  33.93%
Toyota SUM     56 100.00%
Volvo  XC90  4  22.22%
Volvo  V40  14  77.78%
Volvo  SUM  18 100.00%
END
