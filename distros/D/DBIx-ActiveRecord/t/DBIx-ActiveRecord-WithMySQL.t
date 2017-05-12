use strict;
use warnings;
use Test::More skip_all => 'it requires mysql database';

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok('DBIx::ActiveRecord');
    use_ok('DBIx::ActiveRecord::Model');
};

=pod
create database ar_test;
use ar_test;
CREATE TABLE users (
  id serial NOT NULL,
  name varchar(50) NOT NULL,
  profile text,
  blood_type varchar(2),
  deleted bool,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL
) ENGINE=InnoDB;
CREATE TABLE posts (
  id serial NOT NULL,
  user_id bigint NOT NULL,
  title varchar(255) NOT NULL,
  content text,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL
) ENGINE=InnoDB;
CREATE TABLE comments (
  id serial NOT NULL,
  post_id bigint NOT NULL,
  user_id bigint NOT NULL,
  content text,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL
) ENGINE=InnoDB;
=cut

package User;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('users');
__PACKAGE__->columns(qw/id name profile blood_type deleted created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
__PACKAGE__->has_many(posts => 'Post');
__PACKAGE__->has_one(post => 'Post');
# end User Model

package Post;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('posts');
__PACKAGE__->columns(qw/id user_id title content created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
__PACKAGE__->belongs_to(user => 'User');
__PACKAGE__->has_many(comments => 'Comment');
# end Post Model

package Comment;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('comments');
__PACKAGE__->columns(qw/id post_id user_id content created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
# end Comment Model

package main;


DBIx::ActiveRecord->connect("dbi:mysql:ar_test", 'root', 'root', {});
{
    # set up
    User->unscoped->delete_all;
    ok 1;
}

{
    # basic CRUD
    my $u = User->new({name => 'hoge', profile => 'hogehoge'});
    is $u->name, 'hoge';
    is $u->profile, 'hogehoge';

    $u->name('hoge2');
    is $u->name, 'hoge2';
    $u->name();
    is $u->name, 'hoge2';
    $u->name(undef);
    is $u->name, undef;

    $u->name('hoge');
    ok !$u->id;
    $u->save; # insert!
    ok $u->id;
    $u->save; # update!
    ok $u->id;

    my $us = User->all;

    is @$us, 1;
    is $us->[0]->name, 'hoge';
    is $us->[0]->profile, 'hogehoge';

    $u = $us->[0];

    $u->name('hoge2');
    $u->save; # update!

    $us = User->all;
    is @$us, 1;
    is $us->[0]->name, 'hoge2';
    is $us->[0]->profile, 'hogehoge';

    $us->[0]->delete;

    $us = User->all;
    is @$us, 0;
}

{
    # created_at, updated_at
    my $u = User->new({name => 'test'});
    ok !$u->created_at;
    ok !$u->updated_at;
    $u->save;

    ok $u->created_at;
    ok $u->updated_at;
    is $u->created_at, $u->updated_at;

    sleep(1);

    $u->name("test2");
    $u->save;
    ok $u->created_at;
    ok $u->updated_at;
    ok $u->created_at ne $u->updated_at;
}

{
    # scoped searches
    User->create({name => 'hoge'});
    User->create({name => 'fuga'});
    User->create({name => 'hoge2', profile => 'a'});

    my $s = User->eq(name => 'hoge');
    my $us = $s->all;
    is @$us, 1;
    is $us->[0]->name, 'hoge';
    is $s->to_sql, "SELECT * FROM users WHERE name = ?";

    $s = User->eq(name => 'hoge2')->eq(profile => 'a');
    $us = $s->all;
    is @$us, 1;
    is $us->[0]->name, 'hoge2';
    is $s->to_sql, "SELECT * FROM users WHERE name = ? AND profile = ?";

    $s = User->in(id => [1,2,3])->not_null('profile')->contains(profile => 'a');
    $s->all;
    is $s->to_sql, "SELECT * FROM users WHERE id IN (?, ?, ?) AND profile IS NOT NULL AND profile LIKE ?";
}

{
     # scope
     User->default_scope(sub{ shift->ne(deleted => 1) });
     User->scope(type_a => sub{ shift->eq(blood_type => 'A') });
     User->scope(type_a_or_b => sub{ shift->in(blood_type => ['A', 'B']) });

     is(User->scoped->to_sql, "SELECT * FROM users WHERE deleted != ?");

     User->delete_all;
     User->new({deleted => 1, name => 'deleted user'})->save;

     my $us = User->all;
     is @$us, 0;
     ok 1;

     User->type_a->type_a_or_b->all;

     is(User->type_a->to_sql, "SELECT * FROM users WHERE deleted != ? AND blood_type = ?");
     is(User->type_a_or_b->to_sql, "SELECT * FROM users WHERE deleted != ? AND blood_type IN (?, ?)");
     is(User->type_a_or_b->type_a->to_sql, "SELECT * FROM users WHERE deleted != ? AND blood_type IN (?, ?) AND blood_type = ?");
}

{
    # association - belongs_to

    my $u = User->new({name => 'aaa'});
    $u->save;

    my $p = Post->new({user_id => $u->id, title => 'aaa title'});
    $p->save;
    my $s = $p->user;

    ok 1;
}

{
    # association - has_many

    my $u = User->new({name => 'aaa'});
    $u->save;
    my $s = $u->posts;

    is $s->to_sql, "SELECT * FROM posts WHERE user_id = ?";
    is_deeply [$s->_binds], [$u->id];
    ok 1;
}

{
    # association - has_one

    my $u = User->new({name => 'aaa'});
    $u->save;
    my $post = $u->post;

    ok 1;
}

{
    # joins
    my $s = User->joins('posts')->merge(Post->eq(title => 'aaa'));
    $s->all;
    is $s->to_sql, "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted != ? AND posts.title = ?";
}

{
    # select
    my $s = User->select("id", "name")->in(id => [1,2,3]);
    $s->all;
    is $s->to_sql, "SELECT id, name FROM users WHERE deleted != ? AND id IN (?, ?, ?)";

    # join and select
    $s = User->joins('posts')->merge(Post->eq(title => 'aaa'))->select("id", "name")->in(id => [1,2,3]);
    $s->all;
    is $s->to_sql, "SELECT me.id, me.name FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted != ? AND posts.title = ? AND me.id IN (?, ?, ?)";
}

{
    # order, group, limit, offset
    my $s = User->desc("created_at")->asc("id");
    is $s->to_sql, "SELECT * FROM users WHERE deleted != ? ORDER BY created_at DESC, id";
    $s->all;

    $s = User->group("blood_type");
    is $s->to_sql, "SELECT * FROM users WHERE deleted != ? GROUP BY blood_type";
    $s->all;

    $s = User->limit(5)->offset(2);
    is $s->to_sql, "SELECT * FROM users WHERE deleted != ? LIMIT ? OFFSET ?";
    $s->all;

    $s = User->eq(id => 1)->lock;
    is $s->to_sql, "SELECT * FROM users WHERE deleted != ? AND id = ? FOR UPDATE";
    $s->all;
}

{
    User->first;
    User->last;
    ok 1;
}

{
    # transaction
    User->transaction(sub {
    });
    User->transaction(sub {
      die;
    });
}

{
    # scope cache
#    print STDERR "*** cache test ***\n";
    User->all;
    User->all;

#    print STDERR "*** all only ***\n";
    my $s = User->scoped;
    $s->all;
    $s->first;
    $s->last;

#    print STDERR "*** first, last, all ***\n";
    $s = User->scoped;
    $s->first;
    $s->last;
    $s->first;
    $s->last;
    $s->all;
    $s->all;

#    print STDERR "*** new scope! ***\n";
    $s->eq(id => 1)->all;

    ok 1;
}
# includes
{

#    print STDERR "*** includes user => posts ***\n";
    User->unscoped->delete_all;
    Post->unscoped->delete_all;
    my $u1 = User->new({name => 'hoge', deleted => 0});
    my $u2 = User->new({name => 'fuga', deleted => 0});
    $u1->save;
    $u2->save;

    Post->new({title => 'hoge 01', user_id => $u1->id})->save;
    Post->new({title => 'hoge 02', user_id => $u1->id})->save;
    Post->new({title => 'hoge 03', user_id => $u1->id})->save;
    Post->new({title => 'hoge 04', user_id => $u1->id})->save;
    Post->new({title => 'fuga 01', user_id => $u2->id})->save;
    Post->new({title => 'fuga 02', user_id => $u2->id})->save;

    my $us = User->includes('posts')->all;
    is @{$us->[0]->posts->all}, 4;
    is @{$us->[1]->posts->all}, 2;

    ok 1;
}

{
    # array operator
    ok @{User->scoped};

    my $users = User->includes('posts');
    foreach my $u (@$users) {
        foreach my $p (@{$u->posts}) {
            ok $u;
            ok $p;
        }
    }
    ok 1;
}

{
    # nested joins

    my $users = User->joins('posts', 'comments');
    ok @{$users};

    is $users->to_sql, "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id LEFT JOIN comments comments ON comments.post_id = posts.id WHERE me.deleted != ?";
}

{
    # nested includes
    User->unscoped->delete_all;
    Post->unscoped->delete_all;
    Comment->delete_all;

    my $u1 = User->create({name => 'hoge', deleted => 0});
    my $u2 = User->create({name => 'fuga', deleted => 0});

    my $p1 = Post->create({user_id => $u1->id, title => "hoge 01"});
    Comment->create({content => 'hoge 01 com1', post_id => $p1->id, user_id => $u2->id});
    Comment->create({content => 'hoge 01 com2', post_id => $p1->id, user_id => $u2->id});
    Comment->create({content => 'hoge 01 com3', post_id => $p1->id, user_id => $u2->id});
    Comment->create({content => 'hoge 01 com4', post_id => $p1->id, user_id => $u2->id});

    my $p2 = Post->create({user_id => $u1->id, title => "hoge 02"});
    Comment->create({content => 'hoge 02 com1', post_id => $p2->id, user_id => $u2->id});
    Comment->create({content => 'hoge 02 com2', post_id => $p2->id, user_id => $u2->id});

    my $p3 = Post->create({user_id => $u2->id, title => "fuga 01"});
    Comment->create({content => 'fuga 01 com1', post_id => $p3->id, user_id => $u1->id});
    Comment->create({content => 'fuga 01 com2', post_id => $p3->id, user_id => $u1->id});

    my $users = User->includes('posts', 'comments');
    ok @{$users};
}

{
    # count
    Post->count;
    Post->eq(title => 5)->count;
    Post->joins('user')->merge(User->eq(id => 3))->count;

}

done_testing;
