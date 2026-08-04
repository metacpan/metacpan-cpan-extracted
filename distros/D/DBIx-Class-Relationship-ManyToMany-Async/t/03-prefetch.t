use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

# Use TestSchemaQuoted — it declares 'group' relation (SQL reserved word)
# and requires quote_char. This tests the real-world Fondation scenario.
my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef,
    { quote_char => '"', name_sep => '.' },
    {
        workers      => 2,
        schema_class => 'TestSchemaQuoted',
        async_loop   => $loop,
        dbi_attrs    => { quote_char => '"' },
    },
);

$schema->await($schema->deploy({ add_drop_table => 0 }));

my $u_rs = $schema->resultset('User');
my $g_rs = $schema->resultset('Group');

# ─── Setup: user with 2 groups ─────────────────────────────────────────────

my $alice  = $schema->await($u_rs->create({ name => 'Alice' }));
my $admins = $schema->await($g_rs->create({ name => 'Admins' }));
my $editors = $schema->await($g_rs->create({ name => 'Editors' }));

$schema->await($alice->add_to_groups($admins));
$schema->await($alice->add_to_groups($editors));

# ─── search_with_prefetch → groups via prefetched path ─────────────────────

my $rows = $schema->await(
    $schema->search_with_prefetch('User', {},
        { user_group => 'group' })
);

# 1. search_with_prefetch returned the user
is(scalar @$rows, 1, 'one user returned via search_with_prefetch');
my $row = $rows->[0];
is($row->name, 'Alice', 'correct user');

# 2. Prefetched data is stored (collapse => 1 populates _relationship_data)
ok($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group},
    'prefetched data stored for user_group');

# 3. groups accessor uses prefetched path (no extra DB queries)
my $groups = $schema->await($row->groups);
is(scalar @$groups, 2, 'user has 2 groups via prefetched path');
my %names = map { $_->{name} => 1 } @$groups;
ok($names{Admins},  'group Admins in result');
ok($names{Editors}, 'group Editors in result');

# 4. Prefetched data is raw hashrefs (not Row objects)
is(ref $groups->[0], 'HASH', 'group is a raw hashref from prefetched data');
ok($groups->[0]{id},   'group has id');
ok($groups->[0]{name}, 'group has name');

# ─── Standard path still works (no _relationship_data) ─────────────────────

# Re-fetch without prefetch — the standard async path must still work
my $alice2 = $schema->await($u_rs->find($alice->id));
my $groups2 = $schema->await($alice2->groups);
is(scalar @$groups2, 2, 'standard async path: user has 2 groups');
# Standard path returns Row objects
ok($groups2->[0]->isa('DBIx::Class::Row'), 'standard path returns Row objects');
is($groups2->[0]->name, $groups->[0]{name}, 'same group name from both paths');

$schema->disconnect;
done_testing;
