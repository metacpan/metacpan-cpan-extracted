#! perl -I. -w
use t::Test::abeltje;

use Test::MockObject;

use Dancer2::RPCPlugin::DispatchFromPod;
use Dancer2::RPCPlugin::DispatchItem;

use lib 'ex/';
use MyAppCode;

my $logfile = "";
my $app = Test::MockObject->new->mock(
    log => sub {
        shift;
        use Data::Dumper;
        local ($Data::Dumper::Indent, $Data::Dumper::Sortkeys, $Data::Dumper::Terse) = (0, 1, 1);
        my @processed = map { ref($_) ? Data::Dumper::Dumper($_) : $_ } @_;
        $logfile = join("\n", $logfile, join(" ", @processed)); }
);
my $plugin = Test::MockObject->new->set_always(
    app => $app,
);

{
    note('Working dispatch table from POD');

    my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'jsonrpc',
        packages      => [qw/ MyAppCode /],
        endpoint      => '/testing',
    );
    isa_ok($builder, 'Dancer2::RPCPlugin::DispatchFromPod', 'Builder')
        or diag("\$builder isa: ", ref $builder);
    my $dispatch = $builder->build_dispatch_table();
    is_deeply(
        $dispatch,
        {
            'ping' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_ping'),
                package => 'MyAppCode',
            ),
            'version' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_version'),
                package => 'MyAppCode',
            ),
            'method.list' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_methodlist'),
                package => 'MyAppCode',
            ),
        },
        "Dispatch table from POD"
    ) or diag(explain($dispatch));
}

{
    note('Adding non existing code, fails');

    like(
        exception {
            (
                my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                    plugin_object => $plugin,
                    plugin        => 'jsonrpc',
                    packages      => [qw/ MyBogusApp /],
                    endpoint      => '/testing',
                )
            )->build_dispatch_table();
        },
        qr/Handler not found for bogus.nonexistent: MyBogusApp::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
}

{
    note('Adding non existing package, fails');
    like(
        exception {
            (
                my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                    plugin_object => $plugin,
                    plugin        => 'jsonrpc',
                    packages      => [qw/ MyNotExistingApp /],
                    endpoint      => '/testing',
                )
            )->build_dispatch_table();
        },
        qr/Cannot load MyNotExistingApp .+ in build_dispatch_table_from_pod/s,
        "Using a non existing package throws an exception"
    );
}

{
    note('POD error in =for json');
    $logfile = "";
    like(
        exception {
            (
                my $builder = Dancer2::RPCPlugin::DispatchFromPod->new(
                    plugin_object => $plugin,
                    plugin        => 'jsonrpc',
                    packages      => [qw/ MyPoderrorApp /],
                    endpoint      => '/testing',
                )
            )->build_dispatch_table();
        },
        qr/Handler not found for method: MyPoderrorApp::code doesn't seem to exist/,
        "Ignore syntax-error in '=for jsonrpc/xmlrpc'"
    );
    like(
        $logfile,
        qr/^error .+ >rpcmethod-name-missing< <=> >sub-name-missing</m,
        "error log-message method and sub missing"
    );
    like(
        $logfile,
        qr/^error .+ <=> >sub-name-missing</m,
        "error log-message sub missing"
    );
}

{
    my $xmlrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'xmlrpc',
        packages      => [qw/ MixedEndpoints /],
        endpoint      => '/system',
    )->build_dispatch_table();

    my $system_call = Dancer2::RPCPlugin::DispatchItem->new(
        package => 'MixedEndpoints',
        code    => MixedEndpoints->can('call_for_system'),
    );
    my $any_call = Dancer2::RPCPlugin::DispatchItem->new(
        package => 'MixedEndpoints',
        code    => MixedEndpoints->can('call_for_all_endpoints'),
    );

    is_deeply(
        $xmlrpc,
        {
            'system.call' => $system_call,
            'any.call'    => $any_call,
        },
        "picked the /system call for xmlrpc"
    ) or diag(explain($xmlrpc));

    my $jsonrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin => 'jsonrpc',
        packages => [ 'MixedEndpoints' ],
        endpoint => '/system',
    )->build_dispatch_table();
    is_deeply(
        $jsonrpc,
        {
            'system_call' => $system_call,
            'any_call'    => $any_call,
        },
        "picked the /system call for jsonrpc"
    ) or diag(explain($jsonrpc));

    my $restrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'restrpc',
        packages      => ['MixedEndpoints'],
        endpoint      => '/system',
    )->build_dispatch_table();
    is_deeply(
        $restrpc,
        {
            'call'     => $system_call,
            'any-call' => $any_call,
        },
        "picked the /system call for restrpc"
    ) or diag(explain($restrpc));
}

{
    my $xmlrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'xmlrpc',
        packages      => ['MixedEndpoints'],
        endpoint      => '/testing',
    )->build_dispatch_table();
    my $testing_call = Dancer2::RPCPlugin::DispatchItem->new(
        package => 'MixedEndpoints',
        code    => MixedEndpoints->can('call_for_testing'),
    );
    my $any_call = Dancer2::RPCPlugin::DispatchItem->new(
        package => 'MixedEndpoints',
        code    => MixedEndpoints->can('call_for_all_endpoints'),
    );

    is_deeply(
        $xmlrpc,
        {
            'testing.call' => $testing_call,
            'any.call'    => $any_call,
        },
        "picked the /testing call for xmlrpc"
    ) or diag(explain($xmlrpc));

    my $jsonrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'jsonrpc',
        packages      => ['MixedEndpoints'],
        endpoint      => '/testing',
    )->build_dispatch_table();
    is_deeply(
        $jsonrpc,
        {
            'testing_call' => $testing_call,
            'any_call'    => $any_call,
        },
        "picked the /testing call for jsonrpc"
    ) or diag(explain($jsonrpc));

    my $restrpc = Dancer2::RPCPlugin::DispatchFromPod->new(
        plugin_object => $plugin,
        plugin        => 'restrpc',
        packages      => ['MixedEndpoints'],
        endpoint      => '/testing',
    )->build_dispatch_table();
    is_deeply(
        $restrpc,
        {
            'call'     => $testing_call,
            'any-call' => $any_call,
        },
        "picked the /testing call for restrpc"
    ) or diag(explain($restrpc));
}

abeltje_done_testing();
