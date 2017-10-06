#! perl -w
use strict;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Dancer::Test;

use Dancer::RPCPlugin::DispatchFromPod;
use Dancer::RPCPlugin::DispatchItem;

{
    my $dispatch = dispatch_table_from_pod(
        plugin   => 'jsonrpc',
        packages => [qw/
            TestProject::ApiCalls
        /],
        endpoint => '/testing',
    );
    is_deeply(
        $dispatch,
        {
            'api.uppercase' => dispatch_item(
                code => TestProject::ApiCalls->can('do_uppercase'),
                package => 'TestProject::ApiCalls',
            ),
        },
        "Dispatch table from POD"
    );

    like(
        exception {
            dispatch_table_from_pod(
                plugin   => 'jsonrpc',
                packages => [qw/
                    TestProject::Bogus
                /],
                endpoint => '/testing',
            )
        },
        qr/Handler not found for bogus.nonexistent: TestProject::Bogus::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
}

{
    my $xmlrpc = dispatch_table_from_pod(
        plugin => 'xmlrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/system',
    );
    my $system_call = dispatch_item(
        package => 'TestProject::MixedEndpoints',
        code    => TestProject::MixedEndpoints->can('call_for_system'),
    );
    my $any_call = dispatch_item(
        package => 'TestProject::MixedEndpoints',
        code    => TestProject::MixedEndpoints->can('call_for_all_endpoints'),
    );

    is_deeply(
        $xmlrpc,
        {
            'system.call' => $system_call,
            'any.call'    => $any_call,
        },
        "picked the /system call for xmlrpc"
    );

    my $jsonrpc = dispatch_table_from_pod(
        plugin => 'jsonrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/system',
    );
    is_deeply(
        $jsonrpc,
        {
            'system_call' => $system_call,
            'any_call'    => $any_call,
        },
        "picked the /system call for jsonrpc"
    );

    my $restrpc = dispatch_table_from_pod(
        plugin => 'restrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/system',
    );
    is_deeply(
        $restrpc,
        {
            'call'     => $system_call,
            'any-call' => $any_call,
        },
        "picked the /system call for restrpc"
    );
}

{
    my $xmlrpc = dispatch_table_from_pod(
        plugin => 'xmlrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/testing',
    );
    my $testing_call = dispatch_item(
        package => 'TestProject::MixedEndpoints',
        code    => TestProject::MixedEndpoints->can('call_for_testing'),
    );
    my $any_call = dispatch_item(
        package => 'TestProject::MixedEndpoints',
        code    => TestProject::MixedEndpoints->can('call_for_all_endpoints'),
    );

    is_deeply(
        $xmlrpc,
        {
            'testing.call' => $testing_call,
            'any.call'    => $any_call,
        },
        "picked the /testing call for xmlrpc"
    );

    my $jsonrpc = dispatch_table_from_pod(
        plugin => 'jsonrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/testing',
    );
    is_deeply(
        $jsonrpc,
        {
            'testing_call' => $testing_call,
            'any_call'    => $any_call,
        },
        "picked the /testing call for jsonrpc"
    );

    my $restrpc = dispatch_table_from_pod(
        plugin => 'restrpc',
        packages => [ 'TestProject::MixedEndpoints' ],
        endpoint => '/testing',
    );
    is_deeply(
        $restrpc,
        {
            'call'     => $testing_call,
            'any-call' => $any_call,
        },
        "picked the /testing call for restrpc"
    );
}

done_testing();
