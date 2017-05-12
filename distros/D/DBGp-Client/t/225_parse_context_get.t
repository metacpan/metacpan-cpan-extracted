#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get"
                         context_id="0"
                         transaction_id="19" ><property name="@_" fullname="@_" type="ARRAY" constant="0" children="0" ></property>
<property name="$env" fullname="$env" type="HASH" constant="0" children="1" numchildren="3" address="27c7c20" size="0" page="0" pagesize="128"><property
   name="-&gt;{HTTP_ACCEPT}" fullname="$env-&gt;{HTTP_ACCEPT}" encoding="base64" type="string" constant="0" children="0" size="102" >dGV4dC9odG1sLGFwcGxpY2F0aW9uL3hodG1sK3htbCxhcHBsaWNhdGlvbi94bWw7cT0wLjksaW1h
Z2Uvd2VicCwqLyo7cT0wLjg=
</property><property
   fullname="$env-&gt;{HTTP_ACCEPT_ENCODING}" name="-&gt;{HTTP_ACCEPT_ENCODING}" encoding="base64" type="string" constant="0" children="0" size="29" >Z3ppcCwgZGVmbGF0ZSwgc2RjaA==
</property><property
   name="-&gt;{HTTP_ACCEPT_LANGUAGE}" fullname="$env-&gt;{HTTP_ACCEPT_LANGUAGE}" encoding="base64" type="string" constant="0" children="0" size="45" >ZW4tVVMsZW47cT0wLjgsZnI7cT0wLjYsaXQ7cT0wLjQ=
</property></property>
<property name="$name" fullname="$name" encoding="base64" type="string" constant="0" children="0" size="5" >Zm9v
</property>

</response>
EOT
    , {
        transaction_id  => '19',
        command         => 'context_get',
        is_error        => '0',
        context_id      => '0',
        values          => [
            {
                name        => '@_',
                fullname    => '@_',
                classname   => undef,
                page        => undef,
                pagesize    => undef,
                type        => 'ARRAY',
                facet       => undef,
                children    => '0',
                numchildren => 0,
                key         => undef,
                address     => undef,
                childs      => [
                ],
            },
            {
                name        => '$env',
                fullname    => '$env',
                classname   => undef,
                page        => '0',
                pagesize    => '128',
                type        => 'HASH',
                facet       => undef,
                children    => '1',
                numchildren => '3',
                key         => undef,
                address     => '27c7c20',
                childs      => [
                    {
                        name        => '->{HTTP_ACCEPT}',
                        fullname    => '$env->{HTTP_ACCEPT}',
                        classname   => undef,
                        page        => undef,
                        pagesize    => undef,
                        type        => 'string',
                        facet       => undef,
                        children    => '0',
                        numchildren => 0,
                        key         => undef,
                        address     => undef,
                        value       => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                    },
                    {
                        name        => '->{HTTP_ACCEPT_ENCODING}',
                        fullname    => '$env->{HTTP_ACCEPT_ENCODING}',
                        classname   => undef,
                        page        => undef,
                        pagesize    => undef,
                        type        => 'string',
                        facet       => undef,
                        children    => '0',
                        numchildren => 0,
                        key         => undef,
                        address     => undef,
                        value       => 'gzip, deflate, sdch',
                    },
                    {
                        name        => '->{HTTP_ACCEPT_LANGUAGE}',
                        fullname    => '$env->{HTTP_ACCEPT_LANGUAGE}',
                        classname   => undef,
                        page        => undef,
                        pagesize    => undef,
                        type        => 'string',
                        facet       => undef,
                        children    => '0',
                        numchildren => 0,
                        key         => undef,
                        address     => undef,
                        value       => 'en-US,en;q=0.8,fr;q=0.6,it;q=0.4',
                    },
                ],
            },
            {
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
        ],
    },
);

done_testing();
