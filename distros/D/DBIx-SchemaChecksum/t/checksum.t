use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

use DBIx::SchemaChecksum::App::Checksum;

{
    my $sc = DBIx::SchemaChecksum::App::Checksum->new(
        dsn => MakeTmpDb->dsn,
    );
    trap { $sc->run };
    like($trap->stdout,qr/ee3a4db19fc06296306738ee6d4cdfd1204adf8c/,'got checksum');
}

{
    my $sc2 = DBIx::SchemaChecksum::App::Checksum->new(
        dsn => MakeTmpDb->dsn,
        show_dump=>1
    );
    trap { $sc2->run };
    like($trap->stdout,qr/ee3a4db19fc06296306738ee6d4cdfd1204adf8c/,'got checksum');
    like($trap->stdout,qr/main\.first_table/,'got DBI data');
}

done_testing();
