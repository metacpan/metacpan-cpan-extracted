use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => MakeTmpDb->dsn,
    no_prompt=>1, sqlsnippetdir=> 't/dbs/snippets2');

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'ee3a4db19fc06296306738ee6d4cdfd1204adf8c','pre checksum');

trap { $sc->apply_sql_snippets($pre_checksum) };
my @stdout = split(/\n/,$trap->stdout);
like($stdout[2],qr{Apply second_change_no_checksum_change.sql \(won't change checksum\)?},'Output includes "wont change checksum"');
like($stdout[2],qr{y/n/s},'Prompt: y/n/s/');

my $post_checksum = $sc->checksum;
is ($post_checksum,'dc7198bc9b458194fd6584a090e219d38d9ef6a7','checksum after two changes ok');

done_testing();
