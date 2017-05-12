use t::lib::Utils;

use Test::More;
use Test::Fatal;

use Data::Mapper::Data;
use t::lib::Data::Mapper::Data::Test;

subtest 'table' => sub {
    plan skip_all => 'removed $data->table()';

    note 'subclassing';
    {
        my $data = t::lib::Data::Mapper::Data::Test->new;
        is $data->table, 'test';
    }

    note 'direct access';
    {
        my $data = Data::Mapper::Data->new;
        like exception { $data->table }, qr/^this class should be inherited by subclass/;
    }
};

subtest 'param' => sub {
    my $data = t::lib::Data::Mapper::Data::Test->new;

    note 'param() as a getter';
    ok !$data->param('foo');
    $data->param(foo => 'test');
    is $data->param('foo'), 'test';

    note 'param() as a setter';
    $data->param(bar => 'test2', baz => 'test3');
    is $data->param('bar'), 'test2';
    is $data->param('baz'), 'test3';

    note 'param() without args';
    is_deeply [sort $data->param], [qw(bar baz foo)];

    note 'param() croaks when odd number args passed in';
    like exception { $data->param(1, 2, 3) }, qr/^arguments count must be/;
};

subtest 'changes' => sub {
    my $data = t::lib::Data::Mapper::Data::Test->new;

    ok !$data->is_changed;
    is_deeply $data->changed_keys, [];
    is_deeply $data->changes,      {};

    $data->param(foo => 'test');

    ok $data->is_changed;
    is_deeply $data->changed_keys, [qw(foo)];
    is_deeply $data->changes,      { foo => 'test' };

    $data->discard_changes;

    ok !$data->is_changed;
    is_deeply $data->changed_keys, [];
    is_deeply $data->changes,      {};
};

done_testing;
