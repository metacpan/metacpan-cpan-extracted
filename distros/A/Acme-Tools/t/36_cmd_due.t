# make test
# perl Makefile.PL; make; perl -Iblib/lib t/36_cmd_due.t
# perl Makefile.PL; make; ATDEBUG=1 perl -Iblib/lib t/36_cmd_due.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests    => 6;
use Time::Local;
warn <<"" and map ok(1),1..6 and exit if $^O!~/^(linux|cygwin)$/;
Tests for cmd_due not available for $^O, only linux and cygwin

my($tmp,$p,$ok,@d)=(tmp());
sub okk{ is($p, $ok, shift); $p eq $ok or deb "$p\n!=\n$ok\n"};

my %f=( a=>10, b=>20, c=>30 );
my $i=1;
$Acme::Tools::Magic_openstr=0;
for my $ext (qw( .gz .xz .txt .doc .doc.gz),""){
  writefile("$tmp/$_$ext","x" x ($f{$_}*$i++)) for sort(keys%f);
}
#print qx(find $tmp -ls),"\n" if $ENV{ATDEBUG}; #!deb()
$p=printed { Acme::Tools::cmd_due('-Mihz',$tmp) };
my $answer=<<'';
.gz               3          140 B    3.95%  ymd ymd ymd
.xz               3          320 B    9.04%  ymd ymd ymd
.txt              3          500 B   14.12%  ymd ymd ymd
.doc              3          680 B   19.21%  ymd ymd ymd
.doc.gz           3          860 B   24.29%  ymd ymd ymd
                  3        1.02 kB   29.38%  ymd ymd ymd
Sum              18        3.46 kB  100.00%  ymd ymd ymd

$ok=repl($answer,'ymd',tms('YYYY/MM/DD'));
okk('due -Mihz');

@Acme::Tools::Due_fake_stdin=split"\n",gunzip(unbase64(<<''));
H4sIAOY951kCA72ayXKjSBCG7/0U3Dsk1b5c+jhPMHOewAJk3CwKwNvbTyFkulJST5CpFg45wtiyP/7cs3CScG0NZyI5fagk
694/us34Cpc66dp2OP1k/uL0NuZN8pI22yQxSSIYt8muPQ6797LJN/2QHsrmsOuf0y7ffUvOBHmTYO4n1GkzQ9RNiPwjkF3R
bf/5+6+Nm2n6Jk38Wdp4wc9I8SXQJZvufdNtxle45L9DcsmT9NiV1XiXI9MsZ57e1OfdW95t+azZnP4wF4tugDPn1H03sP2l
XWLQiTeK3Yeu059Aun1kcB2ri+ByjwyuL1ocXJx5nG+9sxgDAyb0LefskWrjDOIclUFaaYMRedaWVVHczmViEZEr7QnEJj+m
w3NENShq4pwhUffF4RdUSBRUGudI0IuqJM7JEn59UeQqaRSJmz1FYjnOwtJqjYbWfZl/5PvIwgIVvo5bjlfaRUAucHHkLc2l
+7bp2youCRxX7pXUJHAkVeESVVhJIj6FvxJRPc7A1tMMXJSRdYVgOK3GCzS1yw95VsZSLQ7KNKNA+7dOiqg44AysGCfU3zrO
0TOQJdXYzE6v//NoCF5ayhyPW55sfiTjxWEf34Fb5w4O37//7g5wbVYpRms/AMosMpU4I0FrWDZwc6mTilY24DgqziPTYqzR
NLHZa32MqBprYnxkNe0QhpksguLau5aaViKfXssqizqQeOTAn+Vw4OfykSPwFw3MwgLnTOkFqsUC5s1t8txxF/d4rcV9NxAV
KCyaufvQF9ukfNh+lx6PVblPhzJMVDMN1wO5lIuLRYybbJzl/c+hPX6xFXtUGo3fmim4hmMQDWf81q76t2yGattUs03VwxL2
BCzaZphZWuPUhd9BqTvBdn3Iz7Io8m24nFV6XCPXXFDIdVpV+RCDrV1D8tsh7T/7Qwx2U7yKZbkS+vDyc6YrW4eKEJENw0m2
gkIOXx6y8LkdhmImy5W8nHOhLYgvtZabL8neTYMnW0BWOuwiJD/X/edzbGmvUbOMsExRLD3FNQhrbIF0jJxPIJH15GGxDCwM
E46i+LN+aitg6XMes2WWdoaax2NMa6DYIU2tHD2mY7KYnuNwuWiq4VJxRyGnXZkCU1tcUCtBwgZTF0GwAVGNfCDiSYVr3752
oCsavxL2ql56s5pg0BUtTnEYOSl1uk67MAYMUWwJxqaYWdSOx6NdTRE8pM9tnYLyYVd0MSgfTmAKV8h55ugDCJy5kD2CMWqP
cFaBfLI4yUwKeq0G+aTNevMtUIwrXFYaiqlfrucA71H5ZLkl5VNZ5z1oEWKNuWd/rVdppINJhp4cDKZ5hz21EvQ0LmCtZiuW
LtiOkV3CGUUeMqGx9WptEa5suFFP09I4CC7KDzDoYc/XvSFHNahbTiJbBNnDl7GlDC6flBX0fAJt0WAb8h1kYGyrUJKld4o+
V4MZRCFPX2gN+eUqsLnH9YnTAQLZy7CEGNy+6Knkq6qpcf94w4W6Y+ADAabFiuc+QLNXU8iaZZuqpeXUNNY/ZfEkorEHiyTN
NwYvjqtfWt5xhgucLFfrjfDgh+Gql6QeWhcX24Rd8zQTnvxw5B7D6T6G+7mX53+4XJRPzCnjiE4G58Z8ve0JyDXItY12mvly
Y29DPokxzJGrB5wF1lonissV2dnV6gdUbNYo1M83VkaHmwTIWZxfFC4lpidPi8BCibG0Y8Cnx7NlU3z7D43Aan/3LwAA

eval { Acme::Tools::cmd_due('-ihz',$tmp) };
ok($@ eq "due: can not combine STDIN and args\n", 'ok die');

$p=printed { Acme::Tools::cmd_due('-ihz') };
$ok=<<"";
.desktop          1        1.30 kB    0.02%
.nls              1        6.26 kB    0.10%
.1               27      150.23 kB    2.52%
.inf              1      236.48 kB    3.97%
.fon             50      471.83 kB    7.92%
.ttf              9        4.97 MB   85.46%
Sum              89        5.82 MB  100.00%

okk('find -ls|due -ihz');

my @f;File::Find::find(sub{-f$_&&push@f,"$tmp/$_"},$tmp);
@Acme::Tools::Due_fake_stdin=@f;

SKIP: {
#  skip "",3 if join('',(localtime(8e8))[3..5]) ne '9495'
#            or join('',(localtime(9e8))[3..5]) ne '9698'; #tz?
  my $cnt=0;$cnt+=
  utime 0, .5<rand()?timelocal(0,0,0,9,5-1,1995)
                    :timelocal(0,0,0,9,7-1,1998), $_ for @f;
  skip "cnt $cnt != ".@f, 3 if $cnt != 0+@f;		   
  $ok=repl($answer,'ymd','1998/07/09');
  $p=printed { Acme::Tools::cmd_due('-Mihz') };
  print "--\n$p" if $ENV{ATDEBUG};
  $p=~s{\b(\d{4}/\d\d/\d\d)\b}{push@d,$1;'1998/07/09'}ge;
  print "--\n$p" if $ENV{ATDEBUG};
  is(mins(@d),'1995/05/09','min');
  is(maxs(@d),'1998/07/09','max');
  okk('find|due -Mihz  ...with -M');
};
