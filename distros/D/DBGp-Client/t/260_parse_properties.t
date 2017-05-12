#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="property_get" 
                         transaction_id="7" ><property name="@foo" fullname="@foo" type="ARRAY" constant="0" children="1" numchildren="2" address="13317e0" size="0" page="0" pagesize="10"><property
   fullname="$foo[0]" name="[0]" encoding="base64" type="string" constant="0" children="0" size="5" ><value encoding="base64"><![CDATA[YQ==
]]></value>
</property><property
   name="[1]" fullname="$foo[1]" encoding="base64" type="string" constant="0" children="0" size="5" ><value encoding="base64"><![CDATA[Yg==
]]></value>
</property></property>

</response>
EOT
    , {
        transaction_id  => '7',
        command         => 'property_get',
        is_error        => '0',
        property        => {
            name        => '@foo',
            fullname    => '@foo',
            classname   => undef,
            page        => '0',
            pagesize    => '10',
            type        => 'ARRAY',
            facet       => undef,
            children    => '1',
            numchildren => '2',
            key         => undef,
            address     => '13317e0',
            childs      => [
                {
                    name        => '[0]',
                    fullname    => '$foo[0]',
                    classname   => undef,
                    page        => undef,
                    pagesize    => undef,
                    type        => 'string',
                    facet       => undef,
                    children    => '0',
                    numchildren => 0,
                    key         => undef,
                    address     => undef,
                    value       => 'a',
                },
                {
                    name        => '[1]',
                    fullname    => '$foo[1]',
                    classname   => undef,
                    page        => undef,
                    pagesize    => undef,
                    type        => 'string',
                    facet       => undef,
                    children    => '0',
                    numchildren => 0,
                    key         => undef,
                    address     => undef,
                    value       => 'b',
                },
            ],
        },
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="property_value" 
                      transaction_id="8"
                      name="@foo" fullname="@foo" type="ARRAY" constant="0" children="1" numchildren="2" address="13317e0" size="0" page="0" pagesize="10"><property
   fullname="$foo[0]" name="[0]" encoding="base64" type="string" constant="0" children="0" size="5" ><value encoding="base64"><![CDATA[YQ==
]]></value>
</property><property
   name="[1]" fullname="$foo[1]" encoding="base64" type="string" constant="0" children="0" size="5" ><value encoding="base64"><![CDATA[Yg==
]]></value>
</property></response>
EOT
    , {
        transaction_id  => '8',
        command         => 'property_value',
        is_error        => '0',
        size            => '0',
        value           => undef,
        name        => '@foo',
        fullname    => '@foo',
        classname   => undef,
        page        => '0',
        pagesize    => '10',
        type        => 'ARRAY',
        facet       => undef,
        children    => '1',
        numchildren => '2',
        key         => undef,
        address     => '13317e0',
        childs      => [
            {
                name        => '[0]',
                fullname    => '$foo[0]',
                classname   => undef,
                page        => undef,
                pagesize    => undef,
                type        => 'string',
                facet       => undef,
                children    => '0',
                numchildren => 0,
                key         => undef,
                address     => undef,
                value       => 'a',
            },
            {
                name        => '[1]',
                fullname    => '$foo[1]',
                classname   => undef,
                page        => undef,
                pagesize    => undef,
                type        => 'string',
                facet       => undef,
                children    => '0',
                numchildren => 0,
                key         => undef,
                address     => undef,
                value       => 'b',
            },
        ],
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="property_value" 
                      transaction_id="8"
                      size="25"
                      encoding="base64">KCJhIiwgImIiLCAiYyIsICJkIiwgImUiKQ==
</response>
EOT
    , {
        transaction_id  => '8',
        command         => 'property_value',
        is_error        => '0',
        size            => '25',
        value           => '("a", "b", "c", "d", "e")',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="property_set" 
                                                transaction_id="9" success="1" />
EOT
    , {
        transaction_id  => '9',
        command         => 'property_set',
        is_error        => '0',
        success         => '1',
    },
);

done_testing();
