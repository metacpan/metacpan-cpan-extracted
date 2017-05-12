#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="break" status="break" success="1"
                               transaction_id="3" />
EOT
    , {
        transaction_id  => '3',
        command         => 'break',
        is_error        => '0',
        success         => '1',
    },
);

done_testing();
