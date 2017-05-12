# make test
# perl Makefile.PL; make; perl -Iblib/lib t/18_pad.t

BEGIN{require 't/common.pl'}
use Test::More tests => 20;

for(
  ['rpad','gomle',9,undef,'gomle    '],
  ['lpad','gomle',9,undef,'    gomle'],
  ['rpad','gomle',9,'-','gomle----'],
  ['lpad','gomle',9,'+','++++gomle'],
  ['rpad','gomle',4,undef,'goml'],
  ['lpad','gomle',4,undef,'goml'],
  ['rpad','gomle',7,'xyz','gomlexy'],
  ['lpad','gomle',10,'xyz','xyzxygomle'],
  ['lpad','gomle',24,'-xyz','-xyz-xyz-xyz-xyz-xygomle' ],
  ['cpad','mat',5,undef,' mat '],
  ['cpad','mat',4,undef,'mat '],
  ['cpad','mat',6,undef,' mat  '],
  ['cpad','mat',9,undef,'   mat   '],
  ['cpad','mat',5,'+','+mat+'],
  ['cpad','mat',4,'xyz','matx'],
  ['cpad','mat',5,'xyz','xmatx'],
  ['cpad','mat',6,'xyz','xmatxy'],
  ['cpad','mat',12,'xyz','xyzxmatxyzxy'],
  ['cpad','MMM',20,'xyz','xyzxyzxyMMMxyzxyzxyz'],
  ['cpad','MMMM',20,'xyzXYZ','xyzXYZxyMMMMxyzXYZxy'],
){
  my($f,$s,$l,$p,$c,$r)=@$_;
  my @a=defined$p?($s,$l,$p):($s,$l);
  ok( ($r=&$f(@a)) eq $c, sprintf "%-30s eq %-30s should be '$c'", "$f".repl(serialize(\@a),"\n"), "'$r'" );
}
