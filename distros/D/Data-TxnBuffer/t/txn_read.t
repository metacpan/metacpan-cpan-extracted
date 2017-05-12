use strict;
use warnings;
use Test::More;

use Data::TxnBuffer;

my $b = Data::TxnBuffer->new;

my ($foo, $bar, $ret);
my $reader = sub {
    $foo = $b->read(3);
    $bar = $b->read(3);
};

eval {
    $ret = $b->txn_read($reader);
};
ok $@, 'read error ok';

$b->write('foo');
eval {
    $ret = $b->txn_read($reader);
};
ok $@, 'read error again ok';

$b->write('bar');
eval {
    $ret = $b->txn_read($reader);
};
ok !$@, 'no error ok';

is $foo, 'foo', 'foo is ok';
is $bar, 'bar', 'bar is ok';

ok !$b->data, 'auto spin ok';
is $ret, 'foobar', 'return spin data ok';

done_testing;
