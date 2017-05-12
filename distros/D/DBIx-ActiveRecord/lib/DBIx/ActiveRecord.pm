package DBIx::ActiveRecord;

use 5.008008;
use strict;
use warnings;

use DBI;

our $VERSION = '0.03';

our $DBH;
our $SINGLETON;
our %GLOBAL;

sub connect {
    my ($self, $data_source, $user_name, $auth, $attr) = @_;
    $DBH = DBI->connect($data_source, $user_name, $auth, $attr);
    $SINGLETON = bless {dbh => $DBH}, $self;
    $self->init;
}

sub init {
    my $self = shift;
    foreach my $package (keys %GLOBAL) {
        $self->_load_model($package);
        $self->_make_field_accessors($package);
    }
    $self->_define_associates;
}

sub _load_model {
    my ($self, $package) = @_;
    my $file = $package;
    $file =~ s/::/\//;
    $file .= ".pm";
    eval {require $file};
}

sub _make_field_accessors {
    my $self = shift;
    my $pkg = shift;
    no strict 'refs';
    foreach my $col (@{$pkg->_global->{columns}}) {
        *{$pkg."::$col"} = sub {
            my $self = shift;
            @_ ? $self->set_column($col, @_) : $self->get_column($col);
        };
    }
}

sub _define_associates {
    my $self = shift;
    foreach my $package (keys %GLOBAL) {
        $self->_define_belong_to($package, @$_) for @{$package->_global->{belongs_to}||[]};
        $self->_define_has_relation($package, @$_) for @{$package->_global->{has_relation}||[]};
    }
}

sub _define_belong_to {
    my ($self, $pkg, $name, $package, $opt) = @_;

    $opt->{primary_key} = 'id' if !$opt->{primary_key};
    if (!$opt->{foreign_key}) {
        $package =~ /([^:]+)$/;
        $opt->{foreign_key} = lc($1)."_id";
    }

    $pkg->_global->{joins}->{$name} = {%$opt, model => $package, belongs_to => 1, one => 1};

    no strict 'refs';
    *{$pkg."::$name"} = sub {
        my $self = shift;

        return $self->{associates_cache}->{$name} if exists $self->{associates_cache}->{$name};

        my $m = $opt->{foreign_key};
        $package->unscoped->eq($opt->{primary_key} => $self->$m)->first;
    };
}

sub _define_has_relation {
    my ($self, $pkg, $name, $package, $opt, $has_one) = @_;

    $opt->{primary_key} = 'id' if !$opt->{primary_key};
    if (!$opt->{foreign_key}) {
        $pkg =~ /([^:]+)$/;
        $opt->{foreign_key} = lc($1)."_id";
    }

    $pkg->_global->{joins}->{$name} = {%$opt, model => $package, one => $has_one};

    no strict 'refs';
    *{$pkg."::$name"} = sub {
        my $self = shift;

        return $self->{associates_cache}->{$name} if exists $self->{associates_cache}->{$name};

        my $m = $opt->{primary_key};
        my $s = $package->eq($opt->{foreign_key}, $self->$m);
        $has_one ? $s->limit(1)->first : $s;
    };
}

sub dbh {$DBH}

sub transaction {
    my ($self, $coderef) = @_;
    $self->dbh->begin_work;
    eval {$coderef->()};
    if ($@) {
      $self->dbh->rollback;
    } else {
      $self->dbh->commit;
    }
}

sub DESTROY {
    my ($self) = @_;
    $SINGLETON = undef;
    $self->dbh->disconnect if $self->dbh;
}

1;
__END__
=head1 NAME

DBIx::ActiveRecord - rails3 ActiveRecord like O/R Mapper

=head1 SYNOPSIS

define Model

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

initialize

    use DBIx::ActiveRecord;
    # same args for 'DBI::connect'
    DBIx::ActiveRecord->connect($data_source, $username, $auth, \%attr);

basic CRUD

    # create
    my $user = MyApp::Model::User->new({name => 'new user'});
    $user->save;
    # or
    my $user = MyApp::Model::User->create({name => 'new user'});

    # update
    $user->name('change user name');
    $user->save;

    # delete
    $user->delete;

    # search
    my $users = MyApp::Model::User->in(id => [1..10])->eq(type => 2);

    # delete_all
    User->eq(deleted => 1)->delete_all;

    # update_all
    User->eq(type => 3)->update_all({deleted => 1});

use scope and association

    my $user = MyApp::Model::User->adult->latest->first;
    my $group = $user->group;
    my $published_posts = $user->posts->eq(published => 1);
    my $drafts = $user->posts->eq(published => 0);


=head1 DESCRIPTION

DBIx::ActiveRecord is rails3 ActiveRecord like O/R Mapper.
It is lightweight, very easy use and powerful syntax.

=head1 METHODS

=head2 DBIx::ActiveRecord Methods

=item connect($data_source, $username, $auth, \%attr);

Connect database and initialization.
arguments is same 'DBI::connect'.

example:

    use DBIx::ActiveRecord;
    DBIx::ActiveRecord->connect("dbi:mysql:databasename", 'root', '');


=head2 DBIx::ActiveRecord::Model Methods

This class is core class for DBIx::ActiveRecord module.
Model class is extends this class.

exsample:

    package My::Model::Hoge;
    use base 'DBIx::ActiveRecord::Model';
    __PACKAGE__->table('users');
    __PACKAGE__->columns(qw/id name created_at/);
    __PACKAGE__->primary_keys(qw/id/);
    1;


=item Model->table($table_name)

setting table name for model class.
this method is required for defined model.


=item Model->columns(@column_names)

setting table column name for model class.
this method is required for defined model.


=item Model->primary_keys(@key_column_names)

setting table primary keys for model class.
this method is required for defined model.


=item Model->belongs_to($name, $package, \%opt)

setting up belongs_to association.

exsample:

    __PACKAGE__->belongs_to(group => 'My::Model::Group');

\%opt enable keys is

primary_key

  Specify the method that returns the primary key of associated object used for the association. By default this is id.

foerign_key

  Specify the foreign key used for the association. By default this is the lowermost with model packge name with an “_id” suffix.

example:

    __PACKAGE__->belongs_to(group => 'My::Model::Group', {primary_key => 'id', foerign_key => 'group_id'});


=item Model->has_one($name, $package, \%opt)

setting up has_one association.

exsample:

    __PACKAGE__->has_one(tag => 'My::Model::Tag');

\%opt enable keys is

primary_key

  Specify the method that returns the primary key of associated object used for the association. By default this is id.

foerign_key

  Specify the foreign key used for the association. By default this is the lowermost with model packge name with an “_id” suffix.

example:

    __PACKAGE__->has_one(tag => 'My::Model::Tag', {primary_key => 'id', foerign_key => 'tag_id'});


=item Model->has_many($name, $package, \%opt)

setting up has_many association.

exsample:

    __PACKAGE__->has_many(posts => 'My::Model::Post');

\%opt enable keys is

primary_key

  Specify the method that returns the primary key of associated object used for the association. By default this is id.

foerign_key

  Specify the foreign key used for the association. By default this is the lowermost with model packge name with an “_id” suffix.

example:

    __PACKAGE__->has_one(posts => 'My::Model::Post', {primary_key => 'id', foerign_key => 'post_id'});


=item Model->default_scope($coderef)

example:

    __PACKAGE__->default_scope(sub{ shift->desc('created_at')->ne(deleted => 1) });


=item Model->scope($name, $coderef)

example:

    __PACKAGE__->scope(type1 => sub{ shift->eq(type => 1 });


or has args.

    __PACKAGE__->scope(type_of => sub{ shift->eq(type => shift) });

    # use example for
    # Model->type_of(1)->all;


=item Model->transaction($coderef)

do transactional block

example:

    Model->transaction(sub {
        # transactional code
    });


=item Model->new($hash)

build model instance.

example:

    my $m = Model->new({name => 'hoge', type => 1});


=item Model->create(\%hash)

build and save.

example:

    my $m = Model->create({name => 'hoge', type => 1});

this is same

    my $m = Model->new({name => 'hoge', type => 1});
    $m->save;

=item Model->all()

execute select query.

example:

    my $list = Model->all;

or

    my $list = Model->eq(type => 2)->all;


=item Model->first()

execute select query append LIMIT 1
return value is model instance or undef

example:

    my $m = Model->first;

or

    my $m = Model->eq(type => 2)->first;

=item Model->last()

execute select query append LIMIT 1 and reverse order.
return value is model instance or undef
this method is do not work if not call asc or desc method.

example:

    my $m = Model->asc("id")->last;

or

    my $m = Model->asc("id")->eq(type => 2)->last;


=item Model->scoped()

get relation instance.
will not use normally.

example:

    my $m = Model->scoped->eq(id => 1)->first;

this is same

    my $m = Model->eq(id => 1)->first;


=item Model->unscoped()

get relation instance of not apply default_scope.

example:

    my $all = Model->unscoped->all;

=item Model->to_sql()

get sql statement.

example:

    my $sql = Model->eq(type => 2)->eq(deleted => 1)->to_sql;
    # $sql => 'SELECT * FROM models WHERE type = ? AND deleted = ?'

=item Model->update_all($hash)

do update

example:

    Model->eq(type => 2)->update_all({type => 3});
    # UPDATE models SET type = 3 WHERE type = 2


=item Model->delete_all()

do delete

example:

    Model->eq(type => 2)->delete_all;
    # DELETE FROM models WHERE type = 2


=item Model->joins(@$relations)

join other table

example:

    User->joins('group')->all;

    # nested
    User->joins('posts', 'comments')->all;

    # combine
    User->joins('group')->joins('posts', 'comments')->all;


=item Model->merge($relation)

merge other model relation instance

example:

    User->joins('group')->merge(Group->eq(type => 2))->all;


=item Model->includes(@$relations)

Early binding associations.

example:

    User->includes('group')->all;

    # nested
    User->includes('posts', 'comments')->all;

    # combine
    User->includes('group')->includes('posts', 'comments')->all;

=item Model->eq($column, $value)

add '=' condition

=item Model->ne($column, $value)

add '!=' condition

=item Model->in($column, \@value)

add 'IN' condition

=item Model->not_in($column, \@value)

add 'NOT IN' condition

=item Model->null($column)

add 'IS NULL' condition

=item Model->not_null($column)

add 'IS NOT NULL' condition

=item Model->gt($column, $value)

add '>' condition

=item Model->lt($column, $value)

add '<' condition

=item Model->ge($column, $value)

add '>=' condition

=item Model->le($column, $value)

add '<=' condition

=item Model->like($column, $value)

add 'LIKE' condition

=item Model->contains($column, $value)

add 'LIKE' condition
value will be added to the conditions as "%$value%".

=item Model->starts_with($column, $value)

add 'LIKE' condition
value will be added to the conditions as "$value%".

=item Model->ends_with($column, $value)

add 'LIKE' condition
value will be added to the conditions as "%$value".

=item Model->between($column, $value1, $value2)

this is same

    Model->ge($column, $value1)->lt($column, $value2)


=item Model->where($condition, @bind_values)

add condition

example:

    Model->where('type = ? OR id < ?', 2, 1000)->all
    # SELECT * from models WHERE type = 2 OR id < 1000

=item Model->select(@columns)

set select columns

example:

    Model->select('id', 'name')->all;
    # SELECT id, name from models;

=item Model->limit($value)

set limit


=item Model->offset($value)

set offset


=item Model->lock()

search query added 'FOR UPDATE'

example:

    Model->transaction(sub {
        my $w = Wallet->eq(user_id => 1)->lock->first;
        $w->deposite($w-deposite - 100);
        $w->save;
    });


=item Model->group(@columns)

set group by

example:

    Model->select('type')->group('type')->all;


=item Model->asc(@columns)

add 'ASC' order by

    Model->asc('id', 'name')->all;


=item Model->desc(@columns)

add 'DESC' order by

    Model->desc('id', 'name')->all;


=item Model->reorder()

reset order by

example:

    my $s = Model->asc('id');
    $s = $s->reorder->desc('id');
    $s->all;

=item Model->reverse()

reverse order by

example:

    my $s = Model->asc('id');
    $s->reverse->all;

    # this is same
    Model->desc('id')->all


=item $model->get_column($column)

get a column value.

example:

    my $v = $model->get_column('name');

defined helper method for 'columns' method arguments.

example:

    __PACKAGE__->columns(qw/id name/);
    ...

    my $id = $model->name;
    # this is same
    my $id = $model->get_column('name');


=item $model->set_column($column, $value)

set a column value.

example:

    $model->set_column('name', 'fuga');

defined helper method for 'columns' method arguments.

example:

    __PACKAGE__->columns(qw/id name/);
    ...

    $model->name('fuga');
    # this is same
    my $id = $model->set_column('name', 'fuga');


=item $model->to_hash()

translate hash value.

example:

    my $m = Model->new({name => 'hoge'});
    $m->type(2);

    my $h = $m->to_hash;
    # $h is {name => 'hoge', type => 2}

=item $model->in_storage()

saved instance is return 1.
not saved instance is return 0.

=item $model->save()

do insert or update.

=item $model->insert()

do insert.

=item $model->update()

do update.

=item $model->delete()

do delete.

=head1 BUGS AND LIMITATIONS

This module is alpha version.
Please give me feedback.
Please PullRequest with github If you have more better idea.

=head1 AUTHOR

Toshiyuki Saito

=head1 REPOSITORY

  git clone git://github.com/toshi-saito/perl-dbix-activerecord.git

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2012 by Toshiyuki Saito All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
