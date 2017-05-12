#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stdout" 
                                            transaction_id="6" success="1" />
EOT
    , {
        transaction_id  => '6',
        command         => 'stdout',
        is_error        => '0',
        success         => '1',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stderr" 
                                            transaction_id="7" success="1" />
EOT
    , {
        transaction_id  => '7',
        command         => 'stderr',
        is_error        => '0',
        success         => '1',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stdin" 
                                            transaction_id="8" success="1" />
EOT
    , {
        transaction_id  => '8',
        command         => 'stdin',
        is_error        => '0',
        success         => '1',
    },
);

done_testing();
