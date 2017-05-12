#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<init xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug"
                                appid="18450"
                                idekey="dbgp_test"
                                parent="18449"
                                thread="1"
                               language="Perl"
                               protocol_version="1.0" fileuri="file:///home/bill/perl5/bin/plackup" hostname="bandersnatch"/>
EOT
    , {
        is_error            => '0',
        fileuri             => 'file:///home/bill/perl5/bin/plackup',
        parent              => '18449',
        language            => 'Perl',
        protocol_version    => '1.0',
        hostname            => 'bandersnatch',
        appid               => '18450',
        idekey              => 'dbgp_test',
        thread              => '1',
    },
);

done_testing();
