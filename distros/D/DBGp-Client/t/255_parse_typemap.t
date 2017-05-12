#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" command="typemap_get" 
                         transaction_id="1" ><map type="bool" name="bool" xsi:type="xsd:boolean"/><map type="hash" name="HASH"/>
</response>
EOT
    , {
        transaction_id  => '1',
        command         => 'typemap_get',
        is_error        => '0',
        types           => [
            {
                type        => 'bool',
                name        => 'bool',
                xsi_type    => 'xsd:boolean',
            },
            {
                type        => 'hash',
                name        => 'HASH',
                xsi_type    => undef,
            },
        ],
    },
);

done_testing();
