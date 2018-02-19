# make test
# perl Makefile.PL; make; perl -Iblib/lib t/34_tablestring.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 4;

my @tab=(
   [qw/AA BBBBB CCCC/],
   [123,23,"x1\nx22\nx333"],
   [332,23,34],
   [77,88,99],
   ["lin\nes",12,"xsdff\nxdsa\nxa"],
   [0,22,"adf"]
);
my($ok,$ts,%opt,$nr);
my $okk=sub{ ok( ($ts=tablestring(\@tab,\%opt)) eq $ok, "tablestring ".(++$nr) ) or print "ts=\n$ts\n\n\nok=\n$ok\n" };
$ok=<<'.'; &$okk;
AA  BBBBB CCCC
--- ----- ----- 
123    23 x1
          x22
          x333

332    23 34
77     88 99

lin    12 xsdff
es        xdsa
          xa

0      22 adf
.

$ok=<<'.';
AA  BBBBB CCCC
--- ----- ----- 
123 23    x1
          x22
          x333

332 23    34
77  88    99

lin 12    xsdff
es        xdsa
          xa

0   22    adf
.
$ok=~s,\n\s*\n,\n,g; $opt{left}=1; $opt{no_multiline_space}=1; &$okk;
$ok=~s,\n[- ]+\n,\n,; $opt{no_header_line}=1;                  &$okk;

@tab=map[map {s/88/23/;$_} @$_],@tab;
@tab=grep$$_[0]!~/^(123|lin)/,@tab;
$ok=~s,.*x.*\n,,g;
$ok=~s, 88 , 23 ,;    $opt{nodup}=1;                           &$okk;   #nodup not working yet
