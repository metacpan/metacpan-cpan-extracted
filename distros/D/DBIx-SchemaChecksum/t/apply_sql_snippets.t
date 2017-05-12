use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;
use DBD::SQLite 1.35;

my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => MakeTmpDb->dsn,
    no_prompt=>1, sqlsnippetdir=> 't/dbs/snippets');

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013','checksum after two changes ok');

trap { $sc->run };

is($trap->exit,undef,'normal exit');
like($trap->stdout,qr/Apply first_change\.sql/,'Output: prompt for first_change.sql');
like($trap->stdout,qr/Apply another_change\.sql/,'Output: prompt for another_change.sql');
like($trap->stdout,qr/post checksum OK/,'Output: post checksum OK');
like($trap->stdout,qr/No more changes/,'Output: end of tree');

my $post_checksum = $sc->checksum;
is ($post_checksum,'b1387d808800a5969f0aa9bcae2d89a0d0b4620b','checksum after two changes ok');

done_testing();

