package DBIx::EAV;

use Moo;
use strictures 2;
use DBI;
use Lingua::EN::Inflect ();
use Data::Dumper;
use DBIx::EAV::EntityType;
use DBIx::EAV::Entity;
use DBIx::EAV::ResultSet;
use DBIx::EAV::Schema;
use Carp qw' croak confess ';
use Scalar::Util 'blessed';
use Class::Load qw' try_load_class ';
use namespace::clean;

our $VERSION = "0.09";

# required
has 'dbh', is => 'ro', required => 1;

# options
has 'default_attribute_type', is => 'ro', default => 'varchar';
has 'schema_config', is => 'ro', default => sub { {} };
has 'entity_namespaces', is => 'ro', default => sub { [] };
has 'resultset_namespaces', is => 'ro', default => sub { [] };

# internal
has 'schema', is => 'ro', lazy => 1, builder => 1, init_arg => undef, handles => [qw/ table dbh_do /];
has '_types', is => 'ro', default => sub { {} };
has '_types_by_id', is => 'ro', default => sub { {} };

# group schema_config params
around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $params = @args == 1 && ref $args[0] ? $args[0] : { @args };
    my $schema_config = delete $params->{schema_config} || {};

    my @schema_params = grep { exists $params->{$_} } qw/
        tenant_id         data_types   database_cascade_delete static_attributes
        table_prefix      id_type      default_attribute_type
    /;

    @{$schema_config}{@schema_params} = delete @{$params}{@schema_params};

    $class->$orig(%$params, schema_config => $schema_config);
};


sub _build_schema {
    my $self = shift;
    DBIx::EAV::Schema->new(%{$self->schema_config}, dbh => $self->dbh);
}

sub connect {
    my ($class, $dsn, $user, $pass, $attrs, $constructor_params) = @_;

    croak 'Missing $dsn argument for connect()' unless $dsn;

    croak "connect() must be called as a class method."
        if ref $class;

    $constructor_params //= {};

    $constructor_params->{dbh} = DBI->connect($dsn, $user, $pass, $attrs)
        or die $DBI::errstr;

    $class->new($constructor_params);
}

sub type {
    my ($self, $value) = @_;

    return $self->_types->{$value}
        if exists $self->_types->{$value};

    my $type = $self->_load_type('name', $value);

    # not registered, try to find  a custom entity class and register it
    if (!$type && (my $entity_class = $self->_resolve_entity_class($value))) {

        ($type) = $self->register_types({$value => $entity_class->type_definition});
    }

    confess "EntityType '$value' does not exist."
        unless $type;

    $type;
}

sub type_by_id {
    my ($self, $value) = @_;

    return $self->_types_by_id->{$value}
        if exists $self->_types_by_id->{$value};

    $self->_load_type('id', $value)
        or confess "EntityType 'id=$value' does not exist.";
}

sub _load_type {
    my ($self, $field, $value) = @_;

    my $type_row = $self->table('entity_types')->select_one({ $field => $value });
    return unless $type_row;

    my $type = DBIx::EAV::EntityType->load({ %$type_row, core => $self});
    $self->_types->{$type->name} = $type;
    $self->_types_by_id->{$type->id} = $type;
    $type;
}

sub _resolve_entity_class {
    my ($self, $name) = @_;

    foreach my $ns (@{ $self->entity_namespaces }) {

        my $entity_class = join '::', $ns, $name;
        my ($is_loaded, $error) = try_load_class $entity_class;

        return $entity_class if $is_loaded;

        # rethrow compilation errors
        die $error if $error =~ /^Can't locate .* in \@INC/;
    }

    return;
}

sub _resolve_resultset_class {
    my ($self, $name) = @_;

    foreach my $ns (@{ $self->resultset_namespaces }) {

        my $class = join '::', $ns, $name;
        my ($is_loaded, $error) = try_load_class $class;

        return $class if $is_loaded;

        # rethrow compilation errors
        die $class;
    }

    return;
}

sub resultset {
    my ($self, $name) = @_;

    my $rs_class = $self->_resolve_resultset_class($name)
        || 'DBIx::EAV::ResultSet';

    $rs_class->new({
        eav  => $self,
        type => $self->type($name),
    });
}


sub register_types {
    my ($self, $schema) = @_;
    my %skip;

    # register only not-installed entities to
    # allow multiple calls to this method
    my @new_types = grep { not exists $self->_types->{$_} } keys %$schema;

    # create or update each entity type on database
    my @registered_types;
    foreach my $name (@new_types) {
        next if exists $self->_types->{$name};
        push @registered_types,
             $self->_register_entity_type($name, $schema->{$name}, $schema);
    }

    # register relationships
    foreach my $name (@new_types) {

        my $spec = $schema->{$name};
        my $entity_type = $self->type($name);

        foreach my $reltype (qw/ has_one has_many many_to_many /) {

            next unless defined $spec->{$reltype};

            $spec->{$reltype} ||= [];
            $spec->{$reltype} = [$spec->{$reltype}]
                unless ref $spec->{$reltype} eq 'ARRAY';

            foreach my $rel (@{$spec->{$reltype}}) {
                $entity_type->register_relationship($reltype, $rel);
            }
        }
    }

    @registered_types;
}


sub _register_entity_type {
    my ($self, $name, $spec, $schema) = @_;

    # parent type first
    my $parent_type;
    if ($spec->{extends}) {

        unless ($parent_type = $self->_types->{$spec->{extends}}) {

            die "Unknown type '$spec->{extends}' specified in 'extents' option for type '$name'."
                unless exists $schema->{$spec->{extends}};

            $parent_type = $self->_register_entity_type($spec->{extends}, $schema->{$spec->{extends}}, $schema);
        }
    }

    # find or create entity type
    my $types_table = $self->table('entity_types');
    my $hierarchy_table = $self->table('type_hierarchy');
    my $type = $types_table->select_one({ name => $name });

    if (defined $type) {

        # change parent
    }
    else {

        # TODO implement rename
        # if ($spec->{rename_from}) { ... }

        my $id = $types_table->insert({ name => $name });
        $type = $types_table->select_one({ id => $id });
        die "Error inserting entity type '$name'!" unless $type;

        if ($parent_type) {
            $hierarchy_table->insert({
                parent_type_id => $parent_type->{id},
                child_type_id  => $type->{id}
            });

            $type->{parent} = $parent_type;
        }
    }

    # update or create attributes
    my $attributes = $self->table('attributes');
    my %static_attributes = map { $_ => {name => $_, is_static => 1} } @{$self->table('entities')->columns};
    $type->{attributes} = {};

    my %inherited_attributes = $parent_type ? map { $_->{name} => $_ } $parent_type->attributes( no_static => 1 )
                                            : ();

    foreach my $attr_spec (@{$spec->{attributes}}) {

        # expand string to name/type
        unless (ref $attr_spec) {
            my ($name, $type) = split ':', $attr_spec;
            $attr_spec = {
                name => $name,
                type => $type || $self->default_attribute_type
            };
        }

        die sprintf("Error registering attribute '%s' for  entity '%s'. Can't use names of static attributes (real table columns).", $attr_spec->{name}, $type->{name})
            if exists $static_attributes{$attr_spec->{name}};

        printf STDERR "[warn] entity '%s' is overriding inherited attribute '%s'", $name, $attr_spec->{name}
            if $inherited_attributes{$attr_spec->{name}};

        my $attr = $attributes->select_one({
            entity_type_id => $type->{id},
            name => $attr_spec->{name}
        });

        if (defined $attr) {
            # update
        }
        else {
            delete $attr_spec->{id}; # safety

            my %data = %$attr_spec;

            $data{entity_type_id} = $type->{id};
            $data{data_type} = delete($data{type}) || $self->default_attribute_type;

            die sprintf("Attribute '%s' has unknown data type '%s'.", $data{name}, $data{data_type})
                unless $self->schema->has_data_type($data{data_type});

            $attributes->insert(\%data);
            $attr = $attributes->select_one(\%data);
            die "Error inserting attribute '$attr_spec->{name}'!" unless $attr;
        }

        $type->{attributes}{$attr->{name}} = $attr;
    }

    $self->_types->{$name} =
        $self->_types_by_id->{$type->{id}} = DBIx::EAV::EntityType->new(%$type, core => $self);
}



1;

__END__

=encoding utf-8

=head1 NAME

DBIx::EAV - Entity-Attribute-Value data modeling (aka 'open schema') for Perl

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use DBIx::EAV;

    # connect to the database
    my $eav = DBIx::EAV->connect("dbi:SQLite:database=:memory:");

    # or
    # $eav = DBIx::EAV->new( dbh => $dbh, %constructor_params );

    # create eav tables
    $eav->schema->deploy;

    # register entities
    $eav->register_types({
        Artist => {
            many_to_many => 'CD',
            has_many     => 'Review',
            attributes   => [qw/ name:varchar description:text rating:int birth_date:datetime /]
        },

        CD => {
            has_many     => ['Track', 'Review'],
            has_one      => ['CoverImage'],
            attributes   => [qw/ title description:text rating:int /]
        },

        Track => {
            attributes   => [qw/ title description:text duration:int /]
        },

        CoverImage => {
            attributes   => [qw/ url /]
        },

        Review => {
            attributes => [qw/ content:text views:int likes:int dislikes:int /]
        },
    });


    # insert data (and possibly related data)
    my $bob = $eav->resultset('Artist')->insert({
        name => 'Robert',
        description => '...',
        cds => [
            { title => 'CD1', rating => 5 },
            { title => 'CD2', rating => 6 },
            { title => 'CD3', rating => 8 },
            { title => 'CD4', rating => 9 },
        ]
     });

    # get attributes
    print $bob->get('name'); # Robert

    # update name
    $bob->update({ name => 'Bob' });

    # add more cds
    $bob->add_related('cds', { title => 'CD5', rating => 7 });

    # get Bob's cds via auto-generated 'cds' relationship
    print "\nAll Bob CDs:\n";
    printf " - %s (rating %d)\n", $_->get('title'), $_->get('rating')
        foreach $bob->get('cds');

    print "\nBest Bob CDs:\n";
    printf " - %s (rating %d)\n", $_->get('title'), $_->get('rating')
        foreach $bob->get('cds', { rating => { '>' => 7 } });


    # ResultSets ...


    # retrieve Bob from database
    $bob = $eav->resultset('Artist')->find({ name => 'Bob' });

    # retrieve Bob's cds directly from CD resultset
    # note the use of 'artists' relationship automaticaly created
    # from the "Artist many_to_many CD" declaration
    my @cds = $eav->resultset('CD')->search({ artists => $bob });

    # same as above
    @cds = $bob->get('cds');

    # or traverse the cds using the resultset cursor
    my $cds_rs = $bob->get('cds');

    while (my $cd = $cds_rs->next) {
        print $cd->get('title');
    }

    # delete all cds
    $eav->resultset('CD')->delete;

    # delete all cds and related data (i.e. tracks)
    $eav->resultset('CD')->delete_all;



=head1 DESCRIPTION

An implementation of Entity-Attribute-Value data modeling with support for
entity relationships, inheritance, custom classes and multi-tenancy.
See L<DBIx::EAV::Manual>.

=head1 ALPHA STAGE

This project is in its infancy, and the main purpose of this stage is to let
other developers try it, and help identify any major design flaw before we can
stabilize the API. One exception is the ResultSet whose API (and docs :]) I've
borrowed from L<DBIx::Class>, so its (API is) already stable.

=head1 CONSTRUCTORS

=head2 new

=over

=item Arguments: %params

=back

Valid C<%params> keys:

=over

=item dbh B<(required)>

Existing L<DBI> database handle. See L</connect>.

=item schema_config

Hashref of options used to instantiate our L<DBIx::EAV::Schema>.
See L<DBIx::EAV::Schema/"CONSTRUCTOR OPTIONS">.

=item entity_namespaces

Arrayref of namespaces to look for custom L<entity|DBIx::EAV::Entity> classes.

    # mimic DBIx::Class
    entity_namespaces => ['MyApp::Schema::Result']

Class names are created by appending the entity type name to each namespace in
the list. The first existing class is used.

Custom entity classes are useful not only provide custom business logic, but
also to define your entities, like DBIx::Class result classes.
See L<DBIx::EAV::Entity/"CUSTOM CLASS">.

=item resultset_namespaces

Arrayref of namespaces to look for custom resultset classes.

    # mimic DBIx::Class
    resultset_namespaces => ['MyApp::Schema::ResultSet']

Class names are created by appending the entity type name to each namespace in
the list. The first existing class is used.

=back

=head2 connect

=over

=item Arguments: $dsn, $user, $pass, $attrs, \%constructor_params

=back

Connects to the database via C<< DBI->connect($dsn, $user, $pass, $attrs) >>
then returns a new instance via L<new(\%constructor_params)|/new>.

=head1 METHODS

=head2 register_types

=over

=item Arguments: \%schema

=item Return value: none

=back

Registers entity types specified in \%schema, where each key is the name of the
L<type|DBIx::EAV::EntityType> and the value is a hashref describing its
attributes and relationships. Fully described in
L<DBIx::EAV::EntityType/"ENTITY DEFINITION">.

This method ignores types already installed, allowing code that registers types
to live close to the code that actually uses the types.

When registering types already registered, additional attributes and
relationships are registered accordingly. To delete attributes and values see
L<DBIx::EAV::EntityType/PRUNING>.

See L<"INSTALLED VS REGISTERED TYPES">.

=head2 resultset

=over

=item Arguments: $name

=item Return value: L<$rs|DBIx::EAV::ResultSet>

=back

Returns a new L<resultset|DBIx::EAV::ResultSet> instance for
L<type|DBIx::EAV::EntityType> C<$name>.

    my $rs = $eav->resultset('Artist');

=head2 type

=over

=item Arguments: $name

=back

Returns the L<DBIx::EAV::EntityType> instance for type C<$name>. If the type
instance is not already installed in this DBIx::EAV instance, we try to load
the type definition from the database. Dies if type is not registered.

    my $types = $eav->type('Artist');

See L<"INSTALLED VS REGISTERED TYPES">.

=head2 has_type

=over

=item Arguments: $name

=back

Returns true if L<entity type|DBIx::EAV::EntityType> C<$name> is installed.

=head2 schema

Returns the L<DBIx::EAV::Schema> instance representing the physical database tables.

=head2 table

Shortcut for C<< ->schema->table >>.

=head2 dbh_do

=over

=item Arguments: $stmt, \@bind?

=item Return Values: ($rv, $sth)

Prepares C<$stmt> and executes with the optional C<\@bind> values. Returns the
return value from execute C<$rv> and the actual statement handle C<$sth> object.

Set environment variable C<DBIX_EAV_TRACE> to 1 to get statements printed to
C<STDERR>.

=back

=head1 INSTALLED VS REGISTERED TYPES

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
