#!/usr/bin/perl

use t::lib::Test;

dbgp_response_cmp(<<'EOT'
<?xml version="1.0" encoding="UTF-8" ?>
<response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="source" 
                                     transaction_id="5"
                                     success="1"
                                     encoding="base64"
                                     >c3ViIGZvbyB7CiAgICAkX1swXSArIDEKfQoKbXkgQGZvbyA9IHF3KGEgYiBjIGQgZSk7CmZvbygp
Owo=
</response>
EOT
    , {
        transaction_id  => '5',
        command         => 'source',
        is_error        => '0',
        success         => '1',
        source          => <<'EOT',
sub foo {
    $_[0] + 1
}

my @foo = qw(a b c d e);
foo();
EOT
    },
);

done_testing();
