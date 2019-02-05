# make;perl -Iblib/lib t/42_finddup.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 13;
my $tmp;
my @f;
sub mkf {
  my $n=shift()//4;
  $tmp=tmp();
  my $str=sub{$_<4?"abcd$_":"ABCD$_"};
  @f=map{my$f="$tmp/file$_";writefile($f,&$str($_));$f}0..$n-1;
  my $t=time();
  utime 0,$t+2*$_,$f[$_] for 0..3;
}
mkf();
sub fd{Acme::Tools::cmd_finddup(@_)}
sub f{fd('-R',@_)}
sub sr{repl(srlz(@_),"$tmp/")}

my %f=f(qw(-P 4 -M -F),@f);
my $s=sr(\%f,'f');
my $s2=sr({md5sum(\"abcd")=>[map"file$_",0..3]},'f'); #print$s,$s2;
ok($s eq $s2);

my @r;
sub test{my$sr=sr(\@r,'r')=~s,\n$,,r;print "Got:      $sr\nExpected: $_[0]\n\n" if $sr ne $_[0];ok($sr eq shift)}
@r=f(qw(-P 4 -M  ),    @f[2,1,3,0]);test(q(@r=('file1','file3','file0');));
@r=f(qw(-P 4 -M -k n ),@f[2,1,3,0]);test(q(@r=('file2','file1','file0');));
@r=f(qw(-P 4 -M -k o ),@f[2,1,3,0]);test(q(@r=('file1','file2','file3');));
@r=f(                  @f         );test(q(@r=();));
@r=f(                  $tmp       );test(q(@r=();));

my $pr=sub{my@a=@_;join("",map"$_\n",map{s,$tmp/,,g;$_}split"\n",printed{Acme::Tools::cmd_finddup(@a)})};
my $p; sub okp{print "Got:    $p\nExpected: $_[0]\n" if $p ne $_[0];ok($p eq $_[0])}
$p=&$pr(qw(-k o -MP4),$tmp);      okp("file1\nfile2\nfile3\n");
$p=&$pr(qw(-k o -MP4),$tmp,$tmp); okp("file1\nfile2\nfile3\n");
$p=&$pr('-MP4',  @f); okp("file1\nfile2\nfile3\n");                                      mkf(8);
$p=&$pr('-aMP4', @f); okp("file0\nfile1\nfile2\nfile3\n\nfile4\nfile5\nfile6\nfile7\n"); mkf();
$p=&$pr('-dnMP4',@f); okp(qq(rm "file1"\nrm "file2"\nrm "file3"\n));
$p=&$pr('-snMP4',@f); okp(qq(ln -s "file0" "file1"\nln -s "file0" "file2"\nln -s "file0" "file3"\n));
$p=&$pr('-hnMP4',@f); okp(qq(ln    "file0" "file1"\nln    "file0" "file2"\nln    "file0" "file3"\n));

#if($^O ne 'linux'){ok(1) for 1..x; exit }
#fd('-sMP4',@f); print qx(find $tmp -ls); mkf();
#fd('-hMP4',@f); print qx(find $tmp -ls); mkf();
#fd('-dMP4',@f); print qx(find $tmp -ls); mkf();

#todo: more tests wo -P 4 and -M
