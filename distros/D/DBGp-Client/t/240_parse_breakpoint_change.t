#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="breakpoint_set"
                                    state="enabled" id="1" transaction_id="2" />
EOT
    , {
        transaction_id  => '2',
        command         => 'breakpoint_set',
        is_error        => '0',
        state           => 'enabled',
        id              => '1',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="breakpoint_remove"
                                         transaction_id="4" />
EOT
    , {
        transaction_id  => '4',
        command         => 'breakpoint_remove',
        is_error        => '0',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="breakpoint_update" 
                                            transaction_id="3" ><breakpoint
                             id="0"
                             type="line" filename="file:///home/bill/dev/dbgp/plack-middleware-dbgp/t/apps/lib/App/Base.pm" line="13" lineno="13" state="enabled" temporary="0" hit_count ="0" hit_value ="0"></breakpoint>

</response>
EOT
    , {
        transaction_id  => '3',
        command         => 'breakpoint_update',
        is_error        => '0',
        breakpoint      => {
            type          => 'line',
            filename      => 'file:///home/bill/dev/dbgp/plack-middleware-dbgp/t/apps/lib/App/Base.pm',
            lineno        => '13',
            state         => 'enabled',
            function      => undef,
            hit_count     => '0',
            hit_value     => '0',
            hit_condition => undef,
            exception     => undef,
            expression    => '',
        },
    },
);

done_testing();
