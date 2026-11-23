use strict;
use warnings;

use Data::NestedKey;
use Test::More;

subtest 'delete does not touch unrelated keys through missing paths' => sub {
  my $data = { a => { z => 2, b => { z => 3 } } };
  my $nk = Data::NestedKey->new($data);

  $nk->delete('a.missing.z');
  is_deeply($data, { a => { z => 2, b => { z => 3 } } }, 'missing intermediate key does not delete a different key');

  $nk->delete('a.b.missing.z');
  is_deeply($data, { a => { z => 2, b => { z => 3 } } }, 'deeper missing key leaves data unchanged');

  $nk->delete('a.b.z');
  is_deeply($data, { a => { z => 2 } }, 'valid deletion still removes empty parent hash');
};

subtest 'exists_key on array-rooted structures' => sub {
  my $nk = Data::NestedKey->new([ { name => 'first' }, { name => 'second' }, undef ]);

  ok($nk->exists_key('[0]'), 'first array entry exists');
  ok($nk->exists_key('[0].name'), 'nested key through root array exists');
  ok($nk->exists_key('[-2].name'), 'negative root array subscript exists');
  ok(!$nk->exists_key('[0].missing'), 'absent nested key does not exist');
  ok(!$nk->exists_key('[9]'), 'out-of-range array subscript does not exist');
  ok(!$nk->exists_key('[2]'), 'undefined array slot is treated as missing');
};

subtest 'delete on array-rooted structures' => sub {
  my $data = [ { name => 'first' }, { name => 'second' }, { name => 'third' } ];
  my $nk = Data::NestedKey->new($data);

  $nk->delete('[0].name');
  is_deeply($data->[0], {}, 'delete nested key through root array');

  $nk->delete('[1]');
  is_deeply($data, [ {}, { name => 'third' } ], 'delete bare root subscript splices array');

  $nk->delete('[-1]');
  is_deeply($data, [ {} ], 'delete negative root subscript');
};

subtest 'invalid array subscripts do not modify data' => sub {
  my $data = { a => [ 'one', 'two' ], untouched => 1 };
  my $nk = Data::NestedKey->new($data);

  $nk->delete('a[50]');
  $nk->delete('a[-50]');
  $nk->delete('a[50].untouched');
  is_deeply($data, { a => [ 'one', 'two' ], untouched => 1 }, 'out-of-bounds indices leave data unchanged');
};

done_testing();
