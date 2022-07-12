#! perl -I. -w
use t::Test::abeltje;

use Dancer2::RPCPlugin::PluginNames;

{
    my $pt = Dancer2::RPCPlugin::PluginNames->new();
    isa_ok($pt, 'Dancer2::RPCPlugin::PluginNames');

    my @pil = $pt->names;
    is_deeply(
        \@pil,
        [qw/jsonrpc restrpc xmlrpc/],
        "default types on construction"
    ) or diag(explain(\@pil));

    my $alts = join('|', @pil);
    is(
        $pt->regex,
        qr/(?:$alts)/,
        "Regex generated"
    );

    $pt->_reset();
}
{
    my $pt = Dancer2::RPCPlugin::PluginNames->new(qw/jsonrpc xmlrpc/);
    isa_ok($pt, 'Dancer2::RPCPlugin::PluginNames');

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

abeltje_done_testing();
