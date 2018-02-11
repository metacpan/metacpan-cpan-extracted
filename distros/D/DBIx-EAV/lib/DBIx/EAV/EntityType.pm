package DBIx::EAV::EntityType;

use Moo;
use strictures 2;
use Carp qw/ confess /;



has 'core', is => 'ro', required => 1;
has 'id', is => 'ro', required => 1;
has 'name', is => 'ro', required => 1;
has 'parent', is => 'ro', predicate => 1;
has '_static_attributes', is => 'ro', init_arg => undef, lazy => 1, builder => 1;
has '_attributes', is => 'ro', init_arg => 'attributes', default => sub { {} };
has '_relationships', is => 'ro', init_arg => 'relationships', default => sub { {} };


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
    $sth = $self->core->table('relationships')->select([ {left_entity_type_id => $self->id} , {right_entity_type_id => $self->id} ]);

    while (my $rel = $sth->fetchrow_hashref) {

        if ($self->id eq $rel->{left_entity_type_id}) {
            $self->_relationships->{$rel->{name}} = $rel;
        }
        else {
            $self->_relationships->{$rel->{incoming_name}} = {
                %$rel,
                is_right_entity => 1,
                name => $rel->{incoming_name},
                incoming_name => $rel->{name},
            };
        }
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
    confess 'usage: is_type($type)' unless $type;
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



sub prune_attributes {
    my ($self, $names) = @_;
    # TODO implement prune_attributes
    die "not implemented yet";
}

sub prune_relationships {
    my ($self, $names) = @_;
    # TODO implement prune_relationships
    die "not implemented yet";
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
