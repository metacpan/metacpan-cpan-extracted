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
is ($pre_checksum,'ee3a4db19fc06296306738ee6d4cdfd1204adf8c','checksum after two changes ok');

trap { $sc->run };

is($trap->exit,undef,'normal exit');
like($trap->stdout,qr/Apply first_change\.sql/,'Output: prompt for first_change.sql');
like($trap->stdout,qr/Apply another_change\.sql/,'Output: prompt for another_change.sql');
like($trap->stdout,qr/post checksum OK/,'Output: post checksum OK');
like($trap->stdout,qr/No more changes/,'Output: end of tree');

my $post_checksum = $sc->checksum;
is ($post_checksum,'b96b98d2a80eb1c812a4f1d29a43e40eb4928078','checksum after two changes ok');

done_testing();

