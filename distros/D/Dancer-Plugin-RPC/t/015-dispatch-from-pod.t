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
        label    => 'jsonrpc',
        packages => [qw/
            TestProject::ApiCalls
        /],
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
                label    => 'jsonrpc',
                packages => [qw/
                    TestProject::Bogus
                /],
            )
        },
        qr/Handler not found for bogus.nonexistent: TestProject::Bogus::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
}

done_testing();

