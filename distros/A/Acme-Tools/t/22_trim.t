# make test
# perl Makefile.PL; make; perl -Iblib/lib t/22_trim.t

BEGIN{require 't/common.pl'}
use Test::More tests => 7;

#--trim
ok( trim(" asdf \t\n    123 ") eq "asdf 123",  'trim 1');
ok( trim(" asdf\t\n    123 ") eq "asdf\t123",  'trim 2');
ok( trim(" asdf\n\t    123\n") eq "asdf\n123", 'trim 3');
my($trimstr,@trim)=(' please ', ' please ', ' remove ', ' my ', ' spaces ');
ok( join('',map"<$_>",trim(@trim)) eq '<please><remove><my><spaces>', 'trim array');
trim(\$trimstr);
ok($trimstr eq 'please', 'trim inplace');
my @trim2=@trim;
trim(\@trim);
@trim2=map trim, @trim2;
ok_ref(\@trim, ['please','remove','my','spaces'], 'trimed array inplace');
ok_ref(\@trim2,['please','remove','my','spaces'], 'trimed array inplace 2');

