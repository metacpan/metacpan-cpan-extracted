use strict;
use warnings;

use Data::Rx 0.005;
use Data::Rx::TypeBundle::Perl;
use Test::More 0.88;

my $rx = Data::Rx->new({
  type_plugins => [ qw(Data::Rx::TypeBundle::Perl) ]
});

my $isa_rx = $rx->make_schema({
  type       => '/perl/obj',
  isa        => 'Data::Rx',
});

ok($isa_rx->check($rx),   "a Data::Rx object isa Data::Rx /perl/obj");
ok(! $isa_rx->check( 1 ), "1 is not a Data::Rx /perl/obj");

{
  my $is_code = $rx->make_schema({
    type       => '/perl/code',
  });

  ok(  $is_code->check( sub      {} ), 'proto:    // sub      {} == ok');
  ok(  $is_code->check( sub ()   {} ), 'proto:    // sub ()   {} != ok');
  ok(  $is_code->check( sub ($$) {} ), 'proto:    // sub ($$) {} != ok');
  ok(! $is_code->check( 1 ),           '1 is not code');
}

{
  my $is_code = $rx->make_schema({
    type      => '/perl/code',
    prototype => undef,
  });

  ok(  $is_code->check( sub      {} ), 'proto: ~  // sub      {} == ok');
  ok(! $is_code->check( sub ()   {} ), 'proto: ~  // sub ()   {} != ok');
  ok(! $is_code->check( sub ($$) {} ), 'proto: ~  // sub ($$) {} != ok');
  ok(! $is_code->check( 1 ),    "1 is not code");
}

{
  my $is_code = $rx->make_schema({
    type      => '/perl/code',
    prototype => '',
  });

  ok(! $is_code->check( sub      {} ), 'proto: "" // sub      {} != ok');
  ok(  $is_code->check( sub ()   {} ), 'proto: "" // sub ()   {} == ok');
  ok(! $is_code->check( sub ($$) {} ), 'proto: "" // sub ($$) {} != ok');
  ok(! $is_code->check( 1 ),    "1 is not code");
}

{
  my $is_code = $rx->make_schema({
    type      => '/perl/code',
    prototype => '$$',
  });

  ok(! $is_code->check( sub      {} ), 'proto: $$ // sub      {} != ok');
  ok(! $is_code->check( sub ()   {} ), 'proto: $$ // sub ()   {} != ok');
  ok(  $is_code->check( sub ($$) {} ), 'proto: $$ // sub ($$) {} == ok');
  ok(! $is_code->check( 1 ),    "1 is not code");
}

{
  my $is_arr_code = $rx->make_schema({
    type     => '//arr',
    contents => '/perl/code',
  });

  ok(  $is_arr_code->check([ sub {} ]), '[sub{}] is //arr of /perl/code');
  ok(! $is_arr_code->check([ 1      ]), '[1] is not //arr of /perl/code');
}

{
  my $is_int_ref = $rx->make_schema({
    type      => '/perl/ref',
    referent  => '//int',
  });

  ok(! $is_int_ref->check(  1  ),   '1 is not an int ref');
  ok(  $is_int_ref->check( \1  ),   '\1 is an int ref ');
  ok(! $is_int_ref->check( \1.23 ), '\1.23 is not an int ref');
}

{
  my $is_obj_ref = $rx->make_schema({
    type      => '/perl/ref',
    referent  => { type => '/perl/obj', isa => 'Test::Object' },
  });

  my $obj = bless {} => 'Test::Object';
  my $bad = bless {} => 'Bad::Object';

  ok(! $is_obj_ref->check(  $obj ), "$obj is not a ref to a Test::Object");
  ok(! $is_obj_ref->check(  $bad ), "$bad is not a ref to a Test::Object");
  ok(  $is_obj_ref->check( \$obj ), "\\$obj is a ref to a Test::Object");
  ok(! $is_obj_ref->check( \$bad ), "\\$obj is not a ref to a Test::Object");
}

my $isa_arr_rx = $rx->make_schema({
  type     => '//arr',
  contents => {
    type => '/perl/obj',
    isa  => 'Data::Rx',
  },
});

ok($isa_arr_rx->check([$rx]), '[$rx] is an //arr of /perl/obj');
ok(! $isa_arr_rx->check([1]), "[1] is not an //arr /perl/obj");

{
  my $arr_intref = $rx->make_schema({
    type     => '//arr',
    contents => {
      type     => '/perl/ref',
      referent => '//int',
    },
  });

  eval { $arr_intref->assert_valid([ \1, \2, \3, \3.2 ]); };
  my $fail = $@;

  like($fail->stringify, qr/\$\{\$data/, "stringify has a scalar deref");
}

done_testing;
