use Modern::Perl;
use Test::More;

my $class='Data::Promise';

use_ok($class);
require_ok($class);

{
  my $p=$class->new(cb=>sub { $_[0]->(42) },delayed=>1);

  isa_ok($p,$class);
  ok($p->pending,'called in a delayed state the object should be pending');

  my $result;
  my $count=0;
  $p->then(sub { ($result)=@_;++$count});
  my $final=0;
  $p->finally(sub { ++$final });
  ok(!defined($result),'result should not be defined');
  ok($p->pending,'Result should be pending');
  cmp_ok($final,'==',0,'Finally should not have been called');
  $p->do_resolve;
  cmp_ok($final,'==',1,'Finally should be 1');
  cmp_ok($result,'==',42,'$result should now be 42');

  $p->finally(sub { ++$final });
  cmp_ok($final,'==',2,'Finally should be 2');
  $result=undef;
  ok(!$p->pending,'Result should no longer be pending');
  $p->then(sub { $result=$_[0];++$count });
  cmp_ok($result,'==',42,'$result should now be 42 again');
  cmp_ok($count,'==',2,'Should have called each function just once');


  $p->do_resolve;
  cmp_ok($count,'==',2,'calling $p->do_resolve again should do nothing!');
  $p->_resolver(0)->('error');
  cmp_ok($count,'==',2,'internal _resolver test');


}

{
  my $p=$class->new(cb=>sub { $_[1]->(82) },delayed=>1);

  isa_ok($p,$class);
  ok($p->pending,'called in a delayed state the object should be pending');

  my $result;
  my $count=0;
  $p->then(undef, sub { ($result)=@_;++$count});
  my $final=0;
  $p->finally(sub { ++$final });
  ok(!defined($result),'result should not be defined');
  ok($p->pending,'Result should be pending');
  cmp_ok($final,'==',0,'Finally should not have been called');
  $p->do_resolve;
  cmp_ok($final,'==',1,'Finally should be 1');
  cmp_ok($result,'==',82,'$result should now be 82');

  $p->finally(sub { ++$final });
  cmp_ok($final,'==',2,'Finally should be 2');
  $result=undef;
  ok(!$p->pending,'Result should no longer be pending');
  $p->then(undef, sub { $result=$_[0];++$count });
  cmp_ok($result,'==',82,'$result should now be 82 again');
  cmp_ok($count,'==',2,'Should have called each function just once');


  $p->do_resolve;
  cmp_ok($count,'==',2,'calling $p->do_resolve again should do nothing!');
  $p->_resolver(0)->('error');
  cmp_ok($count,'==',2,'internal _resolver test');
}
{
  my $p=$class->reject(42);
  isa_ok($p,$class);
  ok(!$p->pending,'called in a rejected state, we should not be pending');
  my $pass=undef;
  my $fail=undef;

  $p->then(sub {$pass=$_[0]},sub { $fail=$_[0]});
  cmp_ok($fail,'==',42,'rejected should be 42');
  ok(!defined($pass),'pass value should be empty');

}
{
  my $p=$class->resolve(42);
  isa_ok($p,$class);
  ok(!$p->pending,'called in a rejected state, we should not be pending');
  my $pass=undef;
  my $fail=undef;

  $p->then(sub {$pass=$_[0]},sub { $fail=$_[0]});
  cmp_ok($pass,'==',42,'pass should be 42');
  ok(!defined($fail),'fail value should be empty');
}
done_testing;
