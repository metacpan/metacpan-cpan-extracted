use strict;
use warnings;
use Test::More;
use App::Presto::Stash;

my $stash = App::Presto::Stash->new;
isa_ok $stash, 'App::Presto::Stash';

is_deeply $stash->stash, {}, 'empty stash';

is $stash->get('foo'), undef, 'get on missing key';

$stash->set(foo => 1);
is $stash->get('foo'), 1, 'set/get';

$stash->set(foo => 2);
is $stash->get('foo'), 2, 'set/get part two';

is_deeply $stash->stash, { foo => 2 }, '->stash (no args)';
is $stash->stash('foo'), 2, '->stash (1 arg)';
is $stash->stash(foo => 3), 3, '->stash (2 args)';
is_deeply $stash->stash, { foo => 3 }, 'sanity';
is $stash->get('bar'), undef, 'missing key part two';
is $stash->set('bar', 10), 10, '->set return value';
is $stash->get('bar'), 10, 'sanity part two';
$stash->unset('bar');
is $stash->get('bar'), undef, 'unset key';

done_testing;
