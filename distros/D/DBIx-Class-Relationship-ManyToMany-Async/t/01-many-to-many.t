use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    {
        workers      => 2,
        schema_class => 'TestSchema',
        async_loop   => $loop,
    },
);

$schema->await($schema->deploy({ add_drop_table => 0 }));

my $u_rs = $schema->resultset('User');
my $g_rs = $schema->resultset('Group');

# ─── Setup ───────────────────────────────────────────────────────────────────

my $user_alice  = $schema->await($u_rs->create({ name => 'Alice' }));
my $grp_admins  = $schema->await($g_rs->create({ name => 'Admins' }));
my $grp_editors = $schema->await($g_rs->create({ name => 'Editors' }));

ok($user_alice->id,  'user created');
ok($grp_admins->id,  'group Admins created');
ok($grp_editors->id, 'group Editors created');

# ─── add_to_groups / groups ──────────────────────────────────────────────────

$schema->await($user_alice->add_to_groups($grp_admins));
$schema->await($user_alice->add_to_groups($grp_editors));

my @groups = @{ $schema->await($user_alice->groups) };
is(scalar @groups, 2, 'user has 2 groups');
my %names = map { $_->name => 1 } @groups;
ok($names{Admins},  'user is in Admins');
ok($names{Editors}, 'user is in Editors');

# ─── remove_from_groups ──────────────────────────────────────────────────────

$schema->await($user_alice->remove_from_groups($grp_editors));

my @remaining = @{ $schema->await($user_alice->groups) };
is(scalar @remaining, 1, 'user has 1 group after removal');
is($remaining[0]->name, 'Admins', 'remaining group is Admins');

# ─── set_groups ──────────────────────────────────────────────────────────────

my $grp_viewers = $schema->await($g_rs->create({ name => 'Viewers' }));
$schema->await($user_alice->set_groups([$grp_viewers]));
my @final = @{ $schema->await($user_alice->groups) };
is(scalar @final, 1, 'user has 1 group after set_groups');
is($final[0]->name, 'Viewers', 'user is now in Viewers');

# ─── set_groups with list arguments ──────────────────────────────────────────

my $grp_x = $schema->await($g_rs->create({ name => 'X' }));
my $grp_y = $schema->await($g_rs->create({ name => 'Y' }));
$schema->await($user_alice->set_groups($grp_x, $grp_y));
my @list = @{ $schema->await($user_alice->groups) };
is(scalar @list, 2, 'user has 2 groups after list set_groups');
my %lnames = map { $_->name => 1 } @list;
ok($lnames{X}, 'user is in X');
ok($lnames{Y}, 'user is in Y');

# ─── Reverse direction: group->users ─────────────────────────────────────────
# Alice is now in X and Y, so Admins should have 0 users

my @admins_users = @{ $schema->await($grp_admins->users) };
is(scalar @admins_users, 0, 'Admins group has 0 users (alice was reassigned)');

$schema->await($user_alice->set_groups([$grp_admins]));
my @admins2 = @{ $schema->await($grp_admins->users) };
is(scalar @admins2, 1, 'Admins group has 1 user after reassign');
is($admins2[0]->name, 'Alice', 'user is Alice');

$schema->disconnect;
done_testing;
