use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";
use POSIX;

BEGIN {
    use_ok('DBIx::ActiveRecord');
    use_ok('DBIx::ActiveRecord::Model');
};

package User;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('users');
__PACKAGE__->columns(qw/id name deleted created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
__PACKAGE__->has_many(posts => 'Post');
__PACKAGE__->has_many(comments => 'Comment');
__PACKAGE__->has_one(comment_one => 'Comment');
__PACKAGE__->default_scope(sub{ shift->eq(deleted => 0) });
# end User Model

package Post;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('posts');
__PACKAGE__->columns(qw/id user_id tag title created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
__PACKAGE__->belongs_to(user => 'User');
__PACKAGE__->has_many(comments => 'Comment');
__PACKAGE__->scope(tag01 => sub { shift->eq(tag => "01") });
__PACKAGE__->scope(tag02 => sub { shift->eq(tag => "02") });
# end Post Model

package Comment;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('comments');
__PACKAGE__->columns(qw/id post_id user_id content created_at updated_at/);
__PACKAGE__->primary_keys(qw/id/);
__PACKAGE__->belongs_to(post => 'Post');
# end Comment Model

package main;

# mock and custom expectations
my @results;
package Mock::DBI;
our $INST;
sub new {$INST = bless {actuals => []}, shift};
sub prepare {
    my ($self, $sql) = @_;
    Mock::Statement->new($self, $sql);
}

package Mock::Statement;
sub new {
    my ($self, $dbi, $sql) = @_;
    bless {dbi => $dbi, sql => $sql}, $self;
}
sub execute {
    my $self = shift;
    push @{$self->{dbi}->{actuals}}, [$self->{sql}, @_];
    $self->{res} = shift @results || [];
}
sub fetchrow_hashref {
    my $self = shift;
    shift @{$self->{res}};
}
sub fetchrow_arrayref {}

package main;

sub is_issue_sql {
    my $actual = shift @{$Mock::DBI::INST->{actuals}};
    is_deeply $actual, \@_;
}

sub is_nothing_more {
    is_deeply $Mock::DBI::INST->{actuals}, [];
}

sub set_result {
    push @results, \@_;
}

sub freeze_timestamp {
    my $coderef = shift;
    my $add_time = shift || 0;
    my @ltime = localtime(time() + $add_time);
    no warnings "once";
    local *main::localtime = sub {@ltime};
    $coderef->(POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime));
}

# DBIx::ActiveRecord->connect("dbi:mysql:ar_test", 'root', '', {});
DBIx::ActiveRecord->init;
$DBIx::ActiveRecord::DBH = Mock::DBI->new;

subtest default_scope => sub {
    User->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ?", 0;
    is_nothing_more;
};

subtest create_update => sub {
    my $u;
    freeze_timestamp(sub {
        my $now = shift;
        $u = User->create({name => 'hoge'});
        is_issue_sql "INSERT INTO users (name, created_at, updated_at) VALUES (?, ?, ?)", 'hoge', $now, $now;
        is_nothing_more;
    });

    freeze_timestamp(sub {
        my $now = shift;
        $u->{-org}->{id} = 1; # for test
        $u->name("fuga");
        $u->save;
        is_issue_sql "UPDATE users SET name = ?, updated_at = ? WHERE id = ?", 'fuga', $now, 1;
        is_nothing_more;
    }, 10);
};

subtest delete => sub {
    freeze_timestamp(sub {
        my $now = shift;
        my $u = User->create({name => 'hoge'});
        $u->{-org}->{id} = 1; # for test
        $u->delete;
        is_issue_sql "INSERT INTO users (name, created_at, updated_at) VALUES (?, ?, ?)", 'hoge', $now, $now;
        is_issue_sql "DELETE FROM users WHERE id = ?", 1;
        is_nothing_more;
    });
};


subtest searchs => sub {
    User->eq(id => 1)->ne(id2 => 2)->gt(id3 => 3)->ge(id4 => 4)->lt(id5 => 5)->le(id6 => 6)->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND id = ? AND id2 != ? AND id3 > ? AND id4 >= ? AND id5 < ? AND id6 <= ?", 0, 1, 2, 3, 4, 5, 6;
    is_nothing_more;

    User->like(name => 'hoge1')->contains(name => 'hoge2')->starts_with(name => 'hoge3')->ends_with(name => 'hoge4')->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND name LIKE ? AND name LIKE ? AND name LIKE ? AND name LIKE ?", 0, 'hoge1', '%hoge2%', 'hoge3%', '%hoge4';
    is_nothing_more;


    User->in(id => [1,2,3,4])->not_in(id => [3,4])->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND id IN (?, ?, ?, ?) AND id NOT IN (?, ?)", 0, 1, 2, 3, 4, 3, 4;
    is_nothing_more;

    User->null('id')->not_null('name')->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND id IS NULL AND name IS NOT NULL", 0;
    is_nothing_more;

    User->between('id', 1, 10)->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND id >= ? AND id <= ?", 0, 1, 10;
    is_nothing_more;

    User->unscoped->eq(id => 1)->all;
    is_issue_sql "SELECT * FROM users WHERE id = ?", 1;
    is_nothing_more;
};

subtest scope => sub {
    Post->tag01->tag02->all;
    is_issue_sql "SELECT * FROM posts WHERE tag = ? AND tag = ?", '01', '02';
    is_nothing_more;

    Post->tag01->all;
    is_issue_sql "SELECT * FROM posts WHERE tag = ?", '01';
    is_nothing_more;

    Post->tag02->all;
    is_issue_sql "SELECT * FROM posts WHERE tag = ?", '02';
    is_nothing_more;

    Post->tag02->in(id => [1..3])->all;
    is_issue_sql "SELECT * FROM posts WHERE tag = ? AND id IN (?, ?, ?)", '02', 1, 2, 3;
    is_nothing_more;
};

subtest update_all_delete_all => sub {

    Post->in(id => [1..10])->update_all({name => 'hoge'});
    is_issue_sql "UPDATE posts SET name = ? WHERE id IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 'hoge', (1..10);
    is_nothing_more;

    Post->in(id => [1..10])->delete_all;
    is_issue_sql "DELETE FROM posts WHERE id IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", (1..10);
    is_nothing_more;
};

subtest association => sub {

    my $u;
    freeze_timestamp(sub {
        my $now = shift;
        $u = User->create({name => 'hoge'});
        $u->{-org}->{id} = 1; # for test
        is_issue_sql "INSERT INTO users (name, created_at, updated_at) VALUES (?, ?, ?)", 'hoge', $now, $now;
        is_nothing_more;
    });

    # has_many
    $u->posts->all;
    $u->comments->all;
    is_issue_sql "SELECT * FROM posts WHERE user_id = ?", 1;
    is_issue_sql "SELECT * FROM comments WHERE user_id = ?", 1;
    is_nothing_more;

    # has_one
    $u->comment_one;
    is_issue_sql "SELECT * FROM comments WHERE user_id = ? LIMIT ?", 1, 1;
    is_nothing_more;


    # belongs_to
    my $p;
    freeze_timestamp(sub {
        my $now = shift;
        $p = Post->create({title => 'hoge'});
        $p->{-org}->{user_id} = 3; # for test
        is_issue_sql "INSERT INTO posts (title, created_at, updated_at) VALUES (?, ?, ?)", 'hoge', $now, $now;
        is_nothing_more;
    });

    $p->user;
    is_issue_sql "SELECT * FROM users WHERE id = ? LIMIT ?", 3, 1;
    is_nothing_more;

    # and where
    $u->posts->in(id => [1,2,3])->all;
    is_issue_sql "SELECT * FROM posts WHERE user_id = ? AND id IN (?, ?, ?)", 1, 1, 2, 3;
    is_nothing_more;
};

subtest joins => sub {

    User->joins("posts")->all;
    is_issue_sql "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted = ?", 0;
    is_nothing_more;

    Post->joins('user')->all;
    is_issue_sql "SELECT me.* FROM posts me INNER JOIN users user ON user.id = me.user_id";
    is_nothing_more;

    # and search
    Post->joins('user')->eq(id => 2)->all;
    is_issue_sql "SELECT me.* FROM posts me INNER JOIN users user ON user.id = me.user_id WHERE me.id = ?", 2;
    is_nothing_more;

    # multi join
    Post->joins('user')->joins('comments')->all;
    is_issue_sql "SELECT me.* FROM posts me INNER JOIN users user ON user.id = me.user_id LEFT JOIN comments comments ON comments.post_id = me.id";
    is_nothing_more;

    # nesdted join
    User->joins("posts", "comments")->all;
    is_issue_sql "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id LEFT JOIN comments comments ON comments.post_id = posts.id WHERE me.deleted = ?", 0;
    is_nothing_more;
};

subtest merge => sub {ok 1;

    # where
    User->joins("posts")->merge(Post->eq(id => 3))->all;
    is_issue_sql "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted = ? AND posts.id = ?", 0, 3;
    is_nothing_more;

    # select
    User->joins("posts")->merge(Post->select('title'))->all;
    is_issue_sql "SELECT posts.title FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted = ?", 0;
    is_nothing_more;

    # group
    User->joins("posts")->merge(Post->select("title")->group('title'))->all;
    is_issue_sql "SELECT posts.title FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted = ? GROUP BY posts.title", 0;
    is_nothing_more;

    # order
    User->joins("posts")->merge(Post->desc("id"))->asc("id")->all;
    is_issue_sql "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id WHERE me.deleted = ? ORDER BY posts.id DESC, me.id", 0;
    is_nothing_more;
};

subtest limit_offset => sub {
    Post->limit(4)->offset(2)->all;
    is_issue_sql "SELECT * FROM posts LIMIT ? OFFSET ?", 4, 2;
    is_nothing_more;
};

subtest select => sub {
    Post->select('id', 'title')->all;
    is_issue_sql "SELECT id, title FROM posts";
    is_nothing_more;
};

subtest lock => sub {
    Post->lock->all;
    is_issue_sql "SELECT * FROM posts FOR UPDATE";
    is_nothing_more;
};

subtest includes => sub {

    set_result({id => 2}, {id => 4}); # user
    set_result(  # post
        {id => 1, user_id => 2},
        {id => 2, user_id => 2},
        {id => 3, user_id => 4},
        {id => 4, user_id => 4},
        {id => 5, user_id => 2},
    );
    my $us = User->includes('posts')->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ?", 0;
    is_issue_sql "SELECT * FROM posts WHERE user_id IN (?, ?)", 2, 4;
    is_nothing_more;
    is $us->[0]->id, 2;
    is $us->[1]->id, 4;

    is @{$us->[0]->posts}, 3;
    is $us->[0]->posts->[0]->id, 1;
    is $us->[0]->posts->[1]->id, 2;
    is $us->[0]->posts->[2]->id, 5;

    is $us->[1]->posts->[0]->id, 3;
    is $us->[1]->posts->[1]->id, 4;
    is @{$us->[1]->posts}, 2;
    is_nothing_more;
};

subtest nested_includes => sub {

    set_result({id => 2}, {id => 4}); # user
    set_result(  # post
        {id => 1, user_id => 2},
        {id => 2, user_id => 2},
        {id => 3, user_id => 4},
        {id => 4, user_id => 4},
        {id => 5, user_id => 2},
    );
    set_result( # comment
        {id => 1, post_id => 4},
        {id => 2, post_id => 4},
        {id => 3, post_id => 2},
    );
    my $us = User->includes('posts', 'comments')->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ?", 0;
    is_issue_sql "SELECT * FROM posts WHERE user_id IN (?, ?)", 2, 4;
    is_issue_sql "SELECT * FROM comments WHERE post_id IN (?, ?, ?, ?, ?)", (1..5);
    is_nothing_more;

    is $us->[0]->id, 2;
    is $us->[1]->id, 4;

    is @{$us->[0]->posts}, 3;
    is $us->[0]->posts->[0]->id, 1;
    is $us->[0]->posts->[1]->id, 2;
    is $us->[0]->posts->[2]->id, 5;

    is $us->[1]->posts->[0]->id, 3;
    is $us->[1]->posts->[1]->id, 4;
    is @{$us->[1]->posts}, 2;

    is @{$us->[0]->posts->[0]->comments}, 0;
    is @{$us->[0]->posts->[1]->comments}, 1;
    is @{$us->[0]->posts->[2]->comments}, 0;

    is @{$us->[1]->posts->[0]->comments}, 0;
    is @{$us->[1]->posts->[1]->comments}, 2;

    is_nothing_more;
};

subtest includes_belongs_to => sub {
    set_result(  # post
        {id => 1, user_id => 2},
    );
    my $p = Post->includes("user")->first;
    is_issue_sql "SELECT * FROM posts LIMIT ?", 1;
    is_issue_sql "SELECT * FROM users WHERE id IN (?)", 2;
    is_nothing_more;

    $p->user;
    is_nothing_more;
};

subtest cached => sub {

    my $s = User->unscoped->asc("id");
    $s->first;
    is_issue_sql "SELECT * FROM users ORDER BY id LIMIT ?", 1;
    is_nothing_more;

    $s->first;
    is_nothing_more;

    $s->last;
    is_issue_sql "SELECT * FROM users ORDER BY id DESC LIMIT ?", 1;
    is_nothing_more;

    $s->last;
    is_nothing_more;

    $s->all;
    is_issue_sql "SELECT * FROM users ORDER BY id";
    is_nothing_more;

    $s->all;
    is_nothing_more;
};

subtest cached_all => sub {

    my $s = User->unscoped;
    $s->all;
    is_issue_sql "SELECT * FROM users";
    is_nothing_more;

    $s->all;
    $s->first;
    $s->last;
    is_nothing_more;
};

subtest chached_associates => sub {

    set_result({id => 2}, {id => 4}); # user
    set_result(  # post
        {id => 1, user_id => 2},
        {id => 2, user_id => 2},
    );
    my $us = User->unscoped->all;
    is_issue_sql "SELECT * FROM users";
    is_nothing_more;

    $us->[0]->posts->all;
    is_issue_sql "SELECT * FROM posts WHERE user_id = ?", 2;
    is_nothing_more;

    set_result(  # post
        {id => 1, user_id => 2},
    );
    my $p = Post->first;
    is_issue_sql "SELECT * FROM posts LIMIT ?", 1;
    is_nothing_more;

    $p->user;
    is_issue_sql "SELECT * FROM users WHERE id = ? LIMIT ?", 2, 1;
    is_nothing_more;
};

subtest as => sub {

    User->joins('posts', 'comments')->merge(Post->eq('title', 'hoge'))->merge(Comment->eq('content', 'fuga'))->all;
    is_issue_sql "SELECT me.* FROM users me LEFT JOIN posts posts ON posts.user_id = me.id LEFT JOIN comments comments ON comments.post_id = posts.id WHERE me.deleted = ? AND posts.title = ? AND comments.content = ?", 0, 'hoge', 'fuga';
    is_nothing_more;

};

subtest count => sub {

    Post->count;
    is_issue_sql "SELECT COUNT(*) FROM posts";
    is_nothing_more;

    Post->eq(type => 5)->count;
    is_issue_sql "SELECT COUNT(*) FROM posts WHERE type = ?", 5;
    is_nothing_more;

    Post->joins('user')->merge(User->eq(type => 3))->count;
    is_issue_sql "SELECT COUNT(*) FROM posts me INNER JOIN users user ON user.id = me.user_id WHERE user.deleted = ? AND user.type = ?", 0, 3;
    is_nothing_more;
};

subtest subquery => sub {
    User->in(id => Post->select('user_id')->eq(type => 2))->all;
    is_issue_sql "SELECT * FROM users WHERE deleted = ? AND id IN (SELECT user_id FROM posts WHERE type = ?)", 0, 2;
    is_nothing_more;
};

done_testing;
