#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="eval"
                         transaction_id="25" ><property name="$name" fullname="$name" encoding="base64" type="string" constant="0" children="0" size="5" >Zm9v
</property>
</response>
EOT
    , {
        transaction_id  => '25',
        command         => 'eval',
        success         => undef,
        result          => {
            name        => '$name',
            fullname    => '$name',
            classname   => undef,
            page        => undef,
            pagesize    => undef,
            type        => 'string',
            facet       => undef,
            children    => '0',
            numchildren => 0,
            key         => undef,
            address     => undef,
            value       => 'foo',
        },
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="eval"
                         transaction_id="25" />
EOT
    , {
        transaction_id  => '25',
        command         => 'eval',
        success         => undef,
        result          => undef,
    },
);

done_testing();
