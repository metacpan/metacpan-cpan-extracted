use strict;
use warnings;
use Data::DeepAccess qw(deep_exists deep_get deep_set deep_val);
use Test2::V0;

{
  package My::Test::Class;
  sub new { bless {foo => 42}, shift }
  sub foo { @_ > 1 ? do {$_[0]{foo} = $_[1]; $_[0]} : $_[0]{foo} }
}

my $data = {a => [undef,{b => 42, 0 => sub {}}], b => My::Test::Class->new, c => undef};

ok deep_exists($data), 'root structure exists';
ref_is deep_get($data), $data, 'get root structure';
ref_is deep_val($data), $data, 'get root structure (lvalue)';
ok deep_exists($data, 'a'), 'hash key exists';
ref_is deep_get($data, 'a'), $data->{a}, 'get hash key';
ref_is deep_val($data, 'a'), $data->{a}, 'get hash key (lvalue)';
ok deep_exists($data, 'b'), 'hash key exists';
ref_is deep_get($data, 'b'), $data->{b}, 'get hash key';
ref_is deep_val($data, 'b'), $data->{b}, 'get hash key (lvalue)';
ok deep_exists($data, 'c'), 'hash key exists';
is deep_get($data, 'c'), $data->{c}, 'get undef hash key';
is deep_val($data, 'c'), $data->{c}, 'get undef hash key (lvalue)';
ok !deep_exists($data, 'c', 'a'), 'undef has no elements';
is deep_get($data, 'c', 'a'), undef, 'undef has no elements';
is deep_val($data, 'c', 'a'), undef, 'undef has no elements (lvalue)';
ok !deep_exists($data, 'd'), 'hash key does not exist';
is deep_get($data, 'd'), undef, 'get nonexistent hash key';
is deep_val($data, 'd'), undef, 'get nonexistent hash key (lvalue)';
ok !deep_exists($data, 'd', 'd'), 'hash key does not exist';
is deep_get($data, 'd', 'd'), undef, 'get nonexistent hash key';
is deep_val($data, 'd', 'd'), undef, 'get nonexistent hash key (lvalue)';
ok !deep_exists($data, 0), 'hash key does not exist';
is deep_get($data, 0), undef, 'get nonexistent hash key';
is deep_val($data, 0), undef, 'get nonexistent hash key (lvalue)';
ok deep_exists($data, 'a', 0), 'array element exists';
is deep_get($data, 'a', 0), undef, 'get undef array element';
is deep_val($data, 'a', 0), undef, 'get undef array element (lvalue)';
ok deep_exists($data, 'a', 1), 'array element exists';
ref_is deep_get($data, 'a', 1), $data->{a}[1], 'get array element';
ref_is deep_val($data, 'a', 1), $data->{a}[1], 'get array element (lvalue)';
ok !deep_exists($data, 'a', 2), 'array element does not exist';
is deep_get($data, 'a', 2), undef, 'get nonexistent array element';
is deep_val($data, 'a', 2), undef, 'get nonexistent array element (lvalue)';
ok !deep_exists($data, 'a', 0, 0), 'undef has no elements';
is deep_get($data, 'a', 0, 0), undef, 'undef has no elements';
is deep_val($data, 'a', 0, 0), undef, 'undef has no elements (lvalue)';
ok deep_exists($data, 'a', 1, 'b'), 'hash key exists';
is deep_get($data, 'a', 1, 'b'), $data->{a}[1]{b}, 'get hash key';
is deep_val($data, 'a', 1, 'b'), $data->{a}[1]{b}, 'get hash key (lvalue)';
like dies { deep_exists($data, 'a', 1, 'b', 'c') }, qr/Can't traverse/i, 'cannot traverse defined scalar';
like dies { deep_get($data, 'a', 1, 'b', 'c') }, qr/Can't traverse/i, 'cannot traverse defined scalar';
like dies { my $val = deep_val($data, 'a', 1, 'b', 'c') }, qr/Can't traverse/i, 'cannot traverse defined scalar';
ok deep_exists($data, 'a', 1, 0), 'hash key exists';
ref_is deep_get($data, 'a', 1, 0), $data->{a}[1]{0}, 'get hash key';
ref_is deep_val($data, 'a', 1, 0), $data->{a}[1]{0}, 'get hash key (lvalue)';
like dies { deep_exists($data, 'a', 1, 0, 'foo') }, qr/Can't traverse/i, 'cannot traverse coderef';
like dies { deep_get($data, 'a', 1, 0, 'foo') }, qr/Can't traverse/i, 'cannot traverse coderef';
like dies { my $val = deep_val($data, 'a', 1, 0, 'foo') }, qr/Can't traverse/i, 'cannot traverse coderef';
ok deep_exists($data, 'b', 'foo'), 'method exists';
is deep_get($data, 'b', 'foo'), $data->{b}->foo, 'get method value';
is deep_val($data, 'b', 'foo'), $data->{b}->foo, 'get method value (lvalue)';
ok !deep_exists($data, 'b', 'bar'), 'method does not exist';
is deep_get($data, 'b', 'bar'), undef, 'method does not exist';
is deep_val($data, 'b', 'bar'), undef, 'method does not exist (lvalue)';
like dies { deep_exists($data, 'b', 'foo', 'bar') }, qr/Can't traverse/i, 'cannot traverse defined scalar';
like dies { deep_get($data, 'b', 'foo', 'bar') }, qr/Can't traverse/i, 'cannot traverse defined scalar';
like dies { my $val = deep_val($data, 'b', 'foo', 'bar') }, qr/Can't traverse/i, 'cannot traverse defined scalar';

is $data, hash {
  field a => array {
    item undef;
    item hash {field b => 42; field 0 => D; end};
    end;
  };
  field b => object {
    prop blessed => 'My::Test::Class';
    call foo => 42;
  };
  field c => undef;
  end;
}, 'data structure unchanged';

{
  is deep_set(my $data, 42), 42, 'set value';
  is $data, 42, 'set value directly';
}

{
  is deep_val(my $data) = 42, 42, 'set value (lvalue)';
  is $data, 42, 'set value directly (lvalue)';
}

{
  is deep_set(my $data, 'a', 42), 42, 'set hash key';
  is $data, hash {field a => 42; end}, 'vivified hash';
}

{
  is deep_val(my $data, 'a') = 42, 42, 'set hash key (lvalue)';
  is $data, hash {field a => 42; end}, 'vivified hash (lvalue)';
}

{
  is deep_set(my $data, {key => 'b'}, 42), 42, 'set hash key';
  is $data, hash {field b => 42; end}, 'vivified hash';
}

{
  is deep_val(my $data, {key => 'b'}) = 42, 42, 'set hash key (lvalue)';
  is $data, hash {field b => 42; end}, 'vivified hash (lvalue)';
}

{
  is deep_set(my $data, {index => 1}, 42), 42, 'set array element';
  is $data, array {item undef; item 42; end}, 'vivified array';
}

{
  is deep_val(my $data, {index => 1}) = 42, 42, 'set array element (lvalue)';
  is $data, array {item undef; item 42; end}, 'vivified array (lvalue)';
}

{
  like dies { deep_set(my $data, {method => 'foo'}, 42) }, qr/Can't call/i, 'cannot call method on undef';
  like dies { deep_set(my $data, {lvalue => 'foo'}, 42) }, qr/Can't call/i, 'cannot call lvalue on undef';
  like dies { deep_val(my $data, {method => 'foo'}) = 42 }, qr/Can't call/i, 'cannot call method on undef (lvalue)';
  like dies { deep_val(my $data, {lvalue => 'foo'}) = 42 }, qr/Can't call/i, 'cannot call lvalue on undef (lvalue)';
}

{
  my $data = {};
  is deep_set($data, 'a', 'b', 'c', 42), 42, 'set deep hash key';
  is deep_val($data, 'a', 'b', 'd') = 43, 43, 'set deep hash key (lvalue)';
  is $data, hash {
    field a => hash {
      field b => hash {field c => 42; field d => 43; end};
      end;
    };
    end;
  }, 'correct hash structure';
}

{
  my $data = [];
  is deep_set($data, 0, {index => 1}, {index => 2}, 42), 42, 'set deep array element';
  is deep_val($data, 0, {index => 1}, {index => 1}) = 43, 43, 'set deep array element (lvalue)';
  is $data, array {
    item array {
      item undef;
      item array {item undef; item 43; item 42; end};
      end;
    };
    end;
  }, 'correct array structure';
}

{
  my @data;
  is deep_set(\@data, 0, 1, 42), 42, 'set mixed structure value';
  is deep_val(\@data, 0, 2) = 43, 43, 'set mixed structure value (lvalue)';
  is \@data, array {
    item hash {field 1 => 42; field 2 => 43; end};
    end;
  }, 'correct mixed structure';
}

{
  my $obj = My::Test::Class->new;
  ref_is deep_set(my $data, 'c', $obj), $obj, 'set hash key to object';
  is deep_set($data, 'c', 'foo', 'bar'), 'bar', 'set object attribute';
  is deep_val($data, 'c', 'foo') = 'baz', 'baz', 'set object attribute (lvalue)';
  my $hash = {};
  ref_is deep_set($data, 'c', 'foo', $hash), $hash, 'set object attribute to ref';
  is deep_set($data, 'c', 'foo', 'bar', 'baz'), 'baz', 'set hash value in object attribute';
  is deep_val($data, 'c', 'foo', 'baz') = 42, 42, 'set hash value in object attribute (lvalue)';
  is $data, hash {
    field c => object {
      prop blessed => 'My::Test::Class';
      call foo => hash {field bar => 'baz'; field baz => 42; end};
    };
    end;
  }, 'correct data structure';

  todo 'support vivifying object attributes' => sub {
    is deep_set($data, 'c', 'foo', undef), undef, 'undefined object attribute';
    is deep_set($data, 'c', 'foo', {index => 0}, 'bar'), 'bar', 'vivified array in object attribute';
    is $data, hash {
      field c => object {
        prop blessed => 'My::Test::Class';
        call foo => array {item 'bar'; end};
      };
      end;
    }, 'correct data structure';
  };
}

{
  my $ref = \deep_val(my $data, 'foo', 'bar');
  $$ref = 42;
  is $data->{foo}{bar}, 42, 'set deep value from lvalue ref';
  $data->{foo}{bar} = 43;
  is $$ref, 43, 'get deep value from lvalue ref';
}

done_testing;
