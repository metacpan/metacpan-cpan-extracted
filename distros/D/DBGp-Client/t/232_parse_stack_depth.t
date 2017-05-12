#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_depth" 
                                    depth="7" transaction_id="4" />
EOT
    , {
        transaction_id  => '4',
        command         => 'stack_depth',
        is_error        => '0',
        depth           => '7',
    },
);

done_testing();
