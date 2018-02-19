# make test
# perl Makefile.PL; make; perl -Iblib/lib t/28_wipe.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 3;
if($^O eq 'linux'){
  my $f=tmp().'/acme-tools.wipe.tmp';
  writefile($f,join(" ",map rand(),1..1000)); #system("ls -l $f");
  my $ntrp=sub{length(gz(readfile($f).""))};
  my $n=&$ntrp;
  wipe($f,undef,1);
  my $ratio=$n/&$ntrp;
  ok($ratio>50 || !$INC{'Compress/Zlib.pm'}, "ratio $ratio > 50");
  ok(-s$f>5e3);
  wipe($f,1);
  ok(!-e$f);
}
else{ ok(1) for 1..3 }
