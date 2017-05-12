#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_names"
                         transaction_id="7" ><context name="Locals" id="0" />
<context name="Globals" id="1" />
<context name="Arguments" id="2" />
<context name="Special" id="3" />

</response>
EOT
    , {
        transaction_id  => '7',
        command         => 'context_names',
        is_error        => '0',
        contexts        => [
            {
                name => 'Locals',
                id   => '0',
            },
            {
                name => 'Globals',
                id   => '1',
            },
            {
                name => 'Arguments',
                id   => '2',
            },
            {
                name => 'Special',
                id   => '3',
            },
        ],
    },
);

done_testing();
