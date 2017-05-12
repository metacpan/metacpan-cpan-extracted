package DBIx::EAV::ResultSet;

use Moo;
use DBIx::EAV::Entity;
use DBIx::EAV::Cursor;
use Data::Dumper;
use Carp qw/ croak confess /;
use overload
    '0+'   => "_to_num",
    'bool' => "_to_bool",
    fallback => 1;

my $sql = SQL::Abstract->new;

has 'eav',      is => 'ro', required => 1;
has 'type',     is => 'ro', required => 1;
has '_query',   is => 'rw', default => sub { [] }, init_arg => 'query';
has '_options', is => 'rw', default => sub { {} }, init_arg => 'options';
has 'cursor',   is => 'rw',
                lazy      => 1,
                init_arg  => undef,
                predicate => '_has_cursor',
                clearer   => '_clear_cursor',
                builder   => '_build_cursor';

has 'entity_class', is => 'ro', init_arg => undef, lazy => 1, default => sub {
    my $self = shift;
    $self->eav->_resolve_entity_class($self->type->name) || 'DBIx::EAV::Entity';
};

sub _to_num { $_[0]->count }

sub _to_bool { 1 }


sub _build_cursor {
    my $self = shift;

    DBIx::EAV::Cursor->new(
        eav     => $self->eav,
        type    => $self->type,
        query   => $self->_query,
        options => $self->_options,
    );
}


sub new_entity {
    my ($self, $data) = @_;
    my $entity = $self->entity_class->new( eav => $self->eav, type => $self->type );
    $entity->set($data) if ref $data eq 'HASH';
    $entity;
}


sub inflate_entity {
    my ($self, $data) = @_;
    my $type = $self->type;
    $type = $self->eav->type_by_id($data->{entity_type_id})
        if $data->{entity_type_id} && $data->{entity_type_id} != $type->id;

    my $entity = $self->entity_class->new( eav => $self->eav, type => $type, raw => $data );
    $entity->load_attributes;
    $entity;
}


{
    no warnings;
    *create = \&insert;
}

sub insert {
    my ($self, $data) = @_;
    $self->new_entity($data)->save;
}


sub populate {
    my ($self, $data) = @_;
    die 'Call populate(\@items)' unless ref $data eq 'ARRAY';

    my @result;
    foreach my $item (@$data) {
        push @result, $self->insert($item);
    }

    return wantarray ? @result : \@result;
}


sub update {
    my ($self, $data, $where) = @_;

    $where //= {};
    $where->{entity_type_id} = $self->type->id;

    # do a direct update for static attributes

}


sub delete {
    my $self = shift;
    my $eav = $self->eav;
    my $type = $self->type;
    my $entities_table = $eav->table('entities');

    # Call delete_all for SQLite since it doesn't
    # support delete with joins.
    # Better solution welcome.
    return $self->delete_all if
        $self->eav->schema->db_driver_name eq 'SQLite';

    unless ($eav->schema->database_cascade_delete) {

        # delete links by relationship id
        my @ids = map { $_->{id} } $type->relationships;

        $eav->table('entity_relationships')->delete(
            {
                relationship_id => \@ids,
                $entities_table->name.'.entity_type_id' => $type->id
            },
            { join => { $entities_table->name =>  [{ 'me.left_entity_id' => 'their.id' }, { 'me.right_entity_id' => 'their.id' }] } }
        );

        # delete attributes:
        # - group attrs by data type so only one DELETE command is sent per data type
        # - restrict by entity_type_id so we dont delete parent/sibiling/child data
        my %types;
        push @{ $types{$_->{data_type}} }, $_->{id}
            for $type->attributes(no_static => 1);

        while (my ($data_type, $ids) = each %types) {

            my $value_table = $eav->table('value_'.$data_type);
            $value_table->delete(
                {
                    attribute_id => $ids,
                    $entities_table->name.'.entity_type_id' => $type->id
                },
                { join => { $entities_table->name => { 'me.entity_id' => 'their.id' } } }
            );
        }
    }

    $entities_table->delete({ entity_type_id => $type->id });
}


sub delete_all {
    my $self = shift;

    my $rs = scalar @_ > 0 ? $self->search_rs(@_) : $self;
    my $i = 0;

    while (my $entity = $rs->next) {
        $entity->delete;
        $i++;
    }

    $i;
}


sub find {
    my ($self, $criteria, $options) = @_;

    croak "Missing find() criteria."
        unless defined $criteria;

    # simple id search
    return $self->search_rs({ id => $criteria }, $options)->next
        unless ref $criteria;

    my $rs = $self->search_rs($criteria, $options);
    my $result = $rs->next;

    # criteria is a search query, die if this query returns multiple items
    croak "find() returned more than one entity. If this is what you want, use search or search_rs."
        if defined $result && defined $rs->cursor->next;

    $result;
}


sub search {
    my ($self, $query, $options) = @_;

    my $rs = $self->search_rs($query, $options);

    return wantarray ? $rs->all : $rs;
}

sub search_rs {
    my ($self, $query, $options) = @_;

    # simple combine queries using AND
    my @new_query = @{ $self->_query };
    push @new_query, $query if $query;

    # merge options
    my $merged_options = $self->_merge_options($options);

    (ref $self)->new(
        eav      => $self->eav,
        type     => $self->type,
        query    => \@new_query,
        options  => $merged_options
    );
}


sub _merge_options {
    my ($self, $options) = @_;

    my %merged = %{ $self->_options };

    return \%merged
        unless defined $options;

    confess "WTF" if $options eq '';

    foreach my $opt (keys %$options) {

        # doesnt even exist, just copy
        if (not exists $merged{$opt}) {
            $merged{$opt} = $options->{$opt};
        }

        # having: combine queries using AND
        elsif ($opt eq 'having') {

            $merged{$opt} = [$merged{$opt}, $options->{$opt}];
        }

        # merge array
        elsif (ref $merged{$opt} eq 'ARRAY') {

            $merged{$opt} = [
                @{$merged{$opt}},
                ref $options->{$opt} eq 'ARRAY' ? @{$options->{$opt}} : $options->{$opt}
            ];
        }

        else {
            $merged{$opt} = $options->{$opt};
        }
    }

    \%merged;
}


sub count {
    my $self = shift;
    return $self->search(@_)->count if @_;

    # from DBIx::Class::ResultSet::count()
    # this is a little optimization - it is faster to do the limit
    # adjustments in software, instead of a subquery
    my $options = $self->_options;
    my ($limit, $offset) = @$options{qw/ limit offset /};

    my $count = $self->_count_rs($options)->cursor->next->{count};

    $count -= $offset if $offset;
    $count = 0 if $count < 0;
    $count = $limit if $limit && $count > $limit;

    $count;
}


sub _count_rs {
    my ($self, $options) = @_;
    my %tmp_options = ( %$options, select => [\'COUNT(*) AS count'] );

    # count using subselect if needed
    $tmp_options{from} = $self->as_query
        if $options->{group_by} || $options->{distinct};

    delete @tmp_options{qw/ limit offset order_by group_by distinct /};

    (ref $self)->new(
        eav      => $self->eav,
        type     => $self->type,
        query    => [@{ $self->_query }],
        options  => \%tmp_options
    );
}


sub as_query {
    my $self = shift;
    $self->cursor->as_query;
}


sub reset {
    my $self = shift;
    $self->_clear_cursor;
    $self;
}

sub first {
    $_[0]->reset->next;
}

sub next {
    my $self = shift;

    # fetch next
    my $entity_row = $self->cursor->next;
    return unless defined $entity_row;

    # instantiate entity
    $self->inflate_entity($entity_row);
}

sub all {
    my $self = shift;
    my @entities;

    $self->reset;

    while (my $entity = $self->next) {
        push @entities, $entity;
    }

    $self->reset;

    return wantarray ? @entities : \@entities;
}

sub pager {
    die "pager() not implemented";
}

sub distinct {
    die "distinct() not implemented";
}

sub storage_size {
    die "storage_size() not implemented";
}


1;

__END__


=encoding utf-8

=head1 NAME

DBIx::EAV::ResultSet - Represents a query used for fetching a set of entities.

=head1 SYNOPSIS

    # resultsets are bound to an entity type
    my $cds_rs = $eav->resultset('CD');


    # insert CDs
    my $cd1 = $cds_rs->insert({ title => 'CD1', tracks => \@tracks });
    my $cd2 = $cds_rs->insert({ title => 'CD2', tracks => \@tracks });
    my $cd3 = $cds_rs->insert({ title => 'CD3', tracks => \@tracks });

    # ... or use populate() to insert many
    my (@cds) = $cds_rs->populate(\@cds);


    # find all 2015 cds
    my @cds = $eav->resultset('CD')->search({ year => 2015 });

    foreach my $cd (@cds) {

        printf "CD '%s' has %d tracks.\n",
            $cd->get('title'),
            $cd->get('tracks')->count;
    }

    # find one
    my $cd2 = $cds_rs->search_one({ name => 'CD2' });

    # find by related attribute
    my $cd2 = $cds_rs->search_one({ 'tracks.title' => 'Some CD2 Track' });

    # count
    my $top_cds_count = $cds_rs->search({ rating => { '>' => 7 } })->count;


    # update

    # delete all entities
    $cds_rs->delete;      # fast, but doesn't deletes related entities

    $cds_rs->delete_all;  # cascade delete all cds and related entities


=head1 DESCRIPTION

A ResultSet is an object which stores a set of conditions representing
a query. It is the backbone of DBIx::EAV (i.e. the really
important/useful bit).

No SQL is executed on the database when a ResultSet is created, it
just stores all the conditions needed to create the query.

A basic ResultSet representing the data of an entire table is returned
by calling C<resultset> on a L<DBIx::EAV> and passing in a
L<type|DBIx::EntityType> name.

  my $users_rs = $eav->resultset('User');

A new ResultSet is returned from calling L</search> on an existing
ResultSet. The new one will contain all the conditions of the
original, plus any new conditions added in the C<search> call.

A ResultSet also incorporates an implicit iterator. L</next> and L</reset>
can be used to walk through all the L<entities|DBIx::EAV::Entity> the ResultSet
represents.

The query that the ResultSet represents is B<only> executed against
the database when these methods are called:
L</find>, L</next>, L</all>, L</first>, L</count>.

If a resultset is used in a numeric context it returns the L</count>.
However, if it is used in a boolean context it is B<always> true.  So if
you want to check if a resultset has any results, you must use C<if $rs
!= 0>.

=head1 METHODS

=head2 new_entity

=over 4

=item Arguments: \%entity_data

=item Return Value: L<$entity|DBIx::EAV::EntityType>

=back

Creates a new entity object of the resultset's L<type|DBIx::EAV::EntityType> and
returns it. The row is not inserted into the database at this point, call
L<DBIx::EAV::Entity/save> to do that. Calling L<DBIx::EAV::Entity/in_storage>
will tell you whether the entity object has been inserted or not.

    # create a new entity, do some modifications...
    my $cd = $eav->resultset('CD')->new_entity({ title  => 'CD1' });
    $cd->set('year', 2016);

    # now insert it
    $cd->save;

=head2 insert

=over 4

=item Arguments: \%entity_data

=item Return Value: L<$entity|DBIx:EAV::Entity>

=back

Attempt to create a single new entity or a entity with multiple related entities
in the L<type|DBIx::EAV::EntityType> represented by the resultset (and related
types). This will not check for duplicate entities before inserting, use
L</find_or_create> to do that.

To create one entity for this resultset, pass a hashref of key/value
pairs representing the attributes of the L</type> and the values you wish to
store. If the appropriate relationships are set up, you can also pass related
data.

To create related entities, pass a hashref of related-object attribute values
B<keyed on the relationship name>. If the relationship is of type C<has_many>
or C<many_to_many> - pass an arrayref of hashrefs.
The process will correctly identify the relationship type and side, and will
transparently populate the L<entitiy_relationships table>.
This can be applied recursively, and will work correctly for a structure
with an arbitrary depth and width, as long as the relationships actually
exists and the correct data has been supplied.

Instead of hashrefs of plain related data (key/value pairs), you may
also pass new or inserted objects. New objects (not inserted yet, see
L</new_entity>), will be inserted into their appropriate types.

Effectively a shortcut for C<< ->new_entity(\%entity_data)->save >>.

Example of creating a new entity.

    my $cd1 = $cds_rs->insert({
        title  => 'CD1',
        year   => 2016
    });

Example of creating a new entity and also creating entities in a related
C<has_many> resultset.  Note Arrayref for C<tracks>.

    my $cd1 = $eav->resultset('CD')->insert({
        title  => 'CD1',
        year   => 2016
        tracks => [
            { title => 'Track1', duration => ... },
            { title => 'Track2', duration => ... },
            { title => 'Track3', duration => ... }
        ]
    });

Example of passing existing objects as related data.

    my @tags = $eav->resultset('Tag')->search(\%where);

    my $article = $eav->resultset('Article')->insert({
        title   => 'Some Article',
        content => '...',
        tags    => \@tags
    });


=over

=item WARNING

When subclassing ResultSet never attempt to override this method. Since
it is a simple shortcut for C<< $self->new_entity($data)->save >>, a
lot of the internals simply never call it, so your override will be
bypassed more often than not. Override either L<DBIx::EAV::Entity/new>
or L<DBIx::EAV::Entity/save> depending on how early in the
L</insert> process you need to intervene.

=back

=head2 populate

=over 4

=item Arguments: \@entites

=item Return Value: L<@inserted_entities|DBIx:EAV::Entity>

=back

Shortcut for inserting multiple entities at once. Returns a list of inserted
entities.

    my @cds = $eav->resultset('CD')->populate([
        { title => 'CD1', ... },
        { title => 'CD2', ... },
        { title => 'CD3', ... }
    ]);


=head2 count

=over 4

=item Arguments: \%where, \%options

=item Return Value: $count

=back

Performs an SQL C<COUNT> with the same query as the resultset was built
with to find the number of elements. Passing arguments is equivalent to
C<< $rs->search($cond, \%attrs)->count >>

=head2 delete

=over 4

=item Arguments: \%where

=item Return Value: $underlying_storage_rv

=back

Deletes the entities matching \%where condition without fetching them first.
This will run faster, at the cost of related entities not being casdade deleted.
Call L</delete_all> if you want to cascade delete related entities.

When L<DBIx::EAV/database_cascade_delete> is enabled, the delete operation is
done in a single query. Otherwise one more query is needed for each of the
L<values table|DBIx::EAV::Schema> and another for the
L<relationship link table|DBIx::EAV::Schema>.

=over

=item WARNING

This method requires database support for C<DELETE ... JOIN>. Since the current
implementation of DBIx::EAV is only tested against MySQL and SQLite, this method
calls L</delete_all> if SQLite database is detected.

=back

=head2 delete_all

=over 4

=item Arguments: \%where, \%options

=item Return Value: $num_deleted

=back

Fetches all objects and deletes them one at a time via
L<DBIx::EAV::Entity/delete>. Note that C<delete_all> will cascade delete related
entities, while L</delete> will not.

=head1 QUERY OPTIONS

=head2 limit

=over 4

=item Value: $rows

=back

Specifies the maximum number of rows for direct retrieval or the number of
rows per page if the page option or method is used.

=head2 offset

=over 4

=item Value: $offset

=back

Specifies the (zero-based) row number for the  first row to be returned, or the
of the first row of the first page if paging is used.

=head2 page

NOT IMPLEMENTED.

=head2 group_by

=over 4

=item Value: \@columns

=back

A arrayref of columns to group by. Can include columns of joined tables.

  group_by => [qw/ column1 column2 ... /]

=head2 having

=over 4

=item Value: \%condition

=back

The HAVING operator specifies a B<secondary> condition applied to the set
after the grouping calculations have been done. In other words it is a
constraint just like L</QUERY> (and accepting the same
L<SQL::Abstract syntax|SQL::Abstract/WHERE CLAUSES>) applied to the data
as it exists after GROUP BY has taken place. Specifying L</having> without
L</group_by> is a logical mistake, and a fatal error on most RDBMS engines.
Valid fields for criteria are all known attributes, relationships and related
attributes for the type this cursor is bound to.

E.g.

    $eav->resultset('CD')->search(undef, {
        '+select' => { count => 'tracks' },              # alias 'count_tracks' created automatically
        group_by  => ['me.id'],
        having    => { count_tracks => { '>' => 5 } }
    });

Althought literal SQL is supported, you must know the actual alias and column names
used in the generated SQL statement.

  having => \[ 'count(cds_link.) >= ?', 100 ]

Set the debug flag to get the SQL statements printed to stderr.

=head2 distinct

=over 4

=item Value: (0 | 1)

=back

Set to 1 to automatically generate a L</group_by> clause based on the selection
(including intelligent handling of L</order_by> contents). Note that the group
criteria calculation takes place over the B<final> selection. This includes
any L</+columns>, L</+select> or L</order_by> additions in subsequent
L</search> calls, and standalone columns selected via
L<DBIx::Class::ResultSetColumn> (L</get_column>). A notable exception are the
extra selections specified via L</prefetch> - such selections are explicitly
excluded from group criteria calculations.

If the cursor also explicitly has a L</group_by> attribute, this
setting is ignored and an appropriate warning is issued.

=head2 subtype_depth

=over 4

=item Value: $depth

Specifies how deep in the type hierarchy you want the query to go. By default
its 0, and the query is restricted to the type this cursor is bound to. Even though
you can use this option to find entities of subtypes, you cannot use the subtypes own
attributes in the query. So if you need to do a subtype query, ensure all attributes
needed for the query are defined on the parent type.

    # Example entity types:
    # Product       [attrs: name, price, description]
    # HardDrive     [extends: Product] [attrs: rpm, capacity]
    # Monitor       [extends: Product] [attrs: resolution, contrast_ratio]
    # FancyMonitor  [extends: Monitor] [attrs: fancy_feature]

    # this query won't find any HardDrive or Monitor, only Product entities
    $eav->resultset('Product')->search({ price => { '<' => 500 } });

    # this also finds HardDrive and Monitor entities
    $eav->resultset('Product')->search(
        { price => { '<' => 500 } },       # subtype's attributes are not allowed
        { subtype_depth => 1 }
    );

    # this query also finds FancyMonitor
    $eav->resultset('Product')->search(
        \%where,
        { subtype_depth => 2 }
    );

=back

=head2 prefetch

NOT IMPLEMENTED.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
