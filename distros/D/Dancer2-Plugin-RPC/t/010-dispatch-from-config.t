#! perl -I. -w
use t::Test::abeltje;

use Test::MockObject;

use Dancer2::RPCPlugin::DispatchFromConfig;
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
    note('Working dispatch table from configuration');
    my $builder = Dancer2::RPCPlugin::DispatchFromConfig->new(
        plugin_object => $plugin,
        plugin        => 'xmlrpc',
        endpoint      => '/xmlrpc',
        config        => {
            '/xmlrpc' => {
                'MyAppCode' => {
                    'system.ping'    => 'do_ping',
                    'system.version' => 'do_version',
                }
            }
        }
    );
    isa_ok($builder, 'Dancer2::RPCPlugin::DispatchFromConfig', "Builder")
        or diag(ref $builder);
    my $dispatch = $builder->build_dispatch_table();
    is_deeply(
        $dispatch,
        {
            'system.ping'    => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_ping'),
                package => 'MyAppCode',
            ),
            'system.version' => Dancer2::RPCPlugin::DispatchItem->new(
                code => MyAppCode->can('do_version'),
                package => 'MyAppCode',
            ),
        },
        "Dispatch from (YAML)-config"
    );
}

{
    note('Adding non existing code, fails');
    like(
        exception {
            (
                my $builder = Dancer2::RPCPlugin::DispatchFromConfig->new(
                    plugin_object => $plugin,
                    plugin        => 'xmlrpc',
                    endpoint      => '/xmlrpc',
                    config        => {
                        '/xmlrpc' => {
                            'MyAppCode' => {
                                'system.nonexistent' => 'nonexistent',
                            }
                        }
                    },
                )
            )->build_dispatch_table();
        },
        qr/Handler not found for system.nonexistent: MyAppCode::nonexistent doesn't seem to exist/,
        "Setting a non-existent dispatch target throws an exception"
    );
}

{
    note('Adding non existing package, fails');
    like(
        exception {
            (
                my $builder = Dancer2::RPCPlugin::DispatchFromConfig->new(
                    plugin_object => $plugin,
                    plugin        => 'xmlrpc',
                    endpoint      => '/xmlrpc',
                    config        => {
                        '/xmlrpc' => {
                            'MyNotExistingApp' => {
                                'system.nonexistent' => 'nonexistent',
                            }
                        }
                    },
                )
            )->build_dispatch_table();
        },
        qr/Cannot load MyNotExistingApp .+ in build_dispatch_table_from_config/s,
        "Using a non existing package throws an exception"
    );
}

abeltje_done_testing();
