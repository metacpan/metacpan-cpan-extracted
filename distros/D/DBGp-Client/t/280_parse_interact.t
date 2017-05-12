#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="interact" 
                                    transaction_id="8"
                                    status="interactive"
                                    more="1"
                                    prompt="%"
                                    />
EOT
    , {
        transaction_id  => '8',
        command         => 'interact',
        is_error        => '0',
        status          => 'interactive',
        more            => '1',
        prompt          => '%',
    },
);

done_testing();
