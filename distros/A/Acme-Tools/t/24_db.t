# make test
# perl Makefile.PL; make; perl -Iblib/lib t/24_db.t
no strict;
no warnings;
#BEGIN{require 't/common.pl'}
use Acme::Tools;
use Test::More tests => 10;
ok(1) for 1..10;exit;#4now

my $f='/tmp/acme-tools.sqlite'; unlink($f);
print repl($f,'x','y'),"\n";
dlogin($f);
ddo(<<"");
  create table tst (
    a integer primary key,
    b varchar2,
    c date
  )

ddo("insert into tst values ".
      join",",
      map "(".join(",",$_,$_%2?"'XYZ'":"'ABC'",time_fp()).")",
      1..100);
dcommit();
ok( 100 == drow("select sum(1) from tst") );
ok( 50 == drow("select sum(1) from tst where b = ? and c <= ?", 'ABC',time_fp()) );
ok( 50 == drow("select sum(1) from tst where b = ? and c <= ?", 'XYZ',time_fp()) );
ok(1);
dlogout();
