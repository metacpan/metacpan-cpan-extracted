#! perl -I. -w
use t::Test::abeltje;

use Dancer::Test;

use Dancer::RPCPlugin::DispatchFromConfig;
use Dancer::RPCPlugin::DispatchItem;

{
    my $dispatch = dispatch_table_from_config(
        plugin   => 'xmlrpc',
        endpoint => '/xmlrpc',
        config   => {
            '/xmlrpc' => {
                'TestProject::SystemCalls' => {
                    'system.ping'    => 'do_ping',
                    'system.version' => 'do_version',
                }
            }
        }
    );
    is_deeply(
        $dispatch,
        {
            'system.ping'    => dispatch_item(
                code => TestProject::SystemCalls->can('do_ping'),
                package => 'TestProject::SystemCalls',
            ),
            'system.version' => dispatch_item(
                code => TestProject::SystemCalls->can('do_version'),
                package => 'TestProject::SystemCalls',
            ),
        },
        "Dispatch from YAML-config"
    );

    like(
        exception {
            dispatch_table_from_config(
                plugin   => 'xmlrpc',
                endpoint => '/xmlrpc',
                config   => {
                    '/xmlrpc' => {
                        'TestProject::SystemCalls' => {
                            'system.nonexistent' => 'nonexistent',
                        }
                    }
                },
            );
        },
        qr/Handler not found for system.nonexistent: TestProject::SystemCalls::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
}

done_testing();
