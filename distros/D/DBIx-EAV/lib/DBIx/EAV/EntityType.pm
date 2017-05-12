package DBIx::EAV::EntityType;

use Moo;
use strictures 2;



has 'core', is => 'ro', required => 1;
has 'id', is => 'ro', required => 1;
has 'name', is => 'ro', required => 1;
has 'parent', is => 'ro', predicate => 1;
has '_static_attributes', is => 'ro', init_arg => undef, lazy => 1, builder => 1;
has '_attributes', is => 'ro', init_arg => 'attributes', default => sub { {} };
has '_relationships', is => 'ro', init_arg => undef, default => sub { {} };


sub _build__static_attributes {
    my $self = shift;
    +{
        map { $_ => {name => $_, is_static => 1} }
            @{$self->core->table('entities')->columns}
    }
}

sub load {
    my ($class, $row) = @_;
    die "load() is a class method" if ref $class;

    my $self = $class->new($row);

    # load attributes
    my $sth = $self->core->table('attributes')->select({ entity_type_id => $self->id });

    while (my $attr = $sth->fetchrow_hashref) {
        $self->_attributes->{$attr->{name}} = $attr;
    }

    # load relationships
    $sth = $self->core->table('relationships')->select({ left_entity_type_id => $self->id });

    while (my $rel = $sth->fetchrow_hashref) {
        $self->_install_relationship($rel);
    }

    $self;
}

sub parents {
    my ($self) = @_;
    return () unless $self->has_parent;
    my @parents;
    my $parent = $self->parent;
    while ($parent) {
        push @parents, $parent;
        $parent = $parent->parent;
    }

    @parents;
}

sub is_type($) {
    my ($self, $type) = @_;
    return 1 if $self->name eq $type;
    foreach my $parent ($self->parents) {
        return 1 if $parent->name eq $type;
    }
    0;
}




sub has_attribute {
    my ($self, $name) = @_;
    return 1 if exists $self->_attributes->{$name} || exists $self->_static_attributes->{$name};
    return 0 unless $self->has_parent;

    my $parent = $self->parent;
    while ($parent) {
        return 1 if $parent->has_own_attribute($name);
        $parent = $parent->parent;
    }

    0;
}

sub has_static_attribute {
    my ($self, $name) = @_;
    exists $self->_static_attributes->{$name};
}

sub has_own_attribute {
    my ($self, $name) = @_;
    exists $self->_attributes->{$name} || exists $self->_static_attributes->{$name};
}

sub has_inherited_attribute {
    my ($self, $name) = @_;
    return 0 unless $self->has_parent;
    my $parent = $self->parent;
    while ($parent) {
        return 1 if exists $parent->_attributes->{$name};
        $parent = $parent->parent;
    }
    0;
}

sub attribute {
    my ($self, $name) = @_;

    # our attr
    return $self->_attributes->{$name}
        if exists $self->_attributes->{$name};

    return $self->_static_attributes->{$name}
        if exists $self->_static_attributes->{$name};

    # parent attr
    my $parent = $self->parent;
    while ($parent) {
        return $parent->_attributes->{$name}
            if exists $parent->_attributes->{$name};
        $parent = $parent->parent;
    }

    # unknown attribute
    die sprintf("Entity '%s' does not have attribute '%s'.", $self->name, $name);
}

sub attributes {
    my ($self, %options) = @_;
    my @items;

    # static
    push @items, values %{$self->_static_attributes}
        unless $options{no_static};

    # own
    push @items, values %{$self->_attributes}
        unless $options{no_own};

    # inherited
    unless ($options{no_inherited}) {

        my $parent = $self->parent;
        while ($parent) {
            push @items, values %{$parent->_attributes};
            $parent = $parent->parent;
        }
    }

    return $options{names} ? map { $_->{name} } @items : @items;
}




sub has_own_relationship {
    my ($self, $name) = @_;
    exists $self->_relationships->{$name};
}

sub has_relationship {
    my ($self, $name) = @_;
    return 1 if exists $self->_relationships->{$name};
    return 0 unless $self->has_parent;

    my $parent = $self->parent;
    while ($parent) {
        return 1 if $parent->has_own_relationship($name);
        $parent = $parent->parent;
    }

    0;
}

sub relationship {
    my ($self, $name) = @_;

    # our
    return $self->_relationships->{$name}
        if exists $self->_relationships->{$name};

    # parent
    my $parent = $self->parent;
    while ($parent) {
        return $parent->_relationships->{$name}
            if exists $parent->_relationships->{$name};
        $parent = $parent->parent;
    }

    # unknown
    die sprintf("Entity '%s' does not have relationship '%s'.", $self->name, $name);
}

sub relationships {
    my ($self, %options) = @_;

    # ours
    my @items = values %{$self->_relationships};

    # inherited
    unless ($options{no_inherited}) {

        my $parent = $self->parent;
        while ($parent) {
            push @items, values %{$parent->_relationships};
            $parent = $parent->parent;
        }
    }

    return $options{names} ? map { $_->{name} } @items : @items;
}


sub register_relationship {
    my ($self, $reltype, $params) = @_;

    # scalar: entity
    $params = { entity => $params } unless ref $params;

    # array: name => Entity [, incoming_name ]
    if (ref $params eq 'ARRAY') {

        $params = {
            name => $params->[0],
            entity  => $params->[1],
            incoming_name => $params->[2],
        };
    }

    die sprintf("Error: invalid %s relationship for entity '%s': missing 'entity' parameter.", $reltype, $self->name)
        unless $params->{entity};

    my $other_entity = $self->core->type($params->{entity});

    $params->{name} ||= $reltype =~ /_many$/ ? lc Lingua::EN::Inflect::PL($other_entity->name)
                                             : lc $other_entity->name;

    $params->{incoming_name} ||= $reltype eq 'many_to_many' ? lc Lingua::EN::Inflect::PL($self->name)
                                                            : lc $self->name;

    my %rel = (
        left_entity_type_id  => $self->id,
        right_entity_type_id => $other_entity->id,
        name => $params->{name},
        incoming_name => $params->{incoming_name},
        "is_$reltype" => 1
    );

    # update or insert
    my $relationships_table = $self->core->table('relationships');
    my $existing_rel = $relationships_table->select_one({
        left_entity_type_id => $self->id,
        name => $rel{name},
    });

    if ($existing_rel) {

        $rel{id} = $existing_rel->{id};

        # update
        my %changed_cols = map { $_ => $rel{$_} }
                           grep { $rel{$_} ne $existing_rel->{$_} }
                           keys %rel;

        $relationships_table->update(\%changed_cols, { id => $rel{id} })
            if keys %changed_cols > 0;
    }
    else {
        my $id = $relationships_table->insert(\%rel);
        die sprintf("Database error while registering  '%s -> %s' relationship.", $self->name, $rel{name})
            unless $id;

        $rel{id} = $id;
    }

    # install relationship
    $self->_install_relationship(\%rel);
}

sub _install_relationship {
    my ($self, $rel) = @_;
    my $relname = $rel->{name};

    die sprintf("Entity '%s' already has relationship '%s'.", $self->name, $relname)
        if $self->has_relationship($relname);

    my $other_entity = $self->core->type_by_id($rel->{right_entity_type_id});

    # install our side
    $self->_relationships->{$relname} = {
        %$rel,
        entity => $other_entity->name
    };

    # install their side
    die sprintf("Entity '%s' already has relationship '%s'.", $self->name, $relname)
        if $other_entity->has_relationship($rel->{incoming_name});

    $other_entity->_relationships->{$rel->{incoming_name}} = {
        %$rel,
        entity => $self->name,
        is_right_entity => 1,
        name => $rel->{incoming_name},
        incoming_name => $rel->{name},
    };
}


# sub _install_relationship {
#     my ($self, $relname, $rel) = @_;
#
#     die sprintf("Entity '%s' already has relationship '%s'.", $self->name, $relname)
#         if exists $self->_relationships->{$relname};
#
#     $self->_relationships->{$relname} = $rel;
# }



sub prune_attributes {
    my ($self, $names) = @_;
    # TODO implement prune_attributes
}

sub prune_relationships {
    my ($self, $names) = @_;
    # TODO implement prune_relationships
}









1;


__END__

=encoding utf-8

=head1 NAME

DBIx::EAV::EntityType - An entity definition. Its attributes and relationships.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ENTITY DEFINITION

An entity definition is a key/value pair in the form of C<< EntityName => \%definition >>,
where the possible keys for %definition are:

=over

=item attributes

=item has_one

An arrayref of related entity names to create a has_one relationship.

=item has_many

An arrayref of related entity names to create a has_many relationship.

=item many_to_many

An arrayref of related entity names to create a many_to_many relationship.

=back

=head1 METHODS

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
