# make test
# perl Makefile.PL; make; perl -Iblib/lib t/21_read_conf.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 3;

my $c=<<'END';
#tester
hei: fdas #heihei
hopp: and {u dont stoppp #
#dfsa
dfsa

dsa
[section1]  #
hei:        { fds1
312321
123321}
båt: 4231\#3
bil: 213+123
sykkel: { x  }
ski: {
       staver
}

 [section2]

hei: fds1 312321 123321
bil= 213+123:2=1  #: and = are ok in values
sykkel: sdfkdsa
 [section3]
[ section2 ]
båt: 4231
END

my %c=rc(\$c);
my %s0=( hei       =>'fdas',
         hopp      =>'and {u dont stoppp' );
my %fasit=(
  %s0,#''=>\%s0,
  'section1'=>{'bil'=>'213+123',
               'båt'=>'4231#3',
               'hei'=>" fds1\cJ312321\cJ123321",
               'sykkel'=>' x  ',
	       'ski'=>"\n       staver\n",
              },
  'section2'=>{'bil'=>'213+123:2=1',
               'båt'=>'4231',
               'hei'=>'fds1 312321 123321',
               'sykkel'=>'sdfkdsa'
              },
  'section3'=>{}
);
my $t;
sub rc {$t=time_fp();my%c=read_conf(@_);$t=time_fp()-$t;%c}
sub sjekk {
  my $f=serialize(\%fasit,'c','',1);
  my $s=serialize(\%c,'c','',1);
  ok($s eq $f, sprintf("read_conf %10.6f sek (".length($s)." bytes)",$t)) or warn"s=$s\nf=$f\n";
}
sjekk(); #1

my $f=tmp()."/acme-tools.read_conf.tmp";
eval{writefile($f,$c)};$@&&ok(1)&&exit;
%c=(); rc($f,\%c);
sjekk(); #2

$Acme::Tools::Read_conf_empty_section=1; #default 0
$fasit{''}=\%s0;
%c=rc($f);
sjekk(); #3
