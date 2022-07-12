#! perl -I. -w
use t::Test::abeltje;
use lib 't/inc';

{
    note('Consume role');
    my $tst = MyConsumer::RESTRPC->new();
    isa_ok($tst, 'MyConsumer::RESTRPC');
    ok(
        $tst->does('Dancer2::RPCPlugin'),
        ref($tst) . " does Dancer2::RPCPlugin"
    );
    is(MyConsumer::RESTRPC->rpcplugin_tag, 'restrpc', "CLASS->rpcplugin_tag()");
    is($tst->rpcplugin_tag, 'restrpc', "INSTANCE->rpcplugin_tag()");
}

{
    note('Create builder from config');
    my $tst = MyConsumer::RESTRPC->new();
    isa_ok($tst, 'MyConsumer::RESTRPC');
    my $builder = $tst->dispatch_builder(
        '/endpoint',
        undef,
        undef,
        {'/endpoint' => {'MyTestConfig' => {method1 => 'sub1'}}}
    );
    isa_ok($builder, 'CODE');
    my $dispatch = $builder->();
    is_deeply(
        $dispatch,
        {
            'method1' => Dancer2::RPCPlugin::DispatchItem->new(
                code => \&MyTestConfig::sub1,
                package => 'MyTestConfig',
            ),
        },
        "Dispatch from Config"
    );
}

{
    note('Create builder from POD');
    my $tst = MyConsumer::RESTRPC->new();
    isa_ok($tst, 'MyConsumer::RESTRPC');
    my $builder = $tst->dispatch_builder(
       '/endpoint',
       'pod',
       ['MyTestPod'],
    );
    isa_ok($builder, 'CODE');
    my $dispatch = $builder->();
    is_deeply(
        $dispatch,
        {
            'method2' => Dancer2::RPCPlugin::DispatchItem->new(
                code => \&MyTestPod::sub2,
                package => 'MyTestPod',
            ),
        },
        "Dispatch from Pod"
    ) or diag(explain($dispatch));
}

{
    note('Dispatch from code');
    my $tst = MyConsumer::RESTRPC->new();
    isa_ok($tst, 'MyConsumer::RESTRPC');
    my $builder = $tst->dispatch_builder(
        '/endpoint',
        sub {
            return {
                method1 => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => \&MyTestConfig::sub1,
                    package => 'MyTestConfig',
                ),
            }
        }
    );
    isa_ok($builder, 'CODE');
    my $dispatch = $builder->();
    is_deeply(
        $dispatch,
        {
            'method1' => Dancer2::RPCPlugin::DispatchItem->new(
                code => \&MyTestConfig::sub1,
                package => 'MyTestConfig',
            ),
        },
        "Dispatch from Code"
    ) or diag(explain($dispatch));
}


abeltje_done_testing();

BEGIN {
    use Test::MockObject;
    (my $app = Test::MockObject->new->set_always(log => 1));
    package MyConsumer::RESTRPC;
    use Moo;
    with 'Dancer2::RPCPlugin';
    has app => (is => 'ro', default => sub {$app});
    1;

    $INC{'MyTestConfig.pm'} = 'preloaded';
    package MyTestConfig;
    sub sub1 { return 42 }
    1;
}
