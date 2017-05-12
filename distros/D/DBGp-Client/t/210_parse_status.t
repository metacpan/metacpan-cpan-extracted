#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="status" status="break"
                                    reason="ok" transaction_id="6"/>
EOT
    , {
        transaction_id  => '6',
        command         => 'status',
        is_error        => '0',
        reason          => 'ok',
        status          => 'break',
    },
);

done_testing();
