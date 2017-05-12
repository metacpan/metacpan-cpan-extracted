perl-DBIx-ActiveRecord
======================

Rails3 ActiveRecord like O/R Mapper library for perl.
it's very easy, lightweight, and has powerful syntax.

INSTALLATION
============

  % cpan DBIx::ActiveRecord


Features Highlight
==================

Define Model
--
```perl:MyApp/Model/User.pm
package MyApp::Model::User;
use base 'DBIx::ActiveRecord::Model';
__PACKAGE__->table('users'); # table name is required
__PACKAGE__->columns(qw/id name created_at updated_at/); # required
__PACKAGE__->primary_keys(qw/id/); # required

# scope
__PACKAGE__->default_scope(sub{ shift->ne(deleted => 1) });
__PACKAGE__->scope(adult => sub{ shift->ge(age => 20) });
__PACKAGE__->scope(latest => sub{ shift->desc('created_at') });

# association
__PACKAGE__->belongs_to(group => 'MyApp::Model::Group');
__PACKAGE__->has_many(posts => 'MyApp::Model::Post');

1;
```

Initialize
--
```perl
use DBIx::ActiveRecord;
# Same args for 'DBI::connect'
DBIx::ActiveRecord->connect($data_source, $username, $auth, \%attr);
```

Basic CRUD
--
```perl
# create
my $new_admin = User->create({type => 'Administrator', name => 'new admin'});
# or
my $new_admin = User->new({type => 'Administrator', name => 'new admin'});
$new_admin->save;

# select
my $admins = User->eq(type => 'Administrator');

# update
my $admin = $admins->[0];
$admin->name('first administrator');
$admin->save;

# delete
$admin->delete;


# update all administrator
User->eq(type => 'Administrator')->update_all({deleted => 1});

# delete all administrator
User->eq(type => 'Administrator')->delete_all;
```

Other query operators
--
```perl
User->eq(id => 1)
# other operator is "ne", "gt", "lt", "ge", "le", "like".

# IN, NOT IN
User->in(id => [1..10])->not_in(type => [2, 4]);

# IS NULL, IS NOT NULL
User->null('profile')->not_null('type');

# BETWEEN
User->between('number', 1, 100)

# etc..
User->limit(1)->offset(2)->asc('created_at')->desc('id')
```

Associates
--
```perl
# associates
my $first_user_posts = User->first->posts;
```


joins, merge
--
```perl
my $active_users = User->joins('posts')->merge(Post->eq(created_at => $today));
```

transaction
--
```perl
User->transaction(sub {
    $u = User->eq(id => 1)->lock->first;
    $u->deposite($u->deposite - 100);
    $u->save;
});
```


scope, default_scope, unscoped
--
```perl
my $admins = User->admin;
my $all = User->unscoped;
```

includes
--
```perl
my $u = User->eq(id => 1)->includes('posts');
# "$u->posts" is already load.
```

