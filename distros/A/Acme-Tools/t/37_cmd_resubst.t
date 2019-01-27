# make test
# perl Makefile.PL; make; perl -Iblib/lib t/37_cmd_resubst.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 2;
my $gzip=(grep -x$_, '/bin/gzip', '/usr/bin/gzip')[0];
SKIP:{
skip "- no cmd_due for $^O (only linux and cygwin)", 2 if $^O!~/^(linux|cygwin)$/;
skip "- gzip not found", 2                             if !$gzip;
skip "- md5 not found", 2                              if !eval('require Digest::MD5');
my($tmp,$seed,$n)=(tmp(),1234,15);
writefile("$tmp/$_",join("",map{"$_ ".rnd()."\n"}1..10)) for 1..$n;
sub rnd { Digest::MD5::md5_hex($seed++) }
sub test {
  my($n,$ok,@a)=@_;
  my $p=printed{eval{Acme::Tools::cmd_resubst(@a)}};
  if($@=~/not found/){ok(1);return} #if missing bzip2
  $p=~s,\s\S*/tmp/\S*/([^\/\s]+), /tmp/x/$1,g;
  is($p, $ok, "test $n");
}
test(1,<<".",'-v','-f','e',map"$tmp/$_",1..$n);
 1/15 10/10               351 =>     341 b (97%) /tmp/x/1
 2/15 19/9                351 =>     342 b (97%) /tmp/x/2
 3/15 27/8                351 =>     343 b (97%) /tmp/x/3
 4/15 36/9                351 =>     342 b (97%) /tmp/x/4
 5/15 44/8                351 =>     343 b (97%) /tmp/x/5
 6/15 52/8                351 =>     343 b (97%) /tmp/x/6
 7/15 60/8                351 =>     343 b (97%) /tmp/x/7
 8/15 68/8                351 =>     343 b (97%) /tmp/x/8
 9/15 77/9                351 =>     342 b (97%) /tmp/x/9
10/15 86/9                351 =>     342 b (97%) /tmp/x/10
11/15 95/9                351 =>     342 b (97%) /tmp/x/11
12/15 105/10              351 =>     341 b (97%) /tmp/x/12
13/15 113/8               351 =>     343 b (97%) /tmp/x/13
14/15 121/8               351 =>     343 b (97%) /tmp/x/14
15/15 128/7               351 =>     344 b (98%) /tmp/x/15
Replaces: 128  Bytes before: 5265  After: 5137   Change: -2.4%
.
qx($gzip $tmp/*);
test(2,<<".",'-o','bz2','-9','-v','-f','f',map"$tmp/$_.gz",1..$n);
 1/15 8/8                 225 =>     237 b (105%) /tmp/x/1.gz
 2/15 17/9                226 =>     232 b (102%) /tmp/x/2.gz
 3/15 26/9                226 =>     235 b (103%) /tmp/x/3.gz
 4/15 34/8                227 =>     232 b (102%) /tmp/x/4.gz
 5/15 42/8                226 =>     235 b (103%) /tmp/x/5.gz
 6/15 48/6                225 =>     239 b (106%) /tmp/x/6.gz
 7/15 57/9                225 =>     235 b (104%) /tmp/x/7.gz
 8/15 64/7                225 =>     236 b (104%) /tmp/x/8.gz
 9/15 74/10               227 =>     232 b (102%) /tmp/x/9.gz
10/15 84/10               227 =>     236 b (103%) /tmp/x/10.gz
11/15 94/10               227 =>     234 b (103%) /tmp/x/11.gz
12/15 101/7               224 =>     236 b (105%) /tmp/x/12.gz
13/15 109/8               227 =>     233 b (102%) /tmp/x/13.gz
14/15 117/8               228 =>     234 b (102%) /tmp/x/14.gz
15/15 125/8               228 =>     236 b (103%) /tmp/x/15.gz
Replaces: 125  Bytes before: 3393  After: 3522   Change: 3.8%
.
}
