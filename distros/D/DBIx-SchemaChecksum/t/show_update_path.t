use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

use DBIx::SchemaChecksum::App::ShowUpdatePath;

my $sc = DBIx::SchemaChecksum::App::ShowUpdatePath->new(
    dsn => MakeTmpDb->dsn,
    sqlsnippetdir=> 't/dbs/snippets2'
);

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013','pre checksum');
trap { $sc->run };

like($trap->stdout,qr/first_change/,'1st');
like($trap->stdout,qr/second_change_no/,'2nd (no change)');
like($trap->stdout,qr/second_change\.sql/,'2nd');
like($trap->stdout,qr/third_change/,'3rd');

done_testing();
