#!perl

use lib 't/lib';
use TestManager;
use TestRole;
use TestUser;
use Test::More tests => 29;

my $mg = TestManager->new;

my $ra = TestRole->new(name => 'RA', actions => ['create_comment'], mg => $mg);
my $rc = TestRole->new(name => 'RC', actions => ['do_something'], mg => $mg);
my $rb = TestRole->new(name => 'RB', actions => ['edit_comment', 'delete_comment', 'edit_post', 'delete_post'], roles => ['RC'], mg => $mg);

my $ua = TestUser->new(name => 'UA', actions => ['create_post', ['edit_post', 'his'], ['delete_post', 'his']], roles => ['RA'], mg => $mg);
my $ub = TestUser->new(name => 'UB', is_super => 1, mg => $mg);
my $uc = TestUser->new(name => 'UC', actions => [['create_post', 'news_only']], roles => ['RA', 'RB'], mg => $mg);

$mg->add_objects($ra, $rb, $rc);

ok($ra, 'Got RA');
ok($rb, 'Got RB');
ok($rc, 'Got RC');
ok($ua, 'Got UA');
ok($ub, 'Got UB');
ok($uc, 'Got UC');

ok($ua->assigned_role('RA'), 'UA assigned to RA');
ok(!$ua->assigned_role('RB'), 'UA not assigned to RB');
ok(!$uc->assigned_role('RC'), 'UC not assigned to RC');
ok($uc->does_role('RC'), 'UC does RC');
ok(!$ua->does_role('RC'), 'UA does not do RC');
ok(!$ub->assigned_role('RA'), 'UB not assigned RA');
ok($rb->assigned_role('RC'), 'RB assigned RC');

ok($ua->can_perform('create_post'), 'UA can create posts');
ok($ua->can_perform('edit_post', 'his'), 'UA can edit his posts');
ok(!$ua->can_perform('edit_post'), 'UA cannot edit all posts');
ok($ua->can_perform('create_comment'), 'UA can create comments');

ok($ub->can_perform('create_post'), 'UB can create posts');
ok($ub->can_perform('fake_action'), 'UB can even perform fake actions');
ok($ub->can_perform('delete_post', 'his'), 'UB can delete its own posts');
ok($ub->can_perform('delete_comment', 'all'), 'UB can delete all comments');

ok($uc->can_perform('create_comment'), 'UC can create comments');
ok(!$uc->can_perform('fake_action'), 'UC cannot perform fake action');
ok($uc->can_perform('delete_comment'), 'UC can delete comments');
ok($uc->can_perform('delete_comment', 'his'), 'UC can delete its own comments');
ok($uc->can_perform('do_something'), 'UC can do something');

# let's check the _all_ and _any_ options
ok($ua->can_perform('edit_post', '_any_'), '_any_ works when UA has constraint on edit_post');
ok($ua->can_perform('create_post', '_all_'), '_all_ works when UA has no constraint on create_post');
ok($ua->can_perform('create_post', '_any_'), '_any_ also works when UA has no constrain on create_post');

done_testing();
