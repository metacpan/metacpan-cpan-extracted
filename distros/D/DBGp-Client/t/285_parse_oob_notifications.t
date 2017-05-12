#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<stream xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug"
                                   type="stdout"
                                   encoding="base64">U3RlcCAxCg==
</stream>
EOT
    , {
        is_oob          => 1,
        is_stream       => 1,
        is_notification => 0,
        type            => 'stdout',
        content         => "Step 1\n",
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<notify xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug"
                                   name="stdin" />
EOT
    , {
        is_oob          => 1,
        is_stream       => 0,
        is_notification => 1,
        name            => 'stdin',
    },
);

done_testing();
