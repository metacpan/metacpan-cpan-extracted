use Modern::Perl;
use Test::More qw(no_plan);
use Data::Dumper;

my $class='Data::Result::Moo';
use_ok($class);
require_ok($class);


my $test=new Test::Moo;
isa_ok($test,'Test::Moo');

ok($test->new_true,'should return true');

isa_ok($test->new_true,$test->RESULT_CLASS);
ok(!$test->new_false('this is a test'),'should return false');
isa_ok($test->new_false('msg'),$test->RESULT_CLASS);

eval { $test->new_false };
ok($@,'should fail to create a new false objcet without a message');

BEGIN {
  package Test::Moo;
  use Modern::Perl;
  use Moo;
  with('Data::Result::Moo');
  1;
}

done_testing;
