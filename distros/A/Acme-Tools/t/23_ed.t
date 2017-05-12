# make test
# perl Makefile.PL; make; perl -Iblib/lib t/23_ed.t

BEGIN{require 't/common.pl'}
use Test::More tests => 17;

sub tst {
  my($start,$cmds,$end)=@_;
  my $ed=ed($start,$cmds);
  ok($ed eq $end, $ed eq $end ? "Ok ed() -> $ed" : "Got: $ed  Expected: $end");
}
#--test sub ed
tst('','hello world', 'hello world' );
tst('','"Hello World!"', 'Hello World!' );
tst('hello world','FaDMF verdenMD', 'hallo verden' );
tst('hello world','EMBverdenMDMBMBDDha', 'hallo verden' );
tst("A.,-\nabc.",'FMD', 'A.' );
tst('hei du.','EM-', 'hei ' );
tst('d','{abc}!!', 'abcabcabcd' );
tst('Hello world','SwRBnice ','Hello nice world');
tst('Hello world','SwRild w','Hello wild world');
tst('Hello world','E\!','Hello world!');
tst('Hello','E ""world""','Hello "world"');
tst('abc','EM-YYY','abcabcabc');
tst("abc\n123",'EM-YYYD',"abcabcabc123");
tst("abc\n123",'EM-YYYK',"abcabcabc123");
tst("abc\n123",'EM-YYYKK',"abcabcabc");
tst('','M12a','aaaaaaaaaaaa');
my $s='a b c'; ok(ed(\$s,'MFMFx') eq $s and $s eq 'a bx c');
