#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" feature_name="max_depth"
                                    success="1" transaction_id="2" />
EOT
    , {
        transaction_id  => '2',
        command         => 'feature_set',
        is_error        => '0',
        feature         => 'max_depth',
        success         => '1',
    },
);

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_get" feature_name="language_name"
                                    supported="1" transaction_id="1">Perl</response>
EOT
    , {
        transaction_id  => '1',
        command         => 'feature_get',
        is_error        => '0',
        feature         => 'language_name',
        supported       => '1',
        value           => 'Perl',
    },
);

done_testing();
