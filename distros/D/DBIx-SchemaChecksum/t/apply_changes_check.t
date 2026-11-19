use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;

my $dsn = MakeTmpDb->dsn;
my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => $dsn, sqlsnippetdir => 't/dbs/snippets', check => 1);
my $initial = $sc->checksum;
trap { $sc->run };
is($trap->exit, 1, 'pending changes fail');
like($trap->stdout, qr/unapplied changes/, 'pending changes explained');
is($sc->checksum, $initial, 'check does not apply changes');

my $apply = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => $dsn, sqlsnippetdir => 't/dbs/snippets', no_prompt => 1);
trap { $apply->run };
$sc->reset_checksum;
trap { $sc->run };
is($trap->exit, undef, 'up-to-date check returns normally');
like($trap->stdout, qr/current checksum matches last changes/, 'success reported');

my $unknown = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => $dsn, sqlsnippetdir => 't/dbs/no_snippets', check => 1);
trap { $unknown->run };
is($trap->exit, 1, 'empty changes tree fails');
like($trap->stdout, qr/no changes match current checksum/, 'missing match explained');

my $same = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => $dsn, sqlsnippetdir => 't/dbs/snippets2', check => 1);
trap { $same->run };
is($trap->exit, 1, 'intermediate post-checksum fails');
like($trap->stdout, qr/unapplied changes/, 'remaining changes explained');

{
    no warnings 'redefine';
    local *DBIx::SchemaChecksum::App::ApplyChanges::checksum = sub { '8f6643a8fc8b4e47caa30c70da5635f366075ea1' };
    trap { $same->run };
    is($trap->exit, 1, 'same-checksum changes are treated as pending');
    like($trap->stdout, qr/unapplied changes/, 'same-checksum changes explained');
}
{
    no warnings 'redefine';
    local *DBIx::SchemaChecksum::App::ApplyChanges::checksum = sub { 'unknown' };
    trap { $same->run };
    is($trap->exit, 1, 'unknown checksum fails');
    like($trap->stdout, qr/no changes match current checksum/, 'unknown checksum explained');
}

done_testing();
