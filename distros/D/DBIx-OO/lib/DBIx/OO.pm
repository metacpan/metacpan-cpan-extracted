package DBIx::OO;

use base qw(Class::Data::Inheritable);

use warnings;
use strict;
use Carp ();
use Encode ();

use version; our $VERSION = qv('0.0.9');

use DBI ();
use SQL::Abstract ();

__PACKAGE__->mk_classdata('__dboo_table');
__PACKAGE__->mk_classdata('__dboo_columns');
__PACKAGE__->mk_classdata('__dboo_colgroups');
__PACKAGE__->mk_classdata('__dboo_defaults');
## __PACKAGE__->mk_classdata('__dboo_sql');
__PACKAGE__->mk_classdata('__dboo_sqlabstract');
## __PACKAGE__->mk_classdata('__dboo_relations');

my %INVALID_FIELD_NAMES = ( id      => 1,
                            can     => 1,
                            our     => 1,
                            columns => 1,
                            table   => 1,
                            set     => 1,
                            get     => 1,
                            count   => 1,
                          );

use vars qw( $HAS_WEAKEN );

BEGIN {
    $HAS_WEAKEN = 1;
    eval {
        require Scalar::Util;
        import Scalar::Util qw(weaken);
    };
    if ($@) {
        $HAS_WEAKEN = 0;
    }
}

sub __T { my $c = $_[0]; ref $c || $c; }

=head1 NAME

DBIx::OO - Database to Perl objects abstraction

=head1 SYNOPSIS

    package MyDB;
    use base 'DBIx::OO';

    # We need to overwrite get_dbh since it's an abstract function.
    # The way you connect to the DB is really your job; this function
    # should return the database handle.  The default get_dbh() croaks.

    my $dbh;
    sub get_dbh {
        $dbh = DBI->connect_cached('dbi:mysql:test', 'user', 'passwd')
          if !defined $dbh;
        return $dbh;
    }

    package MyDB::Users;
    use base 'MyDB';

    __PACKAGE__->table('Users');
    __PACKAGE__->columns(P => [ 'id' ],
                         E => [qw/ first_name last_name email /]);
    __PACKAGE__->has_many(pages => 'MyDB::Pages', 'user');

    package MyDB::Pages;
    use base 'MyDB';

    __PACKAGE__->table('Pages');
    __PACKAGE__->columns(P => [ 'id' ],
                         E => [qw/ title content user /]);
    __PACKAGE__->has_a(user => 'MyDB::Users');

    package main;

    my $u = MyDB::Users->create({ id          => 'userid',
                                  first_name  => 'Q',
                                  last_name   => 'W' });

    my $foo = MyDB::Users->retrieve('userid');
    my @p = @{ $foo->fk_pages };
    print "User: ", $foo->first_name, " ", $foo->last_name, " pages:\n";
    foreach (@p) {
        print $_->title, "\n";
    }

    $foo->first_name('John');
    $foo->last_name('Doe');
# or
    $foo->set(first_name => 'John', last_name => 'Doe');
    $foo->update;

=head1 IMPORTANT NOTE

This code is tested only with MySQL.  That's what I use.  I don't have
too much time to test/fix it for other DBMS-es (it shouldn't be too
difficult though), but for now this is it...  Volunteers are welcome.

=head1 DESCRIPTION

This module has been inspired by the wonderful Class::DBI.  It is a
database-to-Perl-Objects abstraction layer, allowing you to interact
with a database using common Perl syntax.

=head2 Why another Class::DBI "clone"?

=over

=item 1

I had the feeling that Class::DBI is no longer maintained.  This
doesn't seem to be the case, because:

=item 2

My code was broken multiple times by Class::DBI upgrades.

=item 3

Class::DBI doesn't quote table or field names, making it impossible to
use a column named, say, 'group' with MySQL.

=item 4

I wanted to know very well what happens "under the hood".

=item 5

I hoped my module would be faster than CDBI.  I'm not sure this
is the case, but it certainly has less features. :-)

=item 6

There's more than one way to do it.

=back

All in all, I now use it in production code so this thing is here to
stay.

=head2 Features

=over

=item B<retrieve, search, create, update, delete>

As Class::DBI, we have functions to retrieve an object by the primary
key, search a table and create multiple objects at once, create a new
object, update an existing object.

=item B<manage fields with convenient accessors>

Same like Class::DBI, we provide accessors for each declared column in
a table.  Usually accessors will have the same name as the column
name, but note that there are cases when we can't do that, such as
"can", "get", "set", etc. -- because DBIx::OO or parent objects
already define these functions and have a different meaning.

When it is not possible to use the column name, it is prefixed with
"col_" -- so if you have a table with a column named "can", its
accessor will be named "col_can".

=item B<has_a, has_many, has_mapping>

We support a few types of table relationships.  They provide a few
nice features, though overally are not as flexible as Class::DBI's.
The syntax is quite different too, be sure to check the
L<documentation of these functions|has_a_has_many>.

=item B<JOIN>-s

has_a also creates a search function that allows you to retrieve data
from both tables using a JOIN construct.  This can drastically reduce
the number of SQL queries required to fetch a list of objects.

=back

=head2 Missing features:

=over

=item B<NO caching of any kind>

DBIx::OO does not cache objects.  This means that you can have the
same DB record in multiple Perl objects.  Sometimes this can put you
in trouble (not if you're careful though).

At some point I might want to implement object uniqueness like
Class::DBI, but not for now.

=item B<NO triggers>

Triggers are nice, but can cause considerable performance problems
when misused.

UPDATE: The only trigger that currently exists is before_set(), check
its documentation.

=item B<A lot others>

Constraints, integrity maintenance, etc.  By contrast Class::DBI has a
lot of nice features, but I think the performance price we pay for
them is just too big.  I hope this module to stay small and be fast.

=back

=head1 QUICK START

You need to subclass DBIx::OO in order to provide an
implementation to the B<get_dbh>() method.  This function is pure
virtual and should retrieve the database handler, as returned by
B<DBI-E<gt>connect>, for the database that you want to use.  You can
use an interim package for that, as we did in our example above
(B<MyDB>).

Then, each derived package will handle exactly one table, should setup
columns and relationships.

=head1 API DOCUMENTATION

=head2 C<new()>

Currently, B<new()> takes no arguments and constructs an empty object.
You normally shouldn't need to call this directly.

=cut

sub new {
    my ($class) = @_;
    bless { values   => {},
            modified => {},
            ### foreign  => {}
          }, $class;
}

=head2 C<get_dbh()>

This method should return a database handler, as returned by
DBI->connect.  The default implementation croaks, so you I<need> to
overwrite it in your subclasses.  To write it only once, you can use
an intermediate object.

=cut

sub get_dbh {
    _croak("Pure virtual method not implemented: get_dbh.",
           "See the documentation, if there is any.");
}

=head2 C<table($table_name)>

Call this method in each derived package to inform DBIx::OO of the
table that you wish that package to use.

    __PACKAGE__->table('Users')

=cut

sub table {
    my $class = __T(shift);
    my $table = shift;
    $class->__dboo_table($table) if $table;
    return $class->__dboo_table;
}

=head2 C<columns(group[=E<gt> cols, ...])>

Sets/retrieves the columns of the current package.

Similarly to Class::DBI, DBIx::OO uses a sort of column grouping.
The 'P' group is always the primary key.  The 'E' group is the
essential group--which will be fetched whenever the object is first
instantiated.  You can specify any other groups names here, and they
will simply group retrieval of columns.

Example:

    __PACKAGE__->columns(P => [ 'id' ],
                         E => [ 'name', 'description' ],
                         X => [ 'c1', 'big_content1', 'big_title1' ],
                         Y => [ 'c2', 'big_content2', 'big_title2' ]);

The above code defines 4 groups.  When an object is first
instantiated, it will fetch 'id', 'name' and 'description'.  When you
say $obj->c1, it will fetch 'c1, 'big_content1' and 'big_title1',
because they are in the same group.  When you say $obj->c2 it will
fetch 'c2', 'big_content2' and 'big_title2'.  That's pretty much like
Class::DBI.

To retrieve columns, you pass a group name.

=head3 Notes

=over

=item *

Class::DBI allows you to call columns() multiple times, passing one
group at a time.  Our module should allow this too, but it's untested
and might be buggy.  We suggest defining all groups in one shot, like
the example above.

=item *

Group 'P' is I<required>.  I mean that.  We won't guess the primary
key column like Class::DBI does.

=back

=cut

sub columns {
    my $class = __T(shift);
    my $h = $class->__dboo_columns;
    if (@_) {
        if (ref $_[0] eq 'HASH') {
            $class->__dboo_columns($_[0]);
        } elsif (@_ == 1) {
            return $class->__dboo_columns->{$_[0]};
        } else {
            $class->__dboo_columns($h = {})
              if !defined $h;
            while (@_) {
                my $k = shift;
                my $v = shift;
                $v = [ $v ]
                  if (!ref $v);
                $h->{$k} = $v;
            }
        }
    } else {
        return [ keys %{$class->__dboo_colgroups} ];
    }
    my $all = $class->__dboo_columns;
    my $hash = {};
    while (my ($group, $v) = each %$all) {
        foreach my $colname (@$v) {
            my $wtf8;
            if ($colname =~ /^!/) {
                $colname = substr($colname, 1);
                $wtf8 = 1;
            }
            my $closname = get_accessor_name($colname);
            no strict 'refs';
            *{"$class\::$closname"} = __COL_CLOSURE($colname, $wtf8);
            $hash->{$colname} = $group;
        }
    }
    $class->__dboo_colgroups($hash);
    return $h;
}

=head2 C<clone_columns(@except)>

Though public, it's likely you won't need this function.  It returns
a list of column names that would be cloned in a clone() operation.
By default it excludes any columns in the "B<P>" group (primary keys)
but you can pass a list of other names to exclude as well.

=cut

sub clone_columns {
    my ($class) = __T(shift);
    my %except;
    if (@_) {
        @except{@_} = @_;
    }
    my $all = $class->columns;
    $all = [ grep { !exists($except{$_}) and $class->__dboo_colgroups->{$_} ne 'P' } @$all ];
    return $all;
}

=head2 C<defaults(%hash)>

Using this function you can declare some default values for your
columns.  They will be used unless alternative values are specified
when a record is inserted (e.g. with create()).  Example:

    __PACKAGE__->defaults(created     => ['now()'],
                          hidden      => 1,
                          modified_by => \&get_current_user_id);

You can specify any scalar supported by SQL::Abstract's insert
operation.  For instance, an array reference specifies literal SQL
(won't be quoted).  Additionally, you can pass code references, in
which case the subroutine will be called right when the data is
inserted and its return value will be used.

=cut

sub defaults {
    my ($class, %args) = @_;
    my $def = $class->__dboo_defaults;
    if (!$def) {
        $class->__dboo_defaults($def = {});
    }
    @{$def}{keys %args} = values %args;
}

=head2 C<get(field_name[, field_name, ...])>

Retrieves the value of one or more columns.  If you pass more column
names, it will return an array of values, in the right order.

=cut

sub get {
    my ($self, @field) = @_;
    if (@field == 1) {
        my $f = $field[0];
        if (!exists $self->{values}{$f}) {
            my $g = $self->__dboo_colgroups->{$f};
            $self->_retrieve_columns($g, $self->{values});
        }
        return wantarray ? ( $self->{values}{$f} ) : $self->{values}{$f};
    } else {
        my %groups = ();
        foreach my $f (@field) {
            $groups{$self->__dboo_colgroups->{$f}} = 1
              if !exists $self->{values}{$f};
        }
        $self->_retrieve_columns([ keys %groups ], $self->{values})
          if %groups;
        return @{$self->{values}}{@field};
    }
}

=head2 C<set(field =E<gt> value[, field =E<gt> value, ...])>

Sets one or more columns to the specified value(s).

This function calls C<before_set> right before modifying the object
data, passing a hash reference to the new values.

=cut

sub set {
    my $self = shift;
    my %h = ref $_[0] eq 'HASH' ? %{$_[0]} : ( @_ );
    $self->before_set(\%h, 0);
    my @keys = keys %h;
    @{$self->{modified}}{@keys} = @{$self->{values}}{@keys};
    @{$self->{values}}{@keys} = values %h;
    return $self;
}

=head2 C<before_set>

By default this function does nothing.  It will be called by the
framework right before setting column values.  A hash reference with
columns to be set will be passed.  You can modify this hash if you
wish.  For example, assuming you have an Users table with a MD5
password and you want to create the MD5 right when the column is set,
you can do this:

    package Users;

    ...

    sub before_set {
        my ($self, $h, $is_create) = @_;
        if (exists $h->{password}) {
            $h->{password} = make_md5_passwd($h->{password});
        }
    }

    my $u = Users->retrieve('foo');
    $u->password('foobar');
    print $u->password;
    # be8cd58c70ad7dc935802fdb051869fe

The $is_create argument will be true (1) if this function is called as
a result of a create() command.

=cut

sub before_set {}

=head2 C<id()>

Returns the value(s) of the primary key(s).  If the primary key
consists of more columns, this method will return an array with the
values, in the order the PK column names were specified.

Currently this is equivalent to $self->get(@{ $self->columns('P') }).

=cut

sub id {
    my ($self) = @_;
    return $self->get(@{$self->columns('P')});
}

sub __COL_CLOSURE {
    my ($col, $wtf8) = @_;
    if (!$wtf8) {
        return sub {
            my $self = shift;
            @_ > 0 ? $self->set($col, @_) : $self->get($col);
        };
    } else {
        return sub {
            my $self = shift;
            if (@_ > 0) {
                my @a = map { _to_utf8($_) } @_;
                return $self->set($col, @a);
            } else {
                return $self->get($col);
            }
        };
    }
}

=head2 C<transaction_start()>, C<transaction_rollback()>, C<transaction_commit()>

Use these functions to start, commit or rollback a DB transaction.
These simply call begin_work, rollback and commit methods on the DB
handle returned by get_dbh().

=cut

sub transaction_start {
    $_[0]->get_dbh->begin_work;
}

sub transaction_rollback {
    $_[0]->get_dbh->rollback;
}

sub transaction_commit {
    $_[0]->get_dbh->commit;
}

=head2 C<get_accessor_name()>

There are a few column names that we can't allow as accessor names.
This function receives a column name and returns the name of the
accessor for that field.  By default it prefixes forbidden names with
'col_'.  The forbidden names are:

  - id
  - can
  - our
  - columns
  - table
  - get
  - set
  - count

If you don't like this behavior you can override this function in your
classes to return something else.  However, be very careful about
allowing any the above forbidden names as accessors--basically nothing
will work.

=cut

sub get_accessor_name {
    my $name = shift;
    return $name
      if !$INVALID_FIELD_NAMES{$name};
    return
      "col_$name";
}

=head2 C<get_fk_name>

This function returns the name of a foreign key accessor, as defined
by L<has_a/has_many|has_a_has_many>.  The default returns
"fk_$name"--thus prepending "fk_".

If you want the Class::DBI behavior, you can override this function in
your derived module:

    sub get_fk_name { return $_[1]; }

(the first argument will be object ref. or package)

I think the Class::DBI model is unwise.  Many times I found my columns
inflated to objects when I was in fact expecting to get an ID.  Having
the code do implicit work for you is nice, but you can spend hours
debugging when it gets it wrong--which is why, DBIx::OO will by
default prepend a "fk_" to foreign objects accessors.  You'll get use
to it.

=cut

sub get_fk_name {
    return "fk_$_[1]";
}

=head2 C<has_a/has_many>

    __PACKAGE__->has_a(name, type[, mapping[, order ]]);
    __PACKAGE__->has_many(name, type[, mapping[, order[, limit[, offset ]]]]);

Creates a relationship between two packages.  In the simplest form,
you call:

    __PACKAGE__->has_a(user => Users);

This declaration creates a relation between __PACKAGE__ (assuming it
has a column named 'user') and 'Users' package.  It is assuming that
'user' from the current package points to the primary key of the Users
package.

The declaration creates a method named 'fk_user', which you can call
in order to retrieve the pointed object.  Example:

    package Pages;
    use base 'MyDB';
    __PACKAGE__->columns('P' => [ 'id' ],
                         'E' => [ 'user', ... ]);
    __PACKAGE__->has_a(user => 'Users');

    my $p = Pages->retrieve(1);
    my $u = $p->fk_user;
    print $u->first_name;

In more complex cases, you might need to point to a different field
than the primary key of the target package.  You can call it like
this:

    Users->has_many(pages => Pages, 'user');
    my $u = Users->retrieve('foo');
    my @pages = @{ $u->fk_pages };

The above specifies that an User has many pages, and that they are
determined by mapping the 'user' field of the Pages package to the
I<primary key> of the C<Users> package.

has_many() also defines an utility function that allows us to easily
count the number of rows in the referenced table, without retrieving
their data.  Example:

    print $u->count_pages;

You can specify an WHERE clause too, in SQL::Abstract syntax:

    print $u->count_pages(keywords => { -like => '%dhtml%' });

The above returns the number of DHTML pages that belong to the user.

In even more complex cases, you want to map one or more arbitrary
columns of one package to columns of another package, so you can pass
a hash reference that describes the column mapping:

    ## FIXME: find a good example

has_many() is very similar to has_a, but the accessor it creates
simply returns multiple values (as an array ref).  We can pass some
arguments too, either to has_a/has_many declarations, or to the
accessor.

    @pages = @{ $u->fk_pages('created', 10, 5) }

The above will retrieve the user's pages ordered by 'created',
starting at OFFSET 5 and LIMIT-ing to 10 results.

You can use has_a even if there's not a direct mapping.  Example, a
page can have multiple revisions, but we can also easily access the
first/last revision:

    Pages->has_many(revisions => 'Revisions', 'page');
    Pages->has_a(first_revision => 'Revisions', 'page', 'created');
    Pages->has_a(last_revision => 'Revisions', 'page', '^created');

has_a() will LIMIT the result to one.  Ordering the results by
'created', we make sure that we actually retrieve what we need.
B<Note> that by prefixing the column name with a '^' character, we're
asking the module to do a DESC ordering.

(Of course, it's a lot faster if we had first_revision and
last_revision as columns in the Pages table that link to Revision id,
but we just wanted to point out that the above is possible ;-)

=head3 Join

has_a() will additionally create a join function.  It allows you to
select data from 2 tables using a single SQL query.  Example:

    package MyDB::Users;
    MyDB::Users->table('Users');
    MyDB::Users->has_a(profile => 'Profiles');

    package MyDB::Profiles;
    MyDB::Profiles->table('Profiles');

    @data = Users->search_join_profile;
    foreach (@data) {
        my $user = $_->{Users};        # the key is the SQL B<table> name
        my $profile = $_->{Profiles};
        print $user->id, " has address: ", $profile->address;
    }

The above only does 1 SELECT.  Note that the join search function
returns an array of hashes that map from the SQL table name to the
DBIx::OO instance.

You can pass additional WHERE, ORDER, LIMIT and OFFSET clauses to the
join functions as well:

    @data = Users->search_join_profile({ 'Users.last_name' => 'Doe' },
                                       'Users.nickname',
                                       10);

The above fetches the first 10 members of the Doe family ordered by
nickname.

Due to lack of support from SQL::Abstract side, the JOIN is actually a
select like this:

    SELECT ... FROM table1, table2 WHERE table1.foreign = table2.id

In the future I hope to add better support for this, that is, use
"INNER JOIN" and eventually support other JOIN types as well.

=head3 Notes

=over

=item 1.

The C<fk_> accessors will actually retrieve data at each call.
Therefore:

    $p1 = $user->fk_pages;
    $p2 = $user->fk_pages;

will retrieve 2 different arrays, containing different sets of objects
(even if they point to the same records), hitting the database twice.
This is subject to change, but for now you have to be careful about
this.  It's best to keep a reference to the returned object(s) rather
than calling fk_pages() all over the place.

=item 2.

has_many() creates accessors that select multiple objects.  The
database will be hit once, though, and multiple objects are created
from the returned data.  If this isn't desirable, feel free to LIMIT
your results.

=back

=cut

### TODO: this can be optimized: cache the where clause and generated SQL.
sub has_a {
    my ($class, $name, $type, $arg, $order) = @_;
    my $fk_name = $class->get_fk_name($name);
    no strict 'refs';
    my $colmap;
    my $mk_colmap = sub {
        if (!defined $colmap) {
            my ($class) = @_;
            $colmap = {};
            if (!$arg) {
                $colmap->{$name} = $type->columns('P')->[0];
            } elsif (!ref $arg) {
                $colmap->{$class->columns('P')->[0]} = $arg;
            } elsif (ref $arg eq 'HASH') {
                $colmap = $arg;
            } elsif (ref $arg eq 'ARRAY') {
                @{$colmap}{@$arg} = @{$type->columns('P')};
            }
        }
    };
    ## declare the fk_colname function
    {
        *{"$class\::$fk_name"} = sub {
            my ($self, $order2) = @_;
            $order2 = $order
              if !defined $order2;
            &$mk_colmap($self);
            my %where;
            @where{values %$colmap} = @{$self->{values}}{keys %$colmap};
            my $a = $type->search(\%where, $order, 1);
            return $a->[0];
        };
    }
    ## simple 2 tables JOIN facility
    {
        my %join_colmap;
        my ($t1, $t2);
        my ($c1, $c2);
        my @cols;
        *{"$class\::search_join_${name}"} = sub {
            my ($class, $where2, $order2, $limit, $offset) = @_;
            $order2 = $order
              if !defined $order2;
            my $sa = $class->get_sql_abstract;
            if (!%join_colmap) {
                &$mk_colmap($class);
                ($t1, $t2) = ($class->table, $type->table);
                $c1 = $class->_get_columns([ 'P', 'E' ]);
                $c2 = $type->_get_columns([ 'P', 'E' ]);
                @cols = map { "$t1.$_" } @$c1;
                push(@cols,
                     map { "$t2.$_" } @$c2);
                my @k = map { "$t1.$_" } keys %$colmap;
                my @v = map { my $tmp = '= ' . $sa->_quote("$t2.$_");
                              \$tmp } values %$colmap;
                @join_colmap{@k} = @v;
            }
            my %where = %join_colmap;
            @where{keys %$where2} = values %$where2
              if $where2;
            my ($sql, @bind) = $sa->select([ $t1, $t2 ],
                                           \@cols, \%where, $order2, $limit, $offset);
            my $sth = $class->_run_sql($sql, \@bind);
            my @ret;
            my $slicepoint = scalar(@$c1) - 1;
            my $end = $slicepoint + scalar(@$c2);
            while (my $row = $sth->fetchrow_arrayref) {
                my $obj = {};
                my $o1 = $obj->{$t1} = $class->new;
                my $o2 = $obj->{$t2} = $type->new;
                @{$o1->{values}}{@$c1} = @{$row}[0..$slicepoint];
                @{$o2->{values}}{@$c2} = @{$row}[$slicepoint+1..$end];
                push @ret, $obj;
            }
            return @ret;
        };
    }
    undef $class;
}

=head2 C<might_have()>

Alias to has_a().

=cut

*might_have = \&has_a;

### TODO: this can be optimized: cache the where clause and generated SQL.
sub has_many {
    my ($class, $name, $type, $arg, $order, $limit, $offset) = @_;
    my $colmap;
    my $fk_name = $class->get_fk_name($name);
    no strict 'refs';
    my $mk_colmap = sub {
        if (!defined $colmap) {
            my $self = shift;
            $colmap = {};
            if (!$arg) {
                $colmap->{$name} = $type->columns('P')->[0];
            } elsif (!ref $arg) {
                $colmap->{$self->columns('P')->[0]} = $arg;
            } elsif (ref $arg eq 'HASH') {
                $colmap = $arg;
            } elsif (ref $arg eq 'ARRAY') {
                @{$colmap}{@$arg} = @{$type->columns('P')};
            }
        }
    };
    *{"$class\::$fk_name"} = sub {
        my ($self, $where2, $order2, $limit2, $offset2) = @_;
        $order2 = $order
          if !defined $order2;
        $limit2 = $limit
          if !defined $limit2;
        $offset2 = $offset
          if !defined $offset2;
        &$mk_colmap($self);
        my %where;
        @where{values %$colmap} = @{$self->{values}}{keys %$colmap};
        @where{keys %$where2} = values %$where2
          if $where2;
        return $type->search(\%where, $order2, $limit2, $offset2);
    };
    *{"$class\::add_to_$name"} = sub {
        my $self = shift;
        my %val = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        &$mk_colmap($self);
        @val{values %$colmap} = @{$self->{values}}{keys %$colmap};
        return $type->create(\%val);
    };
    *{"$class\::count_$name"} = sub {
        my $self = shift;
        my %val = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        &$mk_colmap($self);
        @val{values %$colmap} = @{$self->{values}}{keys %$colmap};
        return $type->count(\%val);
    };
    undef $class;
}

=head2 C<has_mapping(name, type, maptype, map1, map2, order, limit, offset)>

You can use has_mapping to map one object to another using an
intermediate table.  You can have these tables:

    Users: id, first_name, etc.
    Groups: id, description, etc.
    Users_To_Groups: user, group

This is quite classical, I suppose, to declare many-to-many
relationships.  The Users_To_Groups contains records that map one user
to one group.  To get the ID-s of all groups that a certain user
belongs to, you would say:

    SELECT group FROM Users_To_Group where user = '$user'

But since you usually need the Group objects directly, you could speed
things up with a join:

    SELECT Groups.id, Groups.description, ... FROM Groups, Users_To_Groups
           WHERE Users_To_Groups.group = Groups.id
             AND Users_To_Groups.user = '$user';

The relationship declared with has_mapping() does exactly that.  You
would call it like this:

    package Users;
    __PACKAGE__->table('Users');
    __PACKAGE__->columns(P => [ 'id' ], ...);

    __PACKAGE__->has_mapping(groups, 'Groups',
                             'Users_To_Groups', 'user', 'group');

    package Groups;
    __PACKAGE__->table('Groups');
    __PACKAGE__->columns(P => [ 'id' ], ...);

    # You can get the reverse mapping as well:
    __PACKAGE__->has_mapping(users, 'Users',
                             'Users_To_Groups', 'group', 'user');

    package Users_To_Groups;
    __PACKAGE__->table('Users_To_Groups');
    __PACKAGE__->columns(P => [ 'user', 'group' ]);

Note that Users_To_Groups has a multiple primary key.  This isn't
required, but you should at least have an unique index for the (user,
group) pair.

=head3 Arguments

I started with an example because the function itself is quite
complicated.  Here are arguments documentation:

=over

=item name

This is used to name the accessors.  By default we will prepend a
"fk_" (see L<get_fk_name>).

=item type

The type of the target objects.

=item maptype

The mapping object type.  This is the name of the object that maps one
type to another.  Even though you'll probably never need to
instantiate such an object, it still has to be declared.

=item map1

Specifies how we map from current package (__PACKAGE__) to the
C<maptype> object.  This can be a scalar or an hash ref.  If it's a
scalar, we will assume that __PACKAGE__ has a simple primary key (not
multiple) and C<map1> is the name of the column from C<maptype> that
we should map this key to.  If it's a hash reference, it should
directly specify the mapping; the keys will be taken from __PACKAGE__
and the values from C<maptype>.  If that sounds horrible, check the
example below.

=item map2

Similar to C<map1>, but C<map2> specifies the mapping from C<maptype>
to the target C<type>.  If a scalar, it will be the name of the column
from C<maptype> that maps to the primary key of the target package
(assumed to be a simple primary key).  If a hash reference, it
specifies the full mapping.

=item order, limit, offset

Similar to has_many, these can specify default ORDER BY and/or
LIMIT/OFFSET clauses for the resulted query.

=back

=head3 Example

Here's the mapping overview:

                     map1                      map2
     __PACKAGE__     ===>    C<maptype>        ===>       C<type>
   current package        table that holds           the target package
                            the mapping

=cut

sub has_mapping {
    my ($class, $name, $type, $maptype, $arg1, $arg2, $order, $limit, $offset) = @_;
    my $fk_name = $class->get_fk_name($name);
    no strict 'refs';
    my ($tcols, $select);
    my @keys;
    *{"$class\::$fk_name"} = sub {
        my ($self, $order2, $limit2, $offset2) = @_;
        $order2 = $order
          if !defined $order2;
        $limit2 = $limit
          if !defined $limit2;
        $offset2 = $offset
          if !defined $offset2;

        my $sa = $self->get_sql_abstract;
        my @bind;
        if (!$select) {
            if (!ref $arg1) {
                my %tmp;
                $tmp{$self->columns('P')->[0]} = $arg1;
                $arg1 = \%tmp;
            } elsif (ref $arg1 eq 'ARRAY') {
                my %tmp;
                @tmp{@{$self->columns('P')}} = @$arg1;
                $arg1 = \%tmp;
            }
            if (!ref $arg2) {
                my %tmp;
                $tmp{$arg2} = $type->columns('P')->[0];
                $arg2 = \%tmp;
            } elsif (ref $arg2 eq 'ARRAY') {
                my %tmp;
                @tmp{@$arg2} = @{$type->columns('P')};
                $arg2 = \%tmp;
            }

            my %where = ();
            my ($st, $tt, $mt) = ($self->table, $type->table, $maptype->table);
            while (my ($k, $v) = each %$arg1) {
                my $tmp = '= ' . $sa->_quote("$mt.$v");
                $where{"$st.$k"} = \$tmp; # SCALAR ref means literal SQL
                $where{"$mt.$v"} = $self->get($k);
                push @keys, $k; # remember these keys to reconstruct @bind later
            }
            while (my ($k, $v) = each %$arg2) {
                my $tmp = '= ' . $sa->_quote("$tt.$v");
                $where{"$mt.$k"} = \$tmp; # SCALAR ref means literal SQL
            }
            $tcols = $type->_get_columns([ 'P', 'E' ]);
            my @fields = map { "$tt.$_" } @$tcols;

            ($select, @bind) = $sa->select([ $st, $mt, $tt ], \@fields, \%where);
        } else {
            @bind = $self->get(@keys);
        }
        my $sql = $select . $sa->order_and_limit($order2, $limit2, $offset2);
        my $sth = $type->_run_sql($sql, \@bind);
        my @ret;
        while (my $row = $sth->fetchrow_arrayref) {
            my $obj = $type->new;
            @{$obj->{values}}{@$tcols} = @$row;
            push @ret, $obj;
        }

        return wantarray ? @ret : \@ret;
    };
}

=head2 C<create>

    my $u = Users->create({ id          => 'foo',
                            first_name  => 'John',
                            last_name   => 'Doe' });

Creates a new record and stores it in the database.  Returns the newly
created object.  We recommend passing a hash reference, but you can
pass a hash by value as well.

=cut

sub create {
    my $self = shift;
    my %val = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $class = __T($self);

    my $obj = $class->new;
    $obj->before_set(\%val, 1);
    $obj->{values} = \%val;
    $obj->_apply_defaults;

    my $sa = $self->get_sql_abstract;
    my ($sql, @bind) = $sa->insert($self->table, \%val);
    my $dbh = $self->get_dbh;
    $self->_run_sql($sql, \@bind);

    my $pk = $self->columns('P');
    $val{$pk->[0]} = $self->_get_last_id($dbh)
      if @$pk == 1 && !exists $val{$pk->[0]};

    # since users may specify SQL functions using an array ref, we
    # remove them in order to get full values later.
    while (my ($k, $v) = each %val) {
        delete $val{$k}
          if ref $v;
    }

    return $obj;
}

=head2 clone(@except)

Clones an object, returning a hash (reference) suitable for create().
Here's how you would call it:

  my $val = $page->clone;
  my $new_page = Pages->create($val);

Or, supposing you don't want to copy the value of the "created" field:

  my $val = $page->clone('created');
  my $new_page = Pages->create($val);

=cut

sub clone {
    my ($self, @except) = @_;
    my %val;
    my $cols = $self->clone_columns(@except);
    @val{@$cols} = $self->get(@$cols);
    return \%val;
}

=head2 C<init_from_data($data)>

Initializes one or more objects from the given data.  $data can be a
hashref (in which case a single object will be created and returned)
or an arrayref (multiple objects will be created and returned as an
array reference).

The hashes simply contain the data, as retrieved from the database.
That is, map column name to field value.

This method is convenient in those cases where you already have the
data (suppose you SELECT-ed it in a different way than using DBIx::OO)
and want to initialize DBIx::OO objects without the penalty of going
through the DB again.

=cut

sub init_from_data {
    my ($class, $data) = @_;
    if (ref $data eq 'ARRAY') {
        my @a = ();
        foreach my $h (@$data) {
            push @a, $class->init_from_data($h);
        }
        return \@a;
    } else {
        my $obj = $class->new;
        $obj->{values} = $data;
        return $obj;
    }
}

=head2 C<retrieve>

    my $u = Users->retrieve('foo');

Retrieves an object from the database.  You need to pass its ID (the
value of the primary key).  If the primary key consists on more
columns, you can pass the values in order as an array, or you can pass
a hash reference.

Returns undef if no objects were found.

=cut

sub retrieve {
    my $class = __T($_[0]);
    my $self = shift;
    my $obj;
    if (ref $self) {            # refresh existing object
        $obj = $self;
        # reset values
        $obj->{values} = $self->_get_pk_where;
        $obj->{modified} = {};
    } else {                    # create new object
        $obj = $class->new;
        if (!ref $_[0]) {
            my $pk = $class->columns('P');
            @{$obj->{values}}{@$pk} = @_;
        } elsif (ref $_[0] eq 'HASH') {
            my ($h) = @_;
            @{$obj->{values}}{keys %$h} = values %$h;
        }
    }
    eval {
        $obj->_retrieve_columns([ 'P', 'E' ]);
    };
    if ($@) {
        ### XXX: a warning should be in order here?  We can't be sure
        ### why did the operation failed...
        undef $obj;
    }
    return $obj;
}

=head2 C<search($where, $order, $limit, $offset)>

    $a = Users->search({ created => [ '>=', '2006-01-01 00:00:00' ]});

Searches the database and returns an array of objects that match the
search criteria.  All arguments are optional.  If you pass no
arguments, it will return an array containing all objects in the DB.
The syntax of C<$where> and C<$order> are described in
L<SQL::Abstract|SQL::Abstract>.

In scalar context it will return a reference to the array.

The C<$limit> and C<$offset> arguments are added by DBIx::OO and allow you
to limit/paginate your query.

UPDATE 0.0.7:

Certain queries are difficult to express in SQL::Abstract syntax.  The
search accepts a literal WHERE clause too, but until version 0.0.7
there was no way to specify bind variables.  For example, now you can
do this:

    @admins = Users->search("mode & ? <> 0 and created > ?",
                            undef, undef, undef,
                            MODE_FLAGS->{admin},
                            strftime('%Y-%m-%d', localtime)).

In order to pass bind variables, you must pass order, limit and offset
(give undef if you don't care about them) and add your bind variables
immediately after.

=cut

sub search {
    my $class = __T(shift);
    my ($where, $order, $limit, $offset) = @_;
    splice @_, 0, 4;
    my $sa = $class->get_sql_abstract;
    my $cols = $class->_get_columns([ 'P', 'E' ]);
    my ($sql, @bind) = $sa->select($class->table, $cols, $where, $order, $limit, $offset);
    if (@_) {
        push @bind, @_;
    }
    my $sth = $class->_run_sql($sql, \@bind);
    my @ret = ();
    while (my $row = $sth->fetchrow_arrayref) {
        my $obj = $class->new;
        @{$obj->{values}}{@$cols} = @$row;
        push @ret, $obj;
    }
    return wantarray ? @ret : \@ret;
}

=head2 C<retrieve_all()>

retrieve_all() is an alias to search() -- since with no arguments it
fetches all objects.

=cut

*retrieve_all = *search;

=head2 C<update>

    $u->set(first_name => 'Foo',
            last_name => 'Bar');
    $u->update;

Saves any modified columns to the database.

=cut

sub update {
    my $class = shift;
    if (ref $class) {
        $class->_do_update;
    } else {
        my ($fieldvals, $where) = @_;
        my $sa = $class->get_sql_abstract;
        my ($sql, @bind) = $sa->update($class->table, $fieldvals, $where);
        $class->_run_sql($sql, \@bind);
    }
}

=head2 C<delete>

    $u = Users->retrieve('foo');
    $u->delete;

Removes the object's record from the database.  Note that the Perl
object remains intact and you can actually revive it (if you're not
losing it) using undelete().

=cut

sub delete {
    my ($self, $where) = @_;
    my ($sql, @bind);
    my $sa = $self->get_sql_abstract;
    if (!defined $where) {
        # we're deleting one object
        ($sql, @bind) = $sa->delete($self->table, $self->_get_pk_where);
    } else {
        # deleting multiple objects at once
        ($sql, @bind) = $sa->delete($self->table, $where);
    }
    $self->_run_sql($sql, \@bind);
}

=head2 C<undelete>

    $u = Users->retrieve('foo');
    $u->delete;    # record's gone
    $u->undelete;  # resurrected

This function can "ressurect" an object that has been deleted (that
is, it re-INSERT-s the record into the database), provided that you
still have a reference to the object.  I'm not sure how useful it is,
but it helped me test the delete() function. :-)

Other (unuseful) thing you can do with it is manually emulating the
create() function:

    $u = new Users;
    $u->{values}{id} = 'foo';
    $u->first_name('Foo');
    $u->last_name('Bar');
    $u->undelete;

Note we can't call the column accessors, nor use set/get, before we
have a primary key.

This method is not too useful in itself, but it helps understanding
the internals of DBIx::OO.  If you want to read more about this, see
L<under the hood>.

=cut

sub undelete {
    my ($self) = @_;
    $self->_apply_defaults;
    my $sa = $self->get_sql_abstract;
    my ($sql, @bind) = $sa->insert($self->table, $self->{values});
    $self->_run_sql($sql, \@bind);
    $self->{modified} = {};
}

=head2 C<revert>, or C<discard_changes>

    $u = Users->retrieve('foo');
    $u->first_name(undef);
    $u->revert;

Discards any changes to the object, reverting to the state in the
database.  Note this doesn't SELECT new data, it just reverts to
values saved in the C<modified> hash.  See L<under the hood> for more
info.

C<discard_changes()> is an alias to C<revert()>.

=cut

sub revert {
    my $self = shift;
    # delete @{$self->{values}}{keys %{$self->{modified}}};
    my $m = $self->{modified};
    @{$self->{values}}{keys %$m} = values %$m;
    $self->{modified} = {};
}

*discard_changes = \&revert;

=head2 get_sql_abstract

Returns the instance of SQL::Abstract::WithLimit (our custom
derivative) suitable for generating SQL.  This is cached (will be
created only the first time get_sql_abstract is called).

=cut

sub get_sql_abstract {
    my $class = shift;
    my $sa = $class->__dboo_sqlabstract;
    if (!defined $sa) {
        $sa = SQL::Abstract::WithLimit->new(quote_char => '`',    # NOTE: MySQL quote style
                                            name_sep   => '.');
        $class->__dboo_sqlabstract($sa);
    }
    return $sa;
}

=head2 count

Returns the result of an SQL COUNT(*) for the specified where clause.
Call this as a package method, for example:

    $number_of_romanians = Users->count({ country => 'RO' });

The argument is an SQL::Abstract where clause.

=cut

sub count {
    my $class = shift;
    my $where = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    my $sql = 'SELECT COUNT(*) FROM ' . $class->table;
    ($where, my @bind) = $class->get_sql_abstract->where($where);
    my $sth = $class->_run_sql($sql.$where, \@bind);
    return $sth->fetchrow_arrayref->[0];
}

sub _get_pk_where {
    my ($self) = @_;
    my $pc = $self->columns('P');
    my %where = ();
    @where{@$pc} = @{$self->{values}}{@$pc};
    return \%where;
}

sub _run_sql {
    my ($class, $sql, $bind) = @_;
#     {
#         ## DEBUG
#         no warnings 'uninitialized';
#         my @a = map { defined $_ ? $_ : 'NULL' } @$bind;
#         print STDERR "\033[1;33mSQL: $sql\nVAL: ", join(", ", @a), "\n\033[0m";
#     }
    my $dbh = $class->get_dbh;
    my $sth = $dbh->prepare($sql);
    if ($bind) {
        $sth->execute(@$bind);
    } else {
        $sth->execute();
    }
    return $sth;
}

sub _do_update {
    my ($self) = @_;
    my %set = ();
    my @k = keys %{$self->{modified}};
    if (@k) {
        @set{@k} = @{$self->{values}}{@k};
        my $where = $self->_get_pk_where;
        my $sa = $self->get_sql_abstract;
        my ($sql, @bind) = $sa->update($self->table, \%set, $where);
        $self->_run_sql($sql, \@bind);
        $self->{modified} = {};
        while (my ($k, $v) = each %set) {
            delete $self->{values}{$k}
              if ref $v;
        }
    }
}

sub _get_columns {
    my ($self, $groups, $exclude) = @_;
    my $ek;
    if (!$groups || @$groups == 0) {
        $ek = $self->columns;
    } elsif (@$groups == 1) {
        $ek = $self->columns($groups->[0]);
    } else {
        $ek = [];
        foreach my $g (@$groups) {
            my $a = $self->columns($g);
            push @$ek, @{$a}
              if $a;
        }
    }
    if (defined $exclude && %$exclude) {
        $ek = [ grep { !exists $exclude->{$_} } @$ek ];
    }
    return $ek;
}

sub _retrieve_columns {
    my ($self, $groups, $exclude) = @_;
    if (!ref $groups) {
        $groups = [ $groups ];
    }
    my $ek = $self->_get_columns($groups, $exclude || $self->{modified});
    my $where = $self->_get_pk_where;
    my $sa = $self->get_sql_abstract;
    my ($sql, @bind) = $sa->select($self->table, $ek, $where);
    my $sth = $self->_run_sql($sql, \@bind);
    my $data = $sth->fetchrow_arrayref;
    @{$self->{values}}{@$ek} = @$data;
}

sub _get_last_id {
    my ($self, $dbh) = @_;
    my $id = $dbh->last_insert_id(undef, undef, $self->table, undef)
      || $dbh->{mysql_insertid}
        || eval { $dbh->func('last_insert_rowid') }
          or $self->_croak("Can't get last insert id");
    return $id;
}

sub _col_in_group {
    my ($class, $col, $group) = @_;
    my $h = $class->__dboo_colgroups;
    return if !$h;
    return $h->{$col} eq $group;
}

sub _croak {
    Carp::croak(join("\n", @_));
}

sub _apply_defaults {
    my ($self) = @_;
    my $class = __T($self);
    my $def = $class->__dboo_defaults;
    if ($def && %$def) {
        my $val = $self->{values};
        while (my ($k, $v) = each %$def) {
            if (!exists $val->{$k}) {
                if (ref $v eq 'CODE') {
                    $v = &$v();
                }
                $val->{$k} = $v;
            }
        }
    }
}

## thanks Altblue!
sub _to_utf8 {
    my ($str) = @_;
    return $str
      if Encode::is_utf8($str);
    eval {
        $str = Encode::decode_utf8($str);
    };
    if ($@) {
        $str = Encode::decode('Detect', $str);
    }
    return $str;
}

=head2 C<disable_fk_checks()>, C<enable_fk_checks()>

Enable or disable foreign key checks in the backend DB server.  These
are hard-coded in MySQL syntax for now so be careful not to use them
with other servers. ;-)

=cut

sub disable_fk_checks {
    my ($pak) = @_;
    # XXX: MySQL only for now
    $pak->get_dbh->do('set foreign_key_checks = 0');
}

sub enable_fk_checks {
    my ($pak) = @_;
    # XXX: MySQL only for now
    $pak->get_dbh->do('set foreign_key_checks = 1');
}

sub DESTROY {
    my $self = shift;
    my @a = keys %{$self->{modified}};
    if (@a) {
        my @id = $self->id;
        warn("Destroying ", ref $self, " with ID: ", join(':', @id), ' having uncomitted data: ', join(':', @a));
    }
}

## database autocreate/update facility

=head2 C<autocreate(@packages)>

You can use this facility to automatically create / upgrade your
database.  It takes a very simple (rudimentary even) approach, but we
found it to be useful.  Here's the "big" idea.

    package MyDB::Users;
    use base 'MyDB';

    __PACKAGE__->table('Users');
    __PACKAGE__->columns(P => [ 'id' ],
                         E => [qw/ first_name last_name /]);


    sub get_autocreate_data {q{
    #### (users:0) ####

    CREATE TABLE Users ( id VARCHAR(32) NOT NULL PRIMARY KEY,
                         first_name VARCHAR(64),
                         last_name VARCHAR(64) );

    # you can put Perl comments too.

    CREATE INDEX idx_Users_first_name ON Users(first_name)
    }}

OK, now you can write this make_database.pl script:

    /usr/bin/perl -w

    use MyDB;
    MyDB->autocreate(qw( MyDB::Users ));

When you run this script the first time, it will create the Users
table.  (An internal _dbix_oo_versions table gets created as well;
we're using it inside DBIx::OO in order to keep track of existing
table versions).  Note that if you run it again, it doesn't do
anything--the database is up to date.

Later.  You sold a billion copies of your software, customers are
happy but they are crying loud for an "email" field in their user
profiles, also wondering what was your idea to index on first_name and
not on last_name!  In order to make it easy for them to upgrade their
databases, you need to modify MyDB::Users.  Besides declaring the
'email' column using __PACKAGE__->columns, B<append> the following to
your get_autocreate_data section:

    #### (users:1) ####

    # (note that we incremented the version number)

    # add the 'email' field
    ALTER TABLE Users ADD (email VARCHAR(128));

    # index it
    CREATE UNIQUE INDEX idx_Users_email ON Users(email);

    # and add that last_name index
    CREATE INDEX idx_Users_last_name ON Users(last_name);

Now you can just tell your users to run make_database.pl again and
everything gets updated.

The #### (foo:N) #### syntax is meant simply to declare an ID and a
version number.  "foo" can be anything you want -- it doesn't have to
be the table name.  You can actually create multiple tables, if you
need to.

=cut

sub autocreate {
    my ($class, @packages) = @_;
    $class->disable_fk_checks;
    $class->transaction_start;
    eval {
        use Module::Load qw( load );

        # make sure _dbix_oo_versions gets created first
        my @sql_lines = split(/^/m, get_autocreate_data());
        $class->__do_autocreate(@sql_lines);

        # autocreate other packages that were passed
        foreach my $pak (@packages) {
            load $pak;
            @sql_lines = split(/^/m, $pak->get_autocreate_data());
            $class->__do_autocreate(@sql_lines);
        }
    };
    if ($@) {
        $class->transaction_rollback;
        print STDERR "\033[1;31m- There was a problem auto-creating or upgrading tables, can't continue -\033[0m\n";
        die $@;
    } else {
        $class->transaction_commit;
    }
    foreach my $pak (@packages) {
        $pak->autopopulate;
    }
    $class->enable_fk_checks;
}

=head2 autopopulate

This is supposed to initialize tables.  Untested and may not work --
don't use it.

=cut

sub autopopulate {}

=head2 get_autocreate_data

See the documentation of L</autocreate>.

=cut

sub get_autocreate_data {q{
    #### (_dbix_oo_versions:0) ####

    CREATE TABLE _dbix_oo_versions ( TB_name VARCHAR(255) PRIMARY KEY,
                                     TB_version INTEGER );
}}

my $AUTOCREATE_LINE_RE = qr/^\s*####\s*\(([a-z0-9_-]+):([0-9]+)\)\s*####\s*$/i;
# my $AUTOCREATE_SPLIT_SQLS = qr/^\s*##\s*$/m;
my $AUTOCREATE_SPLIT_SQLS = qr/;\s*$/m;
my $AUTOCREATE_TABLES_TABLE = '_dbix_oo_versions';

sub __do_autocreate {
    my ($class, @lines) = @_;

    my $tables = $class->__autocreate_parse_lines(\@lines);

    my $dbh = $class->get_dbh;
    my $sth = $dbh->table_info('', '', $AUTOCREATE_TABLES_TABLE);
    my $existing_tables = $sth->fetchall_hashref('TABLE_NAME');
    my $has_version = exists $existing_tables->{$AUTOCREATE_TABLES_TABLE};
    $sth->finish;

    while (my ($t, $versions) = each %$tables) {
        $class->__autocreate_one_table($t, $versions, $has_version);
    }
}

sub __autocreate_one_table {
    my ($class, $t, $versions, $has_version) = @_;
    my $dbh = $class->get_dbh;
    my $cv = -1;
    if ($has_version) {
        my $sql = $dbh->prepare("SELECT TB_version FROM $AUTOCREATE_TABLES_TABLE WHERE TB_name = ?");
        $sql->execute($t);
        ($cv) = $sql->fetchrow_array;
        $sql->finish;
        if (!defined $cv) {
            $cv = -1;
            $sql = $dbh->prepare("INSERT INTO $AUTOCREATE_TABLES_TABLE (TB_name, TB_version) VALUES (?, ?)");
            $sql->execute($t, $cv);
            $sql->finish;
        }
    }
    my $sql_insert = $dbh->prepare("INSERT INTO $AUTOCREATE_TABLES_TABLE (TB_name, TB_version) VALUES (?, ?)");
    my $sql_delete = $dbh->prepare("DELETE FROM $AUTOCREATE_TABLES_TABLE WHERE TB_name = ?");
    foreach my $v (sort keys %$versions) {
        if ($v > $cv) {
            # print STDERR "$versions->{$v}\n";
            my @statements = split($AUTOCREATE_SPLIT_SQLS, $versions->{$v});
            foreach my $sql (@statements) {
                $sql =~ s/#.*$//mg;
                $sql =~ s/^\s+//;
                $sql =~ s/\s+$//;
                $sql =~ s/,\s*\)/)/g;
                if ($sql) {
                    # print STDERR "  $sql\n";
                    my $n = index($sql, "\n");
                    print STDERR "... $t: " . substr($sql, 0, $n) . "\n";
                    $dbh->do($sql);
                }
            }
            $sql_delete->execute($t);
            $sql_insert->execute($t, $v);
        }
    }
    $sql_insert->finish;
    $sql_delete->finish;
}

sub __autocreate_parse_lines {
    my ($class, $lines) = @_;
    my ($h, $ct, $cv, $cs) = ({}, undef, undef, undef);
    my $doit = sub {
        if (defined $ct) {
            $h->{$ct} ||= {};
            $cs =~ s/^\s+//;
            $cs =~ s/\s+$//;
            $h->{$ct}{$cv} = $cs;
        }
    };
    foreach my $i (@$lines) {
        if ($i =~ $AUTOCREATE_LINE_RE) {
            &$doit;
            $ct = $1;
            $cv = $2;
            $cs = '';
        } elsif (defined $ct) {
            $cs .= $i;
        }
    }
    &$doit;
    # print STDERR Data::Dumper::Dumper($h);
    return $h;
}

=head1 CAVEATS

There are a number of problems you might encounter, mostly related to
the fact that we don't cache objects.

=head2 Concurrent objects

    $u1 = Users->retrieve('foo');
    $u2 = Users->retrieve('foo');

C<$u1> and C<$u2> now point to different objects, but both point to
the same record in the database.  Now the problem:

    $u1->first_name('Foo');
    $u2->first_name('Bar');
    $u1->update;

Which one gets set?  'Foo', but $u2 has uncommitted changes.  When you
further say $u2->update, it will set the name to 'Bar'.  If you say
$u2->revert, it will revert to whatever was there I<before> 'Foo'.
This can lead to potential problems.

Class::DBI (almost) doesn't have this problem (it can appear when you
have multiple processes accessing the database concurrently, such as
httpd processes).

=head1 UNDER THE HOOD

A DBIx::OO object is a hash blessed into the DBIx::OO package.
The hash currently contains 2 keys:

=over

=item B<values>

A hash containing the field => value pairs that are currently
retrieved from the database.

=item B<modified>

Another hash that maps field_name => 'original value' for the fields
that were modified and not yet committed of the current object.

=back

If a field is not present in B<values> and is requested with get(),
then the database will be queried for it and for all other fields that
aren't present in "values" but are listed in the B<E>ssential group.

If a field is present in B<modified>, then it will be saved in the DB
on the next update() call.  An object can discard these operations
with the discard() method.  Discard restores the values using those
stored in the C<modified> hash.

Each operation plays around these hashes.  For instance, when you call
search(), a single SQL will run and then we'll iterate over the
results, create objects and assign the SELECT-ed values to the
B<values> hash.

A retrieve() operation creates a new object and assign the passed
value to its primary key, then it will call the internal
_retrieve_columns([ 'P', 'E' ]) function in order to fetch essential
object data from the DB.  Note that a call to _retrieve_columns is not
actually necessary, since it will happen anyway the first time you
want to retrieve a field that doesn't exist in B<values> -- but it's
good to call it because retrieve() should return B<undef> if the
object can't be found in the DB.

=head1 BUGS

Yeah, the documentation sucks.  Other bugs?

=head1 SEE ALSO

L<SQL::Abstract>, L<Class::DBI>, L<DBIx::Class>

=head1 AUTHOR

Mihai Bazon, <mihai.bazon@gmail.com>
    http://www.dynarch.com/
    http://www.bazon.net/mishoo/

=head1 COPYRIGHT

Copyright (c) Mihai Bazon 2006.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 THANKS

I'd like to thank irc.n0i.net -- our small but wonderful community
that's always there when you need it.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut







package SQL::Abstract::WithLimit;
use base 'SQL::Abstract';

### MySQL and Postgres syntax; Buzz off for others. :-p
sub select {
    my ($self, $table, $cols, $where, $order, $limit, $offset) = @_;
    my ($sql, @bind) = $self->SUPER::select($table, $cols, $where, $order);
    $sql .= $self->order_and_limit(undef, $limit, $offset);
    return wantarray ? ($sql, @bind) : $sql;
}

sub _order_by {
    my $self = shift;
    my $ref = ref $_[0];

    my @vals = $ref eq 'ARRAY'  ? @{$_[0]} :
               $ref eq 'SCALAR' ? ${$_[0]} :
               $ref eq ''       ? $_[0]    :
               SQL::Abstract::puke("Unsupported data struct $ref for ORDER BY");

    my $val = join ', ', map {
        s/^\^// ?
          $self->_quote($_) . $self->_sqlcase(' desc')
            : $self->_quote($_)
        } @vals;
    return $val ? $self->_sqlcase(' order by')." $val" : '';
}

sub order_and_limit {
    my ($self, $order, $limit, $offset) = @_;
    my $q = $order ? $self->_order_by($order) : '';
    $q .= " LIMIT $limit"
      if defined $limit;
    $q .= " OFFSET $offset"
      if defined $offset;
    return $q;
}

*quote_field = \&SQL::Abstract::_quote;
