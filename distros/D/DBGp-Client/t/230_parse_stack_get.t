#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_get"
                                        transaction_id="12" ><stack level="0"
                                       type="file"
                                       filename="file:///home/bill/dev/dbgp/plack-middleware-dbgp/t/apps/lib/App/Base.pm"
                                       lineno="9"
                                       where="App::Base::app"/><stack level="1"
                                           type="file"
                                           filename="file:///home/bill/dev/dbgp/plack-middleware-dbgp/lib/Plack/Middleware/DBGp.pm"
                                           lineno="174"
                                           where="Plack::Middleware::DBGp::call"/>
</response>
EOT
    , {
        transaction_id  => '12',
        command         => 'stack_get',
        is_error        => '0',
        frames          => [
            {
                level       => '0',
                type        => 'file',
                filename    => 'file:///home/bill/dev/dbgp/plack-middleware-dbgp/t/apps/lib/App/Base.pm',
                lineno      => '9',
                where       => 'App::Base::app',
            },
            {
                level       => '1',
                type        => 'file',
                filename    => 'file:///home/bill/dev/dbgp/plack-middleware-dbgp/lib/Plack/Middleware/DBGp.pm',
                lineno      => '174',
                where       => 'Plack::Middleware::DBGp::call',
            },
        ],
    },
);

done_testing();
