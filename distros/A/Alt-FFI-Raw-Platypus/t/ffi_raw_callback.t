use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use lib 't/lib';
use FFI::Raw;

my($shared) = ffi->test->lib;

subtest 'callbacks' => sub {

  my $take_one_int_callback = FFI::Raw->new(
    $shared, 'take_one_int_callback',
    FFI::Raw::void, FFI::Raw::ptr
  );

  my $func1 = sub {
    my $num = shift;
    is($num, 42);
  };

  my $cb1 = FFI::Raw::callback($func1, FFI::Raw::void, FFI::Raw::int);

  $take_one_int_callback->call($cb1);
  $take_one_int_callback->($cb1);

  ok(1, "survived the call");

  my $return_int_callback = FFI::Raw->new(
    $shared, 'return_int_callback',
    FFI::Raw::int, FFI::Raw::ptr
  );

  my $func2 = sub {
    my $num = shift;

    return $num + 15;
  };

  my $cb2 = FFI::Raw::callback($func2, FFI::Raw::int, FFI::Raw::int);

  my $check1 = $return_int_callback->call($cb2);
  my $check2 = $return_int_callback->($cb2);

  ok(1, "survived the call");

  is($check1, (42 + 15), "returned @{[ (42+15) ]}");
  is($check2, (42 + 15), "returned @{[ (42+15) ]}");

  sub func3 {
    my $num = shift;

    return $num + 15;
  };

  my $cb3 = FFI::Raw::callback(\&func3, FFI::Raw::int, FFI::Raw::int);

  $check1 = $return_int_callback->call($cb3);
  $check2 = $return_int_callback->($cb3);

  ok(1, "survived the call (anonymous subroutine)");

  is($check1, (42 + 15), "returned @{[ (42+15) ]}");
  is($check2, (42 + 15), "returned @{[ (42+15) ]}");

  my $str_value = "foo";
  my $cb4 = FFI::Raw::callback(sub { $str_value }, FFI::Raw::str);

  ok(1, "survived the call");

  my $return_str_callback = FFI::Raw->new(
    $shared, 'return_str_callback',
    FFI::Raw::void, FFI::Raw::ptr
  );

  $return_str_callback->call($cb4);

  my $get_str_value = FFI::Raw->new(
    $shared, 'get_str_value',
    FFI::Raw::str,
  );

  my $value = $get_str_value->call();

  is($value, 'foo', 'returned foo');

  $str_value = undef;
  $return_str_callback->call($cb4);

  $value = $get_str_value->call();

  is($value, 'NULL', "returned 'NULL'");

  my $reset = FFI::Raw->new(
    $shared, 'reset',
    FFI::Raw::void,
  );

  $reset->call();
  my $buffer = FFI::Raw::MemPtr->new_from_buf("bar\0", length "bar\0");
  my $cb5 = FFI::Raw::callback(sub { $buffer }, FFI::Raw::ptr);

  ok(1, "survived the call");

  $return_str_callback->call($cb5);

  $value = $get_str_value->call();

  is($value, "bar", "returned bar");

  $reset->call();
  $buffer = FFI::Raw::MemPtr->new_from_buf("baz\0", length "baz\0");
  my $cb6 = FFI::Raw::callback(sub { $$buffer }, FFI::Raw::ptr);

  ok(1, "survived the call");

  $return_str_callback->call($cb6);

  $value = $get_str_value->call();

  is($value, 'baz', "returned baz");

  $reset->call();
  my $cb7 = FFI::Raw::callback(sub { undef }, FFI::Raw::ptr);

  ok(1, "survived the call");

  $return_str_callback->call($cb7);

  $value = $get_str_value->call();

  is($value, "NULL", "returned 'NULL'");
};

done_testing;
