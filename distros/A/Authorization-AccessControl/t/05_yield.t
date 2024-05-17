use v5.26;
use warnings;

use Test2::V0;

use Authorization::AccessControl qw(acl);

use experimental qw(signatures);

use constant true  => !0;
use constant false => !1;

acl->role('admin')->grant(User => 'read')->grant(User => 'update')->grant(User => 'delete')->grant(Post => 'delete')->role('super')
  ->grant(User => 'ban')->role->grant(Post => 'create')->grant(Post => 'read', {own => true})
  ->grant(Post => 'delete', {own => true});

my $r = [];
acl->request->with_action('read')->with_resource('Post')->yield(sub() {'post'})->denied(sub {push($r->@*, "d")});
is($r, ['d'], 'yield without necessary attributes');

$r = [];
acl->request->with_action('read')->with_resource('Post')->with_attributes({own => true})->yield(sub() {'post'})
  ->granted(sub($entity) {push($r->@*, $entity)});
is($r, ['post'], 'yield with necessary attributes');

$r = [];
acl->request->with_action('read')->with_resource('Post')->with_get_attrs(sub($obj) {return {own => true}})->yield(sub() {'post'})
  ->granted(sub($entity) {push($r->@*, $entity)});
is($r, ['post'], 'yield with dynamic attributes');

$r = [];
acl->request->with_action('read')->with_resource('Post')->with_get_attrs(sub($obj) {return {own => false}})->yield(sub() {'post'})
  ->denied(sub() {push($r->@*, 'd')});
is($r, ['d'], 'yield with incorrect dynamic attributes');

my $post = {id => 7, deleted_at => undef};
ok(
  !dies {
    acl->request->with_resource('Post')->with_action('delete')->with_attributes({own => true})->yield(sub() {$post})
      ->granted(sub($obj) {$obj->{deleted_at} = '2024-05-09T12:34:56'})
  },
  "ensure yielded value isn't getting marked read-only"
);

done_testing;
