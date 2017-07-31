use Modern::Perl;
use Data::Dumper;
use Test::More qw(no_plan);

my $class='Data::Result';
require_ok($class);
use_ok($class);

eval { $class->new };
ok($@,'should have to failed to construct without is_true');
diag $@;
ok($class->new(is_true=>1),'$class->new(is_true=>1) test');
ok(!$class->new(is_true=>0),'$class->new(is_true=>0) test') or diag Dumper($class->new(is_true=>0));

{
  my $result=$class->new(is_true=>1,msg=>'testing');
  ok($result,'Testing state: 1 and msg: testing');
  cmp_ok($result,'eq','testing', 'should match the string context');
}
{
  my $result=$class->new(is_true=>0,msg=>'testing');
  ok(!$result,'Testing state: 0 and msg: testing');
  cmp_ok($result,'eq','testing', 'should match the string context');
}
{
  my $result=$class->new(is_true=>0,msg=>'testing',data=>'test data');
  ok(!$result,'Testing state: 0 and msg: testing');
  cmp_ok($result,'eq','testing', 'msg should match the string context');
  cmp_ok($result->data,'eq','test data', 'data hould match: test data');
}

eval { $class->new_false(undef); };

ok($@,'Should croak when Data::Result->new_false(undef)');
ok($class->new_true,'Data::Result->new_true should be true');
ok(!$class->new_false('testing'),'Data::Result->new_false should be fale');

is_deeply({%{$class->new_false('msg')}},{msg=>'msg',is_true=>0,extra=>undef},'False Structure validation');
is_deeply({%{$class->new_true('msg')}},{data=>'msg',is_true=>1,extra=>undef},'True Structure validation');



done_testing;
