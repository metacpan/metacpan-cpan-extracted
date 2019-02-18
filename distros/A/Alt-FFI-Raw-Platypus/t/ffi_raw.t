use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use lib 't/lib';
use FFI::Raw;
use Math::BigInt;
use POSIX;
use File::Spec;
use Env qw(@PATH);
use File::Copy qw(cp);
use File::Temp qw(tempdir);

my($shared) = ffi->test->lib;

subtest 'argless' => sub {

  my $argless = FFI::Raw->new($shared, 'argless', FFI::Raw::void);

  $argless->call;
  $argless->();

  ok 1, 'survived the call';

};

subtest 'simple-args' => sub {
  my $take_one_long = FFI::Raw->new(
    $shared, 'take_one_long',
    FFI::Raw::void, FFI::Raw::long
  );

  $take_one_long->call(LONG_MIN);

  my $take_one_ulong = FFI::Raw->new(
    $shared, 'take_one_ulong',
    FFI::Raw::void, FFI::Raw::ulong
  );

  $take_one_ulong->call(ULONG_MAX);

  my $take_one_int = FFI::Raw->new(
    $shared, 'take_one_int',
    FFI::Raw::void, FFI::Raw::int
  );

  $take_one_int->call(INT_MIN);

  my $take_one_uint = FFI::Raw->new(
    $shared, 'take_one_uint',
    FFI::Raw::void, FFI::Raw::uint
  );

  $take_one_uint->call(UINT_MAX);

  my $take_one_short = FFI::Raw->new(
    $shared, 'take_one_short',
    FFI::Raw::void, FFI::Raw::short
  );

  $take_one_short->call(SHRT_MIN);

  my $take_one_ushort = FFI::Raw->new(
    $shared, 'take_one_ushort',
    FFI::Raw::void, FFI::Raw::ushort
  );

  $take_one_ushort->call(USHRT_MAX);

  my $take_one_char = FFI::Raw->new(
    $shared, 'take_one_char',
    FFI::Raw::void, FFI::Raw::char
  );

  $take_one_char->call(CHAR_MIN);

  my $take_one_uchar = FFI::Raw->new(
    $shared, 'take_one_uchar',
    FFI::Raw::void, FFI::Raw::uchar
  );

  $take_one_uchar->call(UCHAR_MAX);

  my $take_two_shorts = FFI::Raw->new(
    $shared, 'take_two_shorts',
    FFI::Raw::void, FFI::Raw::short, FFI::Raw::short
  );

  $take_two_shorts->call(10, 20);

  my $take_misc_ints = FFI::Raw->new(
    $shared, 'take_misc_ints',
    FFI::Raw::void, FFI::Raw::int, FFI::Raw::short, FFI::Raw::char
  );

  $take_misc_ints->call(101, 102, 103);
  $take_misc_ints->(101, 102, 103);

  # floats
  my $take_one_double = FFI::Raw->new(
    $shared, 'take_one_double',
    FFI::Raw::void, FFI::Raw::double
  );

  $take_one_double->call(-6.9e0);
  $take_one_double->(-6.9e0);

  my $take_one_float = FFI::Raw->new(
    $shared, 'take_one_float',
    FFI::Raw::void, FFI::Raw::float
  );

  $take_one_float->call(4.2e0);
  $take_one_float->(4.2e0);

  # strings
  my $take_one_string = FFI::Raw->new(
    $shared, 'take_one_string',
    FFI::Raw::void, FFI::Raw::str
  );

  $take_one_string->call('ok - passed a string');
  $take_one_string->('ok - passed a string');

};

subtest 'simple-returns' => sub {

  my $min_int64  = Math::BigInt->new('-9223372036854775808');
  my $max_uint64 = Math::BigInt->new('18446744073709551615');

  SKIP: {
  eval "use Math::Int64";

  skip 'Math::Int64 required for int64 tests', 4 if $@;

  my $return_int64 = eval { FFI::Raw->new($shared, 'return_int64', FFI::Raw::int64) };

  skip 'LLONG_MIN and ULLONG_MAX required for int64 tests', 4 if $@;

  is $return_int64->call, $min_int64->bstr();
  is $return_int64->(), $min_int64->bstr();

  my $return_uint64 = FFI::Raw->new($shared, 'return_uint64', FFI::Raw::uint64);
  is $return_uint64->call, $max_uint64->bstr();
  is $return_uint64->(), $max_uint64->bstr();
  };

  my $return_long = FFI::Raw->new($shared, 'return_long', FFI::Raw::long);
  is $return_long->call, LONG_MIN;
  is $return_long->(), LONG_MIN;

  my $return_ulong = FFI::Raw->new($shared, 'return_ulong', FFI::Raw::ulong);
  is $return_ulong->call, ULONG_MAX;
  is $return_ulong->(), ULONG_MAX;

  my $return_int = FFI::Raw->new($shared, 'return_int', FFI::Raw::int);
  is $return_int->call, INT_MIN;
  is $return_int->(), INT_MIN;

  my $return_uint = FFI::Raw->new($shared, 'return_uint', FFI::Raw::uint);
  is $return_uint->call, UINT_MAX;
  is $return_uint->(), UINT_MAX;

  my $return_short = FFI::Raw->new($shared, 'return_short', FFI::Raw::short);
  is $return_short->call, SHRT_MIN;
  is $return_short->(), SHRT_MIN;

  my $return_ushort = FFI::Raw->new($shared, 'return_ushort', FFI::Raw::ushort);
  is $return_ushort->call, USHRT_MAX;
  is $return_ushort->(), USHRT_MAX;

  my $return_char = FFI::Raw->new($shared, 'return_char', FFI::Raw::char);
  is $return_char->call, CHAR_MIN;
  is $return_char->(), CHAR_MIN;

  my $return_uchar = FFI::Raw->new($shared, 'return_uchar', FFI::Raw::uchar);
  is $return_uchar->call, UCHAR_MAX;
  is $return_uchar->(), UCHAR_MAX;

  my $return_double = FFI::Raw->new($shared, 'return_double', FFI::Raw::double);

  {
    my $todo = todo 'failing';
    is $return_double->call, 9.9e0;
    is $return_double->(), 9.9e0;
  };

  my $return_float = FFI::Raw->new($shared, 'return_float', FFI::Raw::float);
  is $return_float->call, -4.5e0;
  is $return_float->(), -4.5e0;

  my $return_string = FFI::Raw->new($shared, 'return_string', FFI::Raw::str);
  is $return_string->call, 'epic cuteness';
  is $return_string->(), 'epic cuteness';
};

subtest 'overload' => sub {

  my $ffi;
  eval {
      $ffi = FFI::Raw->new('libfoo.X', 'foo', FFI::Raw::void);
  };

  ok !$ffi;

  $ffi = FFI::Raw->new($shared, 'foo', FFI::Raw::void);

  ok $ffi;

};

subtest 'from mail' => sub {

  my $isalpha = FFI::Raw->new(undef, 'isalpha', FFI::Raw::int, FFI::Raw::int);

  isa_ok $isalpha, 'FFI::Raw';

  ok  $isalpha->call(ord 'a');
  ok !$isalpha->call(ord '0');

};

subtest 'absolute-path' => sub {

  my $absolute = File::Spec->rel2abs($shared);
  note "shared   = $shared";
  note "absolute = $absolute";

  my $one = FFI::Raw->new($absolute, 'one', FFI::Raw::int);
  is $one->(), 1, "absolute $absolute";

  SKIP: {
    skip 'Cygwin/MSWin32 only'
      unless $^O =~ /^(cygwin|MSWin32)$/;

    my $tmp = tempdir(CLEANUP => 1);
    cp($absolute, File::Spec->catfile($tmp, 'foo.dll'));

    push @PATH, $tmp;
    my $one = FFI::Raw->new('foo.dll', 'one', FFI::Raw::int);

    is $one->(), 1, "path $tmp/foo.dll";
  }
};

subtest 'null' => sub {

  my $return_undef_str  = FFI::Raw->new(
    $shared, 'return_undef_str', FFI::Raw::str
  );

  my $pass_in_undef_str = FFI::Raw->new(
    $shared, 'pass_in_undef_str', FFI::Raw::void, FFI::Raw::str
  );

  $pass_in_undef_str->call(undef);

  my $undef_str = $return_undef_str->call;
  is($undef_str, U(), "returned undef");

  my $return_undef_ptr  = FFI::Raw->new(
    $shared, 'return_undef_ptr', FFI::Raw::ptr
  );

  my $pass_in_undef_ptr = FFI::Raw->new(
    $shared, 'pass_in_undef_ptr', FFI::Raw::void, FFI::Raw::ptr
  );

  $pass_in_undef_ptr->call(undef);

  my $undef_ptr = $return_undef_ptr->call;
  is($undef_ptr, U(), "returned undef");

};

done_testing;
