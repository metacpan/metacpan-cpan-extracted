# make test
# perl Makefile.PL; make; perl -Iblib/lib t/26_openstr.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 16;
#if( $^O =~ /linux/i ) {  plan tests    => 16                 }
#else                  {  plan skip_all => 'skips, not linux' }

sub tst {
  my($s,$f)=@_;
  my $o=eval{openstr($s)};
  if($@=~/(\w+ not found)/){ok(1,$1);return}
  $o=~s,/\S+/,,g;
  ok($o eq $f, "$s --> $f  (is $o)");
}
for(1..2){
  tst( "fil.txt", "fil.txt" );
  tst( "fil.gz", "zcat fil.gz |" );
  tst( "fil.bz2", "bzcat fil.bz2 |" );
  tst( "fil.xz", "xzcat fil.xz |" );
  tst( ">fil.txt", ">fil.txt" );
  tst( ">fil.gz", "| gzip>fil.gz" );
  tst( " > fil.bz2", "| bzip2 > fil.bz2" );
  tst( "  >   fil.xz", "| xz  >   fil.xz" );
  @Acme::Tools::Openstrpath=('/nowhere');
}
