#! perl -I. -w
use t::Test::abeltje;

use Dancer2::RPCPlugin::DispatchMethodList;

note('Instantiate');
{
    my $dml = Dancer2::RPCPlugin::DispatchMethodList->new();
    isa_ok($dml, 'Dancer2::RPCPlugin::DispatchMethodList');

    my $methods = {
        jsonrpc => { '/endpoint_j' => [qw/ method1 method2 /] },
        xmlrpc  => { '/endpoint_x' => [qw/ method3 method4 /] },
    };
    for my $rpc (keys %$methods) {
        for my $ep (keys %{$methods->{$rpc}}) {
            $dml->set_partial(
                protocol => $rpc,
                endpoint => $ep,
                methods  => $methods->{$rpc}{$ep}
            );
        }
    }

    is_deeply(
        $dml->list_methods('any'),
        $methods,
        "all methods (any)"
    );

    is_deeply(
        $dml->list_methods('jsonrpc'),
        $methods->{jsonrpc},
        "list_methods(jsonrpc)"
    );

    is_deeply(
        $dml->list_methods('xmlrpc'),
        $methods->{xmlrpc},
        "list_methods(xmlrpc)"
    );
}

note('Instantiate again');
{
    my $dml = Dancer2::RPCPlugin::DispatchMethodList->new();
    isa_ok($dml, 'Dancer2::RPCPlugin::DispatchMethodList');

    my $methods = {
        jsonrpc => { '/endpoint_j' => [qw/ method1 method2 /] },
        xmlrpc  => { '/endpoint_x' => [qw/ method3 method4 /] },
    };

    is_deeply(
        $dml->list_methods('any'),
        $methods,
        "all methods (any)"
    );

    is_deeply(
        $dml->list_methods('jsonrpc'),
        $methods->{jsonrpc},
        "list_methods(jsonrpc)"
    );

    is_deeply(
        $dml->list_methods('xmlrpc'),
        $methods->{xmlrpc},
        "list_methods(xmlrpc)"
    );
};

abeltje_done_testing();
