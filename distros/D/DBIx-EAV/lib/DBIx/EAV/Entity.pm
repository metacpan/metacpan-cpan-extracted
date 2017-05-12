package DBIx::EAV::Entity;

use Moo;
use strictures 2;
use Scalar::Util qw/ blessed /;
use Data::Dumper;
use Carp 'croak';

has 'eav', is => 'ro', required => 1;
has 'type', is => 'ro', required => 1, handles => [qw/ is_type /];
has 'raw', is => 'ro', default => sub { {} };
has '_modified', is => 'ro', default => sub { {} };
has '_modified_related', is => 'ro', default => sub { {} };



sub in_storage {
    my $self = shift;
    exists $self->raw->{id} && defined $self->raw->{id};
}

sub id {
    my $self = shift;
    return unless exists $self->raw->{id};
    $self->raw->{id};
}



sub get {
    my $self = shift;
    my $name = shift;
    my $type = $self->type;

    return $self->raw->{$name}
        if $type->has_attribute($name);

    if ($type->has_relationship($name)) {
        my $rel = $type->relationship($name);
        my $rs = $self->_get_related($name, @_);
        # return an Entity for has_one and belongs_to; return Cursor otherwise
        return $rs->next if
            $rel->{is_has_one} || ($rel->{is_has_many} && $rel->{is_right_entity});

        # *_many rel, return cursor or array of entities
        return wantarray ? $rs->all : $rs;
    }

    die sprintf "get() error: '%s' is not a valid attribute/relationship for '%s'", $name, $self->type->name;
}

sub _get_related {
    my ($self, $relname, $query, $options) = @_;
    $query //= {};
    my $rel = $self->type->relationship($relname);
    $query->{$rel->{incoming_name}} = $self;
    $self->eav->resultset($rel->{entity})->search($query, $options);
}


sub load_attributes {
    my ($self, @attrs) = @_;

    die "Can't load_attributes(): this entity has no id!"
        unless defined $self->id;

    my $eav = $self->eav;
    my $type = $self->type;

    @attrs = $type->attributes( no_static => 1, names => 1 )
        if @attrs == 0;

    # build sql query: one aliases subselect for each attribute
    my $sql_query = 'SELECT ' . join(', ', map {

        my $attr_spec = $type->attribute($_);
        my $value_table = $eav->table('value_'. $attr_spec->{data_type} );
        sprintf "(SELECT value FROM %s WHERE entity_id = %d AND attribute_id = %d) AS %s",
            $value_table->name,
            $self->id,
            $attr_spec->{id},
            $_;

    } @attrs);

    # fetch data
    my ($rv, $sth) = $eav->dbh_do($sql_query);
    my $data = $sth->fetchrow_hashref;

    die "load_attributes() failed! No data returned from database!"
        unless ref $data eq 'HASH';

    my $raw = $self->raw;
    my $total = 0;

    # adopt data
    for (keys %$data) {
        $raw->{$_} = $data->{$_};
        $total++;
    }

    # return the number os attrs loaded
    $total;
}

sub update {
    my $self = shift;
    $self->set(@_)->save;
}

sub set {
    my $self = shift;
    my $numargs = scalar(@_);

    die 'Call set(\%data) or set($attr, $value)'
        if 1 > $numargs || $numargs > 2;

    if ($numargs == 2) {
        $self->_set(@_);
    }
    elsif ($numargs == 1) {
        die "You must pass a hashref set()" unless ref $_[0] eq 'HASH';
        while (my ($k, $v) = each %{$_[0]}) {
            $self->_set($k, $v);
        }
    }

    $self;
}

sub _set {
    my ($self, $attr_name, $value) = @_;
    my $type = $self->type;

    if ($type->has_relationship($attr_name)) {
        return $self->_set_related($attr_name, $value);
    }

    my $attr = $self->type->attribute($attr_name);

    die "Sorry, you can't set the 'id' attribute."
        if $attr_name eq 'id';

    # same value
    return if defined $value &&
              exists $self->raw->{$attr_name} &&
              defined $self->raw->{$attr_name} &&
              $value eq $self->raw->{$attr_name};

    # remember original value
    $self->_modified->{$attr_name} = $self->raw->{$attr_name}
        unless exists $self->_modified->{$attr_name};


    # set
    # TODO use type-specific deflator
    $self->raw->{$attr_name} = $value;
}

sub _set_related {
    my ($self, $relname, $data) = @_;
    my $type = $self->type;
    my $rel = $type->relationship($relname);

    die "You can only pass related data in the form of a hashref, blessed Entity object, or an arrayref of it."
        unless ref $data eq 'HASH' || ref $data eq 'ARRAY' || (blessed $data && $data->isa('DBIx::EAV::Entity'));

    die "You can't pass an arrayref for the '$rel->{name}' relationship."
        if ref $data eq 'ARRAY' && ( $rel->{is_has_one} || ($rel->{is_has_many} && $rel->{is_right_entity}) );

    $self->raw->{$relname} = $data;
    $self->_modified_related->{$relname} = 1;
}


sub save {
    my $self = shift;
    my $type = $self->type;
    my $entities_table = $self->eav->table('entities');
    my $is_new_entity = not $self->in_storage;
    my $raw = $self->raw;

    # modified static attrs
    my %modified_static_attributes = map { $_ => $self->raw->{$_} }
                                     grep { $type->has_static_attribute($_) }
                                     keys %{$self->_modified};

    # insert if its new entity
    if ($is_new_entity) {

        # TODO insert default values

        my $id = $entities_table->insert({
            %modified_static_attributes,
            entity_type_id => $type->id,
        });

        die "Invalid ID returned ($id) while inserting new entity."
            unless $id > 0;

        my $static_attributes = $entities_table->select_one({ id => $id });

        die "Error: could not fetch the entity row I've just inserted!"
            unless $static_attributes->{id} == $id;

        $raw->{$_} = $static_attributes->{$_}
            for keys %$static_attributes;

        # undirty those attrs
        delete $self->_modified->{$_} for keys %modified_static_attributes;
        %modified_static_attributes = ();
    }

    # upsert attributes
    my $modified_count = 0;

    while (my ($attr_name, $old_value) = each %{$self->_modified}) {

        $modified_count++;
        my $value = $raw->{$attr_name};
        my $attr_spec = $self->type->attribute($attr_name);

        # save static attrs later
        if ($attr_spec->{is_static}) {
            $modified_static_attributes{$attr_name} = $value;
            next;
        }

        my $values_table = $self->eav->table('value_'.$attr_spec->{data_type});

        my %attr_criteria = (
            entity_id    => $self->id,
            attribute_id => $attr_spec->{id}
        );

        # undefined value, delete attribute row
        if (not defined $value) {
            $values_table->delete(\%attr_criteria);
        }

        # update or insert value
        elsif (defined $old_value) {
            $values_table->update({ value => $value }, \%attr_criteria);
        }
        else {
            $values_table->insert({
                %attr_criteria,
                value => $value
            });
        }
    }

    # upset related
    foreach my $relname (keys %{$self->_modified_related}) {
        $self->_save_related($relname, $self->raw->{$relname});
    }


    # update static attributes
    if ($modified_count > 0) {

        $entities_table->update(\%modified_static_attributes, { id => $self->id })
            if keys(%modified_static_attributes) > 0;
    }

    # undirty
    %{$self->_modified} = ();

    $self;
}

sub _save_related {
    my ($self, $relname, $data, $options) = @_;
    $options //= {};

    my $rel = $self->type->relationship($relname);
    my $related_type = $self->eav->type($rel->{entity});
    my ($our_side, $their_side) = $rel->{is_right_entity} ? qw/ right left / : qw/ left right /;

    # delete any old links
    my $relationship_table = $self->eav->table('entity_relationships');
    $relationship_table->delete({
        relationship_id => $rel->{id},
        $our_side."_entity_id" => $self->id
    }) unless $options->{keep_current_links};

    # link new objects
    foreach my $entity (ref $data eq 'ARRAY' ? @$data : ($data)) {

        # if is a blessed object, check its a entity from the correct type
        if (blessed $entity) {

            die "Can't save data for relationship '$relname': unknown data type: ". ref $entity
                unless $entity->isa('DBIx::EAV::Entity');

            die sprintf("relationship '%s' requires '%s' objects, not '%s'", $relname, $related_type->name, $entity->type->name)
                unless $entity->type->id == $related_type->id;

            die "Can't save data for relationship '$relname': related entity is not in_storage."
                unless $entity->in_storage;

            # remove any links to it
            $relationship_table->delete({
                relationship_id => $rel->{id},
                $their_side."_entity_id" => $entity->id

            }) unless $rel->{is_many_to_many};

        }
        elsif (ref $entity eq 'HASH') {

            # insert new entity
            $entity = $self->eav->resultset($related_type->name)->insert($entity);
        }
        else {
            die "Can't save data for relationship '$relname': unknown data type: ". ref $entity;
        }

        # create link
        $relationship_table->insert({
            relationship_id => $rel->{id},
            $our_side."_entity_id"  => $self->id,
            $their_side."_entity_id" => $entity->id
        }) or die "Error creating link for relationship '$relname'";
    }
}

sub add_related {
    my ($self, $relname, $data) = @_;
    my $rel = $self->type->relationship($relname);
    die "Can't call add_related() for relationship '$rel->{name}'"
        if $rel->{is_has_one} || ($rel->{is_has_many} && $rel->{is_right_entity});

    $self->_save_related($relname, $data, { keep_current_links => 1 });
}


sub remove_related {
    my ($self, $relname, $data) = @_;
    my $rel = $self->type->relationship($relname);

    die "Can't call add_related() for relationship '$rel->{name}'"
        if $rel->{is_has_one} || ($rel->{is_has_many} && $rel->{is_right_entity});

    my $relationships_table = $self->eav->table('entity_relationships');
    my ($our_side, $their_side) = $rel->{is_right_entity} ? qw/ right left / : qw/ left right /;

    $data = [$data] unless ref $data eq 'ARRAY';

    foreach my $entity (@$data) {

        die "remove_related() error: give me an instance of '$rel->{entity}' or an arrayref of it."
            unless blessed $entity && $entity->isa('DBIx::EAV::Entity') && $entity->type->name eq $rel->{entity};

        $relationships_table->delete({
            relationship_id          => $rel->{id},
            $our_side  ."_entity_id" => $self->id,
            $their_side."_entity_id" => $entity->id
        });
    }
}


sub discard_changes {
    my $self = shift;

    while (my ($k, $v) = each %{$self->_modified}) {
        $self->raw->{$k} = $v;
        delete $self->raw->{$k};
    }

    $self;
}


sub delete {
    my $self = shift;
    die "Can't delete coz I'm not in storage!"
        unless $self->in_storage;

    my $eav  = $self->eav;
    my $type = $self->type;

    # cascade delete child entities
    foreach my $rel ($type->relationships) {

        next if $rel->{is_right_entity}
                || $rel->{is_many_to_many}
                || (exists $rel->{cascade_delete} && $rel->{cascade_delete} == 0);

        my $rs = $self->_get_related($rel->{name});
        while (my $related_entity = $rs->next) {
            $related_entity->delete;
        }
    }

    unless ($eav->schema->database_cascade_delete) {

        # delete relationship links
        $eav->table('entity_relationships')->delete([
            { left_entity_id  => $self->id },
            { right_entity_id => $self->id }
        ]);

        # delete attributes
        my %data_types = map { $_->{data_type} => 1 }
        $type->attributes( no_static => 1 );

        foreach my $data_type (keys %data_types) {
            $eav->table('value_'.$data_type)->delete({ entity_id => $self->id });
        }
    }

    # delete entity
    my $entities_table = $self->eav->table('entities');
    my $rv = $entities_table->delete({ id => $self->id });
    delete $self->raw->{id}; # not in_storage
    $rv;
}


##               ##
## Class Methods ##
##               ##

sub is_custom_class {
    my $class = shift;
    croak "is_custom_class() is a Class method." if ref $class;
    $class ne __PACKAGE__;
}

sub type_definition {
    my $class = shift;

    croak "type_definition() is a Class method." if ref $class;
    croak "type_definition() must be called on DBIx::EAV::Entity subclasses."
        unless $class->is_custom_class;

    no strict 'refs';
    unless (defined *{"${class}::__TYPE_DEFINITION__"}) {

        my %definition;
        # detect parent entity
        my $parent_class = ${"${class}::ISA"}[0];
        ($definition{extends}) = $parent_class =~ /::(\w+)$/
            if $parent_class ne __PACKAGE__;

        *{"${class}::__TYPE_DEFINITION__"} = \%definition;
    }


    \%{"${class}::__TYPE_DEFINITION__"};
}

# install class methods for type definition
foreach my $stuff (qw/ attribute has_many has_one many_to_many /) {
    no strict 'refs';
    *{$stuff} = sub {
        my ($class, $spec) = @_;

        croak "$stuff() is a Class method." if ref $class;
        croak "$stuff() must be called on DBIx::EAV::Entity subclasses."
            unless $class->is_custom_class;

        my $key = $stuff eq 'attribute' ? 'attributes' : $stuff;
        push @{ $class->type_definition->{$key} }, $spec;
    };
}



1;


__END__


=head1 NAME

DBIx::EAV::Entity - Represents an entity record.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class can be used by itself or as base class for your entity objects.

=head1 CUSTOM CLASS

DBIx::EAV lets you define your entities via custom classes, which are subclasses
of DBIx::EAV::Entity. Unlike DBIx::Class, the custom classes are not loaded
upfront. They are lazy loaded whenever a call to L<DBIx::EAV/type> is made.
Directly or indirectly (i.e. via other DBIx::EAV methods like L<"resultset()"|DBIx::EAV/resultset>).

Custom classes are used not only define the entity attributes and relationships,
but also to add define you application's business logic, via custom entity methods.

Okay, an example. Lets mimic the namespaces used by DBIx::Class:

    my $eav = DBIx::EAV->connect($dsn, $user, $pass, $attrs, {
        entity_namespaces    => 'MyApp::Schema::Result',
        resultset_namespaces => 'MyApp::Schema::ResultSet',
    });

Now lets create a 'User' entity class.

    package MyApp::Schema::Result::User;
    use Moo;
    BEGIN { extends 'DBIx::EAV::Entity' }

    __PACKAGE__->attribute('first_name');
    __PACKAGE__->attribute('last_name');
    __PACKAGE__->attribute('email');
    __PACKAGE__->attribute('birth_date:datetime');
    __PACKAGE__->attribute('is_verified:boolean:0');

    # can also define relationships
    #__PACKAGE__->has_one( ... );
    #__PACKAGE__->has_many( ... );
    #__PACKAGE__->many_to_many( ... );

    # custom methods
    sub full_name {
        my $self = shift;
        return join ' ', $self->get('first_name'), $self->get('last_name');
    }

    1;


Done. You have just defined the C<User> entity type, and also a custom class for
instances of the this type.

    my $user = $eav->resultset('User')->create({
        first_name => 'Carlos',
        last_name  => 'Gratz'
    });

    print $user->full_name; # Carlos Gratz

    # obviously, all other DBIx::EAV::Entity are also available :]

As you could have noted in the first code snippet, its also possible to create
custom resultset classes.

    package MyApp::Schema::ResultSet::User;

    use Moo;
    extends 'DBIx::EAV::ResultSet';

    sub verified_only {
        my $self = shift;
        $self->search({ is_verified => 1 });
    }


    1;

Now a call to C<< $eav->resultset('User') >> returns an instance of
C<MyApp::Schema::ResultSet::User>.

    my $users_rs = $eav->resultset('User');

    $users_rs->isa('MyApp::Schema::ResultSet::User'); # 1

    my $verified_user = $users_rs->verified_only
                                  ->find({ email => 'user@example.com'});



=head1 CUSTOM CLASS INHERITANCE

DBIx::EAV supports entity type inheritance. When working with custom classes all
you need to do is set you custom base class by normal perl means. DBIx::EAV
will inspect your class C<@ISA> and get the parent entity name.


    package MyApp::DB::Result::UserSubclass;
    BEGIN { extends 'MyApp::DB::Result::User' }

    # define attributes, relationships and methods for 'UserSubclass'

    1;

For more information on how entity type inheritance works in DBIx::EAV, read
L<DBIx::EAV::Manual::Inheritance>.

=head1 METHODS

=head2 in_storage

Returns true if a database id is present.

    sub in_storage {
        my $self = shift;
        exists $self->raw->{id} && defined $self->raw->{id};
    }

=head2 id

Returns the entity database id or C<undef> if entity is not in storage.

    # new_entity() doesn't call save(). $cd1 has no id in this case
    my $cd1 = $eav->resultset('CD')->new_entity({ title => 'CD1' });

    $cd1->id;       # undef
    $cd1->save;
    $cd1->id;       # <database id>
    $cd1->delete;
    $cd1->id;       # undef


=head2 get

=over 4

=item Arguments: $attr_name | $relationship_name

=item Return Value: $attr_value | $related_cursor | @related_entities

=back

Returns a attribute value or related entities.

=head2 set

=over 4

=item Arguments: $name, $value \%values

=item Arguments: \%values

=item Return Value: L<$self|DBIx::EAV::Entity>

=back

Set a new value for the attribute or relationship C<$name>. Returns C<$self> to
allow method chaining. Even though subsequent calls to L</get> will return the
new value you have just L</set>, changes are not saved in the database until you
call L</save>. Use L</update> if you wan't to set and save in one call.

    $cd->set('title' => 'New title');
    $cd->get('title');  # New title
    $cd->save; # or $cd->discard_changes

    # set multiple values
    $cd->set({
        title => 'New Title',
        year  => 2016
    });

When setting the value for a relationship, this method replaces the existing
set of related entities by the new one (relationship bindings are deleted,
not the related entities themselves). Valid values for relationships are
existing L<entities|DBIx::EAV::Entity> or hashref suitable for inserting the
related entity, or a arrayref of those (for *_many relationships). Passing an
entity instance which is not of the correct type for the relationship or not
L</in_storage> is a fatal error.


    # set (and replace) the cd tracks
    $cd->set('tracks', [
        { title => 'Track1', duration => ... },
        { title => 'Track2', duration => ... },
        { title => 'Track3', duration => ... },
    ]);

    # set its tags
    my @tags = $eav->resultset('Tag')->find( name => [qw/ Foo Bar Baz /]);
    $cd->set('tags', \@tags);

You can obviously set attribute and relationships at the same time:

    $cd->set({
        title  => 'New Title',
        year   => 2016,
        tracks => \@tracks
    });

Se also L</add_related> if you want to add (instead of replace) related entities.

=head2 save

=over 4

=item Arguments: none

=item Return Value: $self

=back

Save all changes to the database.

    # modify
    $entity->set( ... );

    $entity->save;

First thing C<save> does is insert the entity (in the entities table) if its
not already L</in_storage>. Then it saves the non-static attributes:
attributes values (in the values tables) are inserted, updated or deleted,
whether the value is new (undef -> value), existing (value -> value),
or undef (value -> undef).

Then relationship bindings are inserted/deleted according with each relationship
type and rules. Related entities in the form of hashref is inserted before the
bindings takes place.

Last but not least, modifications to static attributes are saved on the
L<entities table|DBIx::EAV::Schema>.

=head2 update

=over 4

=item Arguments: $name, $value \%values

=item Arguments: \%values

=item Return Value: L<$self|DBIx::EAV::Entity>

=back

A shortcut for C<set()> and C<save()>.

    # set and save in one call
    $cd->update({
        title => 'New CD Title',
        year  => 2016
    });


=head2 load_attributes

=over 4

=item Arguments: @attr_names?

=back

Fetches the attributes values from database L<value tables> and stores in
entity's L</raw> data structure. If this method is called without arguments
all attributes will be loaded.

NOTE: In the current version of DBIx::EAV this method is called internally by
L<DBIx::EAV::Cursor/next>, which makes all attributes to be loaded everytime.
Its planned for a future version to make the attributes get lazy-loaded, which
will make this method relevant.

=head2 add_related

=over 4

=item Arguments: L<$rel_name|DBIx::EAV::EntityType/relationship>, $related_data

=back

Available only for has_many and many_to_many relationships, this method binds
entities via the C<$rel_name> relationship. C<$related_data> must be a
L<entity|DBIx::EAV::Entity> instance (of the proper type for the relationship)
or a hashref of data to be inserted (again, suitable for the related type), or a
arrayref of those. Passing L<Entity|DBIx::EAV::Entity> objects which are not
L</in_storage> results in a fatal error.

    # add tracks to a cd
    $cd->add_related('tracks', [
        { title => 'Track1', duration => ... },
        { title => 'Track2', duration => ... },
        { title => 'Track3', duration => ... },
    ]);

    # also accepts existing entities
    my @tracks = $eav->resultset('Track')->populate( ... );
    $cd->add_related('tracks', \@tracks);


=head2 remove_related

=over 4

=item Arguments: L<$rel_name|DBIx::EAV::EntityType/relationship>, L<$related_entities|DBIx::EAV::Entity>

=back

Unbinds C<$related_entities> from the relationship C<$rel_name>. Note that it
doesn't delete the related entities.

    my @tags = $eav->resultset('Tag')->find( name => [qw/ Foo Bar Baz /]);
    $article->remove_related('tags', \@tags);

=head2 discard_changes

Reverts all modified attributes to the its original value. Note that the internal
memory of modified attributes is reset after a call to L</save>.

=head2 delete

=over

=item Arguments: none

=item Return Value: L<$result|DBIx::Class::Manual::ResultClass>

=back

Throws an exception if the object is not in the database according to
L</in_storage>.

The object is still perfectly usable, but L</in_storage> will
now return 0 and the object will be reinserted (same attrs, new id) if you
call L</save>.

If you delete an object in a class with a C<has_many> or C<has_one>
relationship, an attempt is made to delete all the related objects as well.
To turn this behaviour off, pass C<< cascade_delete => 0 >> in the C<$attr>
hashref of the relationship, see L<DBIx::EAV/Relationships>.

Since a entity is represented by data not only in the entities table, but also
in value tables and relationship links table, those related rows must be deleted
before the main row.

First a C<DELETE> is executed for the relationship links table where this entity
is the right-side entity, unbinding from "parent" relationships. Then a
C<DELETE> query is executed for each value table, unless this entity has no
attributes of that data type.

Those extra C<DELETE> operations are unneccessary if you are using database-level
C<ON DELETE CASCADE>. See L<DBIx::EAV/DATABASE-LEVEL CASCADE DELETE>.

See also L<DBIx::EAV::ResulutSet/delete>.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
