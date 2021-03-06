use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use lib 't/lib';
use FFI::Raw;

my($shared) = ffi->test->lib;

subtest 'opaque' => sub {

  {
    package Foo;

    no warnings 'once';

    use base qw(FFI::Raw::Ptr);

    *_foo_new = FFI::Raw->new(
      $shared, 'foo_new',
      FFI::Raw::ptr
    )->coderef;

    sub new {
      bless shift->SUPER::new(_foo_new());
    }

    *get_bar = FFI::Raw->new(
      $shared, 'foo_get_bar',
      FFI::Raw::int,
      FFI::Raw::ptr
    )->coderef;

    *set_bar = FFI::Raw->new(
      $shared, 'foo_set_bar',
      FFI::Raw::void,
      FFI::Raw::ptr,
      FFI::Raw::int
    )->coderef;

    *get_free_count = FFI::Raw->new(
      $shared, 'get_free_count',
      FFI::Raw::int,
      FFI::Raw::str
    )->coderef;

    *DESTROY = FFI::Raw->new(
      $shared, 'foo_free',
      FFI::Raw::void,
      FFI::Raw::ptr
    )->coderef;

  }

  my $foo = Foo->new;
  isa_ok $foo, 'FFI::Raw::Ptr';

  $foo->set_bar(42);

  is $foo->get_bar(), 42, '$foo->get_bar == 42';

  is(Foo->get_free_count(), 0, 'Foo->get_free_count = 0');
  undef $foo;
  is(Foo->get_free_count(), 1, 'Foo->get_free_count = 1');
};

done_testing;
