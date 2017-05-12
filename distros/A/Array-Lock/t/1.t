#1.t
use Test;
BEGIN { plan tests => 6 }
eval {
  use Array::Lock;
};
my $error = $@ ? 'Error' : 'No Error';
ok($error,'No Error','Please make sure you have a high enough version of Perl.');
{
  my @array = qw/t e s t/;
  eval {  # Test lock_values.
    Array::Lock::lock_values(@array);
    $array[0] = 'test_change';
  };
  ok($@);
}

{
  my @array = qw/t e s t/;
  my @keys  = (1,2);

  eval {
    Array::Lock::lock_values(@array,@keys);
    $array[0] = 'test_change';
  };
  ok(!$@);
  eval {
    $array[1] = 'test_change';
  };
  ok($@);
}

{
  my @array = qw/t e s t/;
  eval {
    Array::Lock::lock_keys(@array);
    $array[1] = 'test_change';
  };
  ok(!$@);
}

{
  my @array = qw/t e s t/;
  my @keys = qw/1 2/;
  eval {
    Array::Lock::lock_key(@array,@keys);
    $array[1] = 'test_change';
  };
  ok($@);
}