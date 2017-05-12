#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="breakpoint_remove"
                        transaction_id="3" ><error code="205" apperr="4">
                        <message>Problems deleting breakpoint ID 0</message>
                        </error></response>
EOT
    , {
        transaction_id  => '3',
        command         => 'breakpoint_remove',
        is_error        => '1',
        code            => '205',
        apperr          => '4',
        message         => 'Problems deleting breakpoint ID 0',
    },
);

done_testing();
