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
is ($pre_checksum,'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013','pre checksum');

trap { $sc->apply_sql_snippets($pre_checksum) };
my @stdout = split(/\n/,$trap->stdout);
like($stdout[2],qr{Apply second_change_no_checksum_change.sql \(won't change checksum\)?},'Output includes "wont change checksum"');
like($stdout[2],qr{y/n/s},'Prompt: y/n/s/');

my $post_checksum = $sc->checksum;
is ($post_checksum,'55df89fd956a03d637b52d13281bc252896f602f','checksum after two changes ok');

done_testing();
