#! perl -I. -w
use t::Test::abeltje;

use Dancer::RPCPlugin::PluginNames;

{
    my $pt = Dancer::RPCPlugin::PluginNames->new();
    isa_ok($pt, 'Dancer::RPCPlugin::PluginNames');

    is_deeply(
        [ my @pil = $pt->names ],
        [qw/jsonrpc restrpc xmlrpc/],
        "default types on construction"
    );

    my $alts = join('|', @pil);
    is(
        $pt->regex,
        qr/(?:$alts)/,
        "Regex generated"
    );

    $pt->_reset();
}
{
    my $pt = Dancer::RPCPlugin::PluginNames->new(qw/jsonrpc xmlrpc/);
    isa_ok($pt, 'Dancer::RPCPlugin::PluginNames');

    {
        is_deeply(
            [ my @pil = $pt->names ],
            [qw/jsonrpc xmlrpc/],
            "list types on construction"
        );

        my $alts = join('|', @pil);
        is(
            $pt->regex,
            qr/(?:$alts)/,
            "Regex generated"
        );
    }

    $pt->add_names('restrpc', 'soaprpc');
    {
        is_deeply(
            [ my @pil = $pt->names ],
            [qw/jsonrpc restrpc soaprpc xmlrpc/],
            "add types after construction"
        );

        my $alts = join('|', @pil);
        is(
            $pt->regex,
            qr/(?:$alts)/,
            "Regex generated " . $pt->regex
        );
    }
}

done_testing();
