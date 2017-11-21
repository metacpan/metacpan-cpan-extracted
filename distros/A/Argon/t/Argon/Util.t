package TestClass;

sub foo {
  my $self = shift;
  return ['foo was called', @_];
};

1;

package main;
use Test2::Bundle::Extended;
use Test::Refcount;
use Devel::Refcount qw(refcount);
use Argon::Util qw(K param interval);

subtest K => sub {
  my $obj = bless {}, 'TestClass';
  my $mtd = $obj->can('foo');
  my $one = 1;
  my $arg = \$one;

  my $obj_refs = refcount $obj;
  my $mtd_refs = refcount $mtd;
  my $arg_refs = refcount $arg;

  is_refcount $obj, $obj_refs, 'initial instance refcount';
  is_refcount $mtd, $mtd_refs, 'initial method refcount';
  is_refcount $arg, $arg_refs, 'initial arg refcount';

  ok my $cb = K('foo', $obj), 'call';
  is ref $cb, 'CODE', 'returns code ref';

  is_refcount $obj, $obj_refs, 'no new instance refs';
  is_refcount $mtd, $mtd_refs, 'no new method refs';
  is_refcount $arg, $arg_refs, 'no new arg refs';

  ok my $ret = $cb->($arg), 'callback';
  is $ret, ['foo was called', $arg], 'expected return values';
  undef $ret;

  is_refcount $obj, $obj_refs, 'no new instance refs';
  is_refcount $mtd, $mtd_refs, 'no new method refs';
  is_refcount $arg, $arg_refs, 'no new arg refs';
};

subtest param => sub {
  my %args = (foo => 'bar');
  is param('foo', %args), 'bar', 'key exists';
  is param('bar', %args, 'baz'), 'baz', 'key does not exist, default provided';
  is param('bar', %args, undef), U(), 'key does not exist, undef provided as default';
  ok dies { param('bar', %args) }, 'dies if key not specified and no default provided';
};

subtest interval => sub {
  my $n = 2;

  ok my $i = interval($n), 'initialize';
  is $i->(), ($n + log($n)), 'call 1';
  is $i->(), ($n + log($n * 2)), 'call 2';
  is $i->(), ($n + log($n * 3)), 'call 3';
  is $i->(), ($n + log($n * 4)), 'call 4';

  is $i->(1), U(), 'reset';
  is $i->(), ($n + log($n)), 'call 1';
  is $i->(), ($n + log($n * 2)), 'call 2';
};

done_testing;
