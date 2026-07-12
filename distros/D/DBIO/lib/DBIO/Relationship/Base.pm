package DBIO::Relationship::Base;
# ABSTRACT: Inter-table relationships

use strict;
use warnings;

use base qw/DBIO::Base/;

use Scalar::Util qw/weaken blessed/;
use Try::Tiny;
use DBIO::Util 'UNRESOLVABLE_CONDITION';
use namespace::clean;


sub register_relationship { }


sub related_resultset {
  my $self = shift;

  $self->throw_exception("Can't call *_related as class methods")
    unless ref $self;

  my $rel = shift;

  return $self->{related_resultsets}{$rel}
    if defined $self->{related_resultsets}{$rel};

  return $self->{related_resultsets}{$rel} = do {

    my $rsrc = $self->result_source;

    my $rel_info = $rsrc->relationship_info($rel)
      or $self->throw_exception( "No such relationship '$rel'" );

    my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
    $attrs = { %{$rel_info->{attrs} || {}}, %$attrs };

    $self->throw_exception( "Invalid query: @_" )
      if (@_ > 1 && (@_ % 2 == 1));
    my $query = ((@_ > 1) ? {@_} : shift);

    # condition resolution may fail if an incomplete master-object prefetch
    # is encountered - that is ok during prefetch construction (not yet in_storage)
    my ($cond, $is_crosstable) = try {
      $rsrc->_resolve_condition( $rel_info->{cond}, $rel, $self, $rel )
    }
    catch {
      $self->throw_exception ($_) if $self->in_storage;
      UNRESOLVABLE_CONDITION;  # RV, no return()
    };

    # keep in mind that the following if() block is part of a do{} - no return()s!!!
    if ($is_crosstable and ref $rel_info->{cond} eq 'CODE') {

      # A WHOREIFFIC hack to reinvoke the entire condition resolution
      # with the correct alias. Another way of doing this involves a
      # lot of state passing around, and the @_ positions are already
      # mapped out, making this crap a less icky option.
      #
      # The point of this exercise is to retain the spirit of the original
      # $obj->search_related($rel) where the resulting rset will have the
      # root alias as 'me', instead of $rel (as opposed to invoking
      # $rs->search_related)

      # make the fake 'me' rel
      local $rsrc->{_relationships}{me} = {
        %{ $rsrc->{_relationships}{$rel} },
        _original_name => $rel,
      };

      my $obj_table_alias = lc($rsrc->source_name) . '__row';
      $obj_table_alias =~ s/\W+/_/g;

      $rsrc->resultset->search(
        $self->ident_condition($obj_table_alias),
        { alias => $obj_table_alias },
      )->search_related('me', $query, $attrs)
    }
    else {
      # FIXME - this conditional doesn't seem correct - got to figure out
      # at some point what it does. Also the entire UNRESOLVABLE_CONDITION
      # business seems shady - we could simply not query *at all*
      if ($cond eq UNRESOLVABLE_CONDITION) {
        my $reverse = $rsrc->reverse_relationship_info($rel);
        foreach my $rev_rel (keys %$reverse) {
          if ($reverse->{$rev_rel}{attrs}{accessor} && $reverse->{$rev_rel}{attrs}{accessor} eq 'multi') {
            weaken($attrs->{related_objects}{$rev_rel}[0] = $self);
          } else {
            weaken($attrs->{related_objects}{$rev_rel} = $self);
          }
        }
      }
      elsif (ref $cond eq 'ARRAY') {
        $cond = [ map {
          if (ref $_ eq 'HASH') {
            my $hash;
            foreach my $key (keys %$_) {
              my $newkey = $key !~ /\./ ? "me.$key" : $key;
              $hash->{$newkey} = $_->{$key};
            }
            $hash;
          } else {
            $_;
          }
        } @$cond ];
      }
      elsif (ref $cond eq 'HASH') {
       foreach my $key (grep { ! /\./ } keys %$cond) {
          $cond->{"me.$key"} = delete $cond->{$key};
        }
      }

      $query = ($query ? { '-and' => [ $cond, $query ] } : $cond);
      $rsrc->related_source($rel)->resultset->search(
        $query, $attrs
      );
    }
  };
}


sub search_related {
  return shift->related_resultset(shift)->search(@_);
}


sub search_related_rs {
  return shift->related_resultset(shift)->search_rs(@_);
}


sub count_related {
  shift->search_related(@_)->count;
}


sub new_related {
  my ($self, $rel, $data) = @_;

  return $self->search_related($rel)->new_result( $self->result_source->_resolve_relationship_condition (
    infer_values_based_on => $data,
    rel_name => $rel,
    self_result_object => $self,
    foreign_alias => $rel,
    self_alias => 'me',
  )->{inferred_values} );
}


sub create_related {
  my $self = shift;
  my $rel = shift;
  my $obj = $self->new_related($rel, @_)->insert;
  delete $self->{related_resultsets}->{$rel};
  return $obj;
}


sub find_related {
  #my ($self, $rel, @args) = @_;
  return shift->search_related(shift)->find(@_);
}


sub find_or_new_related {
  my $self = shift;
  my $obj = $self->find_related(@_);
  return defined $obj ? $obj : $self->new_related(@_);
}


sub find_or_create_related {
  my $self = shift;
  my $obj = $self->find_related(@_);
  return (defined($obj) ? $obj : $self->create_related(@_));
}


sub update_or_create_related {
  #my ($self, $rel, @args) = @_;
  shift->related_resultset(shift)->update_or_create(@_);
}


sub set_from_related {
  my ($self, $rel, $f_obj) = @_;

  $self->set_columns( $self->result_source->_resolve_relationship_condition (
    infer_values_based_on => {},
    rel_name => $rel,
    foreign_values => $f_obj,
    foreign_alias => $rel,
    self_alias => 'me',
  )->{inferred_values} );

  return 1;
}


sub update_from_related {
  my $self = shift;
  $self->set_from_related(@_);
  $self->update;
}


sub delete_related {
  my $self = shift;
  my $obj = $self->search_related(@_)->delete;
  delete $self->{related_resultsets}->{$_[0]};
  return $obj;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::Base - Inter-table relationships

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  __PACKAGE__->add_relationship(
    spiders => 'My::DB::Result::Creatures',
    sub {
      my $args = shift;
      return {
        "$args->{foreign_alias}.id"   => { -ident => "$args->{self_alias}.id" },
        "$args->{foreign_alias}.type" => 'arachnid'
      };
    },
  );

See F<t/relationship/dynamic_foreign_columns.t> for a runnable example.

=head1 DESCRIPTION

This class provides methods to describe the relationships between the
tables in your database model. These are the "bare bones" relationships
methods, for predefined ones, look in L<DBIO::Relationship>.

=head1 METHODS

=head2 add_relationship

=over 4

=item Arguments: $rel_name, $foreign_class, $condition, $attrs

=back

  __PACKAGE__->add_relationship('rel_name',
                                'Foreign::Class',
                                $condition, $attrs);

Create a custom relationship between one result source and another
source, indicated by its class name.

=head3 condition

The condition argument describes the C<ON> clause of the C<JOIN>
expression used to connect the two sources when creating SQL queries.

=head4 Simple equality

To create simple equality joins, supply a hashref containing the remote
table column name as the key(s) prefixed by C<'foreign.'>, and the
corresponding local table column name as the value(s) prefixed by C<'self.'>.
Both C<foreign> and C<self> are pseudo aliases and must be entered
literally. They will be replaced with the actual correct table alias
when the SQL is produced.

For example given:

  My::Schema::Author->has_many(
    books => 'My::Schema::Book',
    { 'foreign.author_id' => 'self.id' }
  );

A query like:

  $author_rs->search_related('books')->next

will result in the following C<JOIN> clause:

  ... FROM author me LEFT JOIN book books ON books.author_id = me.id ...

This describes a relationship between the C<Author> table and the
C<Book> table where the C<Book> table has a column C<author_id>
containing the ID value of the C<Author>.

Similarly:

  My::Schema::Book->has_many(
    editions => 'My::Schema::Edition',
    {
      'foreign.publisher_id' => 'self.publisher_id',
      'foreign.type_id'      => 'self.type_id',
    }
  );

  ...

  $book_rs->search_related('editions')->next

will result in the C<JOIN> clause:

  ... FROM book me
      LEFT JOIN edition editions ON
           editions.publisher_id = me.publisher_id
       AND editions.type_id = me.type_id ...

This describes the relationship from C<Book> to C<Edition>, where the
C<Edition> table refers to a publisher and a type (e.g. "paperback"):

=head4 Multiple groups of simple equality conditions

As is the default in L<SQL::Abstract>, the key-value pairs will be
C<AND>ed in the resulting C<JOIN> clause. An C<OR> can be achieved with
an arrayref. For example a condition like:

  My::Schema::Item->has_many(
    related_item_links => My::Schema::Item::Links,
    [
      { 'foreign.left_itemid'  => 'self.id' },
      { 'foreign.right_itemid' => 'self.id' },
    ],
  );

will translate to the following C<JOIN> clause:

 ... FROM item me JOIN item_relations related_item_links ON
         related_item_links.left_itemid = me.id
      OR related_item_links.right_itemid = me.id ...

This describes the relationship from C<Item> to C<Item::Links>, where
C<Item::Links> is a many-to-many linking table, linking items back to
themselves in a peer fashion (without a "parent-child" designation)

=head4 Custom join conditions

  NOTE: The custom join condition specification mechanism is capable of
  generating JOIN clauses of virtually unlimited complexity. This may limit
  your ability to traverse some of the more involved relationship chains the
  way you expect, *and* may bring your RDBMS to its knees. Exercise care
  when declaring relationships as described here.

To specify joins which describe more than a simple equality of column
values, the custom join condition coderef syntax can be used. For
example:

  My::Schema::Artist->has_many(
    cds_80s => 'My::Schema::CD',
    sub {
      my $args = shift;

      return {
        "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
        "$args->{foreign_alias}.year"   => { '>', "1979", '<', "1990" },
      };
    }
  );

  ...

  $artist_rs->search_related('cds_80s')->next;

will result in the C<JOIN> clause:

  ... FROM artist me LEFT JOIN cd cds_80s ON
        cds_80s.artist = me.artistid
    AND cds_80s.year < ?
    AND cds_80s.year > ?

with the bind values:

   '1990', '1979'

C<< $args->{foreign_alias} >> and C<< $args->{self_alias} >> are supplied the
same values that would be otherwise substituted for C<foreign> and C<self>
in the simple hashref syntax case.

The coderef is expected to return a valid L<SQL::Abstract>
query-structure, just like what one would supply as the first argument to
L<DBIO::ResultSet/search>. The return value will be passed directly to
L<DBIO::SQLMaker> and the resulting SQL will be used verbatim as the
C<ON> clause of the C<JOIN> statement associated with this relationship.

While every coderef-based condition must return a valid C<ON> clause, it may
elect to additionally return a simplified B<optional> join-free condition
consisting of a hashref with B<all keys being fully qualified names of columns
declared on the corresponding result source>. This boils down to two scenarios:

=over

=item *

When relationship resolution is invoked after C<< $result->$rel_name >>, as
opposed to C<< $rs->related_resultset($rel_name) >>, the C<$result> object
is passed to the coderef as C<< $args->{self_result_object} >>.

=item *

Alternatively when the user-space invokes resolution via
C<< $result->set_from_related( $rel_name => $foreign_values_or_object ) >>, the
corresponding data is passed to the coderef as C<< $args->{foreign_values} >>,
B<always> in the form of a hashref. If a foreign result object is supplied
(which is valid usage of L</set_from_related>), its values will be extracted
into hashref form by calling L<get_columns|DBIO::Row/get_columns>.

=back

Note that the above scenarios are mutually exclusive, that is you will be supplied
none or only one of C<self_result_object> and C<foreign_values>. In other words if
you define your condition coderef as:

  sub {
    my $args = shift;

    return (
      {
        "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
        "$args->{foreign_alias}.year"   => { '>', "1979", '<', "1990" },
      },
      ! $args->{self_result_object} ? () : {
        "$args->{foreign_alias}.artist" => $args->{self_result_object}->artistid,
        "$args->{foreign_alias}.year"   => { '>', "1979", '<', "1990" },
      },
      ! $args->{foreign_values} ? () : {
        "$args->{self_alias}.artistid" => $args->{foreign_values}{artist},
      }
    );
  }

Then this code:

    my $artist = $schema->resultset("Artist")->find({ id => 4 });
    $artist->cds_80s->all;

Can skip a C<JOIN> altogether and instead produce:

    SELECT cds_80s.cdid, cds_80s.artist, cds_80s.title, cds_80s.year, cds_80s.genreid, cds_80s.single_track
      FROM cd cds_80s
      WHERE cds_80s.artist = ?
        AND cds_80s.year < ?
        AND cds_80s.year > ?

With the bind values:

    '4', '1990', '1979'

While this code:

    my $cd = $schema->resultset("CD")->search({ artist => 1 }, { rows => 1 })->single;
    my $artist = $schema->resultset("Artist")->new({});
    $artist->set_from_related('cds_80s');

Will properly set the C<< $artist->artistid >> field of this new object to C<1>

Note that in order to be able to use L</set_from_related> (and by extension
L<< $result->create_related|DBIO::Relationship::Base/create_related >>),
the returned join free condition B<must> contain only plain values/deflatable
objects. For instance the C<year> constraint in the above example prevents
the relationship from being used to create related objects using
C<< $artst->create_related( cds_80s => { title => 'blah' } ) >> (an
exception will be thrown).

In order to allow the user to go truly crazy when generating a custom C<ON>
clause, the C<$args> hashref passed to the subroutine contains some extra
metadata. Currently the supplied coderef is executed as:

  $relationship_info->{cond}->({
    self_resultsource   => The resultsource instance on which rel_name is registered
    rel_name            => The relationship name (does *NOT* always match foreign_alias)

    self_alias          => The alias of the invoking resultset
    foreign_alias       => The alias of the to-be-joined resultset (does *NOT* always match rel_name)

    # only one of these (or none at all) will ever be supplied to aid in the
    # construction of a join-free condition

    self_result_object  => The invocant *object* itself in case of a call like
                           $result_object->$rel_name( ... )

    foreign_values      => A *hashref* of related data: may be passed in directly or
                           derived via ->get_columns() from a related object in case of
                           $result_object->set_from_related( $rel_name, $foreign_result_object )

    # deprecated inconsistent names, will be forever available for legacy code
    self_rowobj         => Old deprecated slot for self_result_object
    foreign_relname     => Old deprecated slot for rel_name
  });

=head3 attributes

The L<standard ResultSet attributes|DBIO::ResultSet/ATTRIBUTES> may
be used as relationship attributes. In particular, the 'where' attribute is
useful for filtering relationships:

     __PACKAGE__->has_many( 'valid_users', 'MyApp::Schema::User',
        { 'foreign.user_id' => 'self.user_id' },
        { where => { valid => 1 } }
    );

The following attributes are also valid:

=over 4

=item join_type

Explicitly specifies the type of join to use in the relationship. Any SQL
join type is valid, e.g. C<LEFT> or C<RIGHT>. It will be placed in the SQL
command immediately before C<JOIN>.

=item proxy =E<gt> $column | \@columns | \%column

The 'proxy' attribute can be used to retrieve values, and to perform
updates if the relationship has 'cascade_update' set. The 'might_have'
and 'has_one' relationships have this set by default; if you want a proxy
to update across a 'belongs_to' relationship, you must set the attribute
yourself.

=over 4

=item \@columns

An arrayref containing a list of accessors in the foreign class to create in
the main class. If, for example, you do the following:

  MyApp::Schema::CD->might_have(liner_notes => 'MyApp::Schema::LinerNotes',
    undef, {
      proxy => [ qw/notes/ ],
    });

Then, assuming MyApp::Schema::LinerNotes has an accessor named notes, you can do:

  my $cd = MyApp::Schema::CD->find(1);
  $cd->notes('Notes go here'); # set notes -- LinerNotes object is
                               # created if it doesn't exist

For a 'belongs_to relationship, note the 'cascade_update':

  MyApp::Schema::Track->belongs_to( cd => 'MyApp::Schema::CD', 'cd,
      { proxy => ['title'], cascade_update => 1 }
  );
  $track->title('New Title');
  $track->update; # updates title in CD

=item \%column

A hashref where each key is the accessor you want installed in the main class,
and its value is the name of the original in the foreign class.

  MyApp::Schema::Track->belongs_to( cd => 'MyApp::Schema::CD', 'cd', {
      proxy => { cd_title => 'title' },
  });

This will create an accessor named C<cd_title> on the C<$track> result object.

=back

NOTE: you can pass a nested struct too, for example:

  MyApp::Schema::Track->belongs_to( cd => 'MyApp::Schema::CD', 'cd', {
    proxy => [ 'year', { cd_title => 'title' } ],
  });

=item accessor

Specifies the type of accessor that should be created for the relationship.
Valid values are C<single> (for when there is only a single related object),
C<multi> (when there can be many), and C<filter> (for when there is a single
related object, but you also want the relationship accessor to double as
a column accessor). For C<multi> accessors, an add_to_* method is also
created, which calls C<create_related> for the relationship.

=item is_foreign_key_constraint

If you find that DBIO is creating constraints where it shouldn't, or not
creating them where it should, set this attribute to a true or false value
to override the detection of when to create constraints.

=item cascade_copy

If C<cascade_copy> is true on a C<has_many> relationship for an
object, then when you copy the object all the related objects will
be copied too. To turn this behaviour off, pass C<< cascade_copy => 0 >>
in the C<$attr> hashref.

The behaviour defaults to C<< cascade_copy => 1 >> for C<has_many>
relationships.

=item cascade_delete

By default, DBIO cascades deletes across C<has_many>,
C<has_one> and C<might_have> relationships. You can disable this
behaviour on a per-relationship basis by supplying
C<< cascade_delete => 0 >> in the relationship attributes.

The cascaded operations are performed after the requested delete,
so if your database has a constraint on the relationship, it will
have deleted/updated the related records or raised an exception
before DBIO gets to perform the cascaded operation.

=item cascade_update

By default, DBIO cascades updates across C<has_one> and
C<might_have> relationships. You can disable this behaviour on a
per-relationship basis by supplying C<< cascade_update => 0 >> in
the relationship attributes.

The C<belongs_to> relationship does not update across relationships
by default, so if you have a 'proxy' attribute on a belongs_to and want to
use 'update' on it, you must set C<< cascade_update => 1 >>.

This is not a RDMS style cascade update - it purely means that when
an object has update called on it, all the related objects also
have update called. It will not change foreign keys automatically -
you must arrange to do this yourself.

=item on_delete / on_update

Use these attributes to explicitly set the desired C<ON DELETE> or
C<ON UPDATE> constraint type. For any 'multi' relationship with
C<< cascade_delete => 1 >>, the corresponding belongs_to relationship
will be created with an C<ON DELETE CASCADE> constraint. For any relationship
bearing C<< cascade_copy => 1 >> the resulting belongs_to constraint will be
C<ON UPDATE CASCADE>. If you wish to disable this autodetection, and just use
the RDBMS' default constraint type, pass C<< on_delete => undef >> or
C<< on_delete => '' >>, and the same for C<on_update> respectively.

=item is_deferrable

Indicates that the foreign key constraint should be deferrable. In other
words, the user may request that the constraint be ignored until the end
of the transaction. Currently, only the PostgreSQL producer actually
supports this.

=item add_fk_index

If true, adds an index for this constraint. Can also be specified globally
in the args to L<DBIO::Schema/deploy>. Default is on, set to 0 to disable.

=back

=head2 register_relationship

=over 4

=item Arguments: $rel_name, $rel_info

=back

Registers a relationship on the class. This is called internally by
DBIO::ResultSourceProxy to set up Accessors and Proxies.

=head2 related_resultset

=over 4

=item Arguments: $rel_name

=item Return Value: L<$related_resultset|DBIO::ResultSet>

=back

  $rs = $cd->related_resultset('artist');

Returns a L<DBIO::ResultSet> for the relationship named
$rel_name.

=head2 $relationship_accessor

=over 4

=item Arguments: none

=item Return Value: L<$result|DBIO::Manual::ResultClass> | L<$related_resultset|DBIO::ResultSet> | undef

=back

  # These pairs do the same thing
  $result = $cd->related_resultset('artist')->single;  # has_one relationship
  $result = $cd->artist;
  $rs = $cd->related_resultset('tracks');           # has_many relationship
  $rs = $cd->tracks;

This is the recommended way to traverse through relationships, based
on the L</accessor> name given in the relationship definition.

This will return either a L<Result|DBIO::Manual::ResultClass> or a
L<ResultSet|DBIO::ResultSet>, depending on if the relationship is
C<single> (returns only one row) or C<multi> (returns many rows).  The
method may also return C<undef> if the relationship doesn't exist for
this instance (like in the case of C<might_have> relationships).

=head2 search_related

=over 4

=item Arguments: $rel_name, $cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=item Return Value: L<$resultset|DBIO::ResultSet> (scalar context) | L<@result_objs|DBIO::Manual::ResultClass> (list context)

=back

Run a search on a related resultset. The search will be restricted to the
results represented by the L<DBIO::ResultSet> it was called
upon.

See L<DBIO::ResultSet/search_related> for more information.

=head2 search_related_rs

This method works exactly the same as search_related, except that
it guarantees a resultset, even in list context.

=head2 count_related

=over 4

=item Arguments: $rel_name, $cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=item Return Value: $count

=back

Returns the count of all the rows in the related resultset, restricted by the
current result or where conditions.

=head2 new_related

=over 4

=item Arguments: $rel_name, \%col_data

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Create a new result object of the related foreign class.  It will magically set
any foreign key columns of the new object to the related primary key columns
of the source object for you.  The newly created result will not be saved into
your storage until you call L<DBIO::Row/insert> on it.

=head2 create_related

=over 4

=item Arguments: $rel_name, \%col_data

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  my $result = $obj->create_related($rel_name, \%col_data);

Creates a new result object, similarly to new_related, and also inserts the
result's data into your storage medium. See the distinction between C<create>
and C<new> in L<DBIO::ResultSet> for details.

=head2 find_related

=over 4

=item Arguments: $rel_name, \%col_data | @pk_values, { key => $unique_constraint, L<%attrs|DBIO::ResultSet/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass> | undef

=back

  my $result = $obj->find_related($rel_name, \%col_data);

Attempt to find a related object using its primary key or unique constraints.
See L<DBIO::ResultSet/find> for details.

=head2 find_or_new_related

=over 4

=item Arguments: $rel_name, \%col_data, { key => $unique_constraint, L<%attrs|DBIO::ResultSet/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Find a result object of a related class.  See L<DBIO::ResultSet/find_or_new>
for details.

=head2 find_or_create_related

=over 4

=item Arguments: $rel_name, \%col_data, { key => $unique_constraint, L<%attrs|DBIO::ResultSet/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Find or create a result object of a related class. See
L<DBIO::ResultSet/find_or_create> for details.

=head2 update_or_create_related

=over 4

=item Arguments: $rel_name, \%col_data, { key => $unique_constraint, L<%attrs|DBIO::ResultSet/ATTRIBUTES> }?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Update or create a result object of a related class. See
L<DBIO::ResultSet/update_or_create> for details.

=head2 set_from_related

=over 4

=item Arguments: $rel_name, L<$result|DBIO::Manual::ResultClass>

=item Return Value: not defined

=back

  $book->set_from_related('author', $author_obj);
  $book->author($author_obj);                      ## same thing

Set column values on the current object, using related values from the given
related object. This is used to associate previously separate objects, for
example, to set the correct author for a book, find the Author object, then
call set_from_related on the book.

This is called internally when you pass existing objects as values to
L<DBIO::ResultSet/create>, or pass an object to a belongs_to accessor.

The columns are only set in the local copy of the object, call
L<update|DBIO::Row/update> to update them in the storage.

=head2 update_from_related

=over 4

=item Arguments: $rel_name, L<$result|DBIO::Manual::ResultClass>

=item Return Value: not defined

=back

  $book->update_from_related('author', $author_obj);

The same as L</"set_from_related">, but the changes are immediately updated
in storage.

=head2 delete_related

=over 4

=item Arguments: $rel_name, $cond?, L<\%attrs?|DBIO::ResultSet/ATTRIBUTES>

=item Return Value: $underlying_storage_rv

=back

Delete any related row, subject to the given conditions.  Internally, this
calls:

  $self->search_related(@_)->delete

And returns the result of that.

=head2 add_to_$rel

B<Currently only available for C<has_many>, C<many_to_many> and 'multi' type
relationships.>

=head3 has_many / multi

=over 4

=item Arguments: \%col_data

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Creates/inserts a new result object.  Internally, this calls:

  $self->create_related($rel, @_)

And returns the result of that.

=head3 many_to_many

=over 4

=item Arguments: (\%col_data | L<$result|DBIO::Manual::ResultClass>), \%link_col_data?

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

  my $role = $schema->resultset('Role')->find(1);
  $actor->add_to_roles($role);
      # creates a My::DBIO::Schema::ActorRoles linking table result object

  $actor->add_to_roles({ name => 'lead' }, { salary => 15_000_000 });
      # creates a new My::DBIO::Schema::Role result object and the linking table
      # object with an extra column in the link

Adds a linking table object. If the first argument is a hash reference, the
related object is created first with the column values in the hash. If an object
reference is given, just the linking table object is created. In either case,
any additional column values for the linking table object can be specified in
C<\%link_col_data>.

See L<DBIO::Relationship/many_to_many> for additional details.

=head2 set_$rel

B<Currently only available for C<many_to_many> relationships.>

=over 4

=item Arguments: (\@hashrefs_of_col_data | L<\@result_objs|DBIO::Manual::ResultClass>), $link_vals?

=item Return Value: not defined

=back

  my $actor = $schema->resultset('Actor')->find(1);
  my @roles = $schema->resultset('Role')->search({ role =>
     { '-in' => ['Fred', 'Barney'] } } );

  $actor->set_roles(\@roles);
     # Replaces all of $actor's previous roles with the two named

  $actor->set_roles(\@roles, { salary => 15_000_000 });
     # Sets a column in the link table for all roles

Replace all the related objects with the given reference to a list of
objects. This does a C<delete> B<on the link table resultset> to remove the
association between the current object and all related objects, then calls
C<add_to_$rel> repeatedly to link all the new objects.

Note that this means that this method will B<not> delete any objects in the
table on the right side of the relation, merely that it will delete the link
between them.

Due to a mistake in the original implementation of this method, it will also
accept a list of objects or hash references. This is B<deprecated> and will be
removed in a future version.

=head2 remove_from_$rel

B<Currently only available for C<many_to_many> relationships.>

=over 4

=item Arguments: L<$result|DBIO::Manual::ResultClass>

=item Return Value: not defined

=back

  my $role = $schema->resultset('Role')->find(1);
  $actor->remove_from_roles($role);
      # removes $role's My::DBIO::Schema::ActorRoles linking table result object

Removes the link between the current object and the related object. Note that
the related object itself won't be deleted unless you call ->delete() on
it. This method just removes the link between the two objects.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
