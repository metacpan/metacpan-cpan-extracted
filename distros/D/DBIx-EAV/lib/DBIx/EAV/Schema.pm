package DBIx::EAV::Schema;

use Moo;
use Carp 'croak';
use Scalar::Util 'blessed';
use DBIx::EAV::Table;
use SQL::Translator;
use constant {
    SQL_DEBUG => $ENV{DBIX_EAV_TRACE}
};

our $SCHEMA_VERSION = 1;


my %driver_to_producer = (
    mysql => 'MySQL'
);


has 'dbh', is => 'ro', required => 1;

has 'database_cascade_delete', is => 'ro', default => 1;
has 'table_prefix', is => 'ro', default => 'eav_';
has 'tenant_id', is => 'ro';
has 'data_types', is => 'ro', default => sub { [qw/ int decimal varchar text datetime bool /] };
has 'static_attributes', is => 'ro', default => sub { [] };
has 'id_type', is => 'ro', default => 'int';

has 'translator', is => 'ro', init_arg => undef, lazy => 1, builder => 1;
has '_tables', is => 'ro', init_arg => undef, default => sub { {} };


sub BUILD {
    my $self = shift;

    # enable sqlite fk for cascade delete to work
    $self->dbh_do("PRAGMA foreign_keys = ON;")
        if $self->db_driver_name eq 'SQLite';
}


sub _build_translator {
    my $self = shift;

    my $sqlt = SQL::Translator->new;
    $self->_build_sqlt_schema($sqlt->schema);

    $sqlt;
}

sub _build_sqlt_schema {
    my ($self, $schema) = @_;

    my @schema = (

        entity_types => {
            columns => ['id', $self->tenant_id ? 'tenant_id' : (), 'name:varchar:255'],
            index   => [$self->tenant_id ? 'tenant_id' : ()],
            unique  => {
                name => [$self->tenant_id ? 'tenant_id' : (),'name']
            }
        },

        entities => {
            columns => [qw/ id entity_type_id  /, @{ $self->static_attributes } ],
            fk      => { entity_type_id => 'entity_types' }
        },

        attributes => {
            columns => [qw/ id entity_type_id name:varchar:255 data_type:varchar:64 /],
            fk      => { entity_type_id => 'entity_types' }
        },

        relationships => {
            columns => [qw/ id left_entity_type_id right_entity_type_id name:varchar:255 incoming_name:varchar:255 is_has_one:bool::0 is_has_many:bool::0 is_many_to_many:bool::0 /],
            fk      => { left_entity_type_id => 'entity_types', right_entity_type_id => 'entity_types' },
            unique  => {
                name => ['left_entity_type_id','name']
            }
        },

        entity_relationships => {
            columns => [qw/ relationship_id left_entity_id right_entity_id /],
            pk => [qw/ relationship_id left_entity_id right_entity_id /],
            fk => {
                relationship_id => 'relationships',
                left_entity_id  => { table => 'entities', cascade_delete => $self->database_cascade_delete },
                right_entity_id => { table => 'entities', cascade_delete => $self->database_cascade_delete },
            }
        },

        type_hierarchy => {
            columns => [qw/ parent_type_id child_type_id /],
            pk => [qw/ parent_type_id child_type_id /],
            fk => {
                parent_type_id => { table => 'entity_types', cascade_delete => $self->database_cascade_delete },
                child_type_id  => { table => 'entity_types', cascade_delete => $self->database_cascade_delete },
            }
        },

        map {
            ("value_$_" => {
                columns => [qw/ entity_id attribute_id /, 'value:'.$_],
                fk => {
                    entity_id    => { table => 'entities', cascade_delete => $self->database_cascade_delete },
                    attribute_id => 'attributes'
                }
            })
        } @{ $self->data_types }
    );

    for (my $i = 0; $i < @schema; $i += 2) {

        # add table
        my $table_name = $schema[$i];
        my $table_schema = $schema[$i+1];
        my $table = $schema->add_table( name => $self->table_prefix . $table_name )
            or die $schema->error;

        # add columns
        foreach my $col ( @{ $table_schema->{columns} }) {

            my $field_params = ref $col ? $col : do {

                my ($name, $type, $size, $default) = split ':', $col;
                +{
                    name => $name,
                    data_type => $type,
                    size => $size,
                    default_value => $default
                }
            };

            $field_params->{data_type} = $self->id_type
                if $field_params->{name} =~ /(?:^id$|_id$)/;

            $field_params->{is_auto_increment} = 1
                if $field_params->{name} eq 'id';

            $field_params->{is_nullable} //= 0;

            $table->add_field(%$field_params)
                or die $table->error;
        }

        # # primary key
        my $pk = $table->get_field('id') ? 'id' : $table_schema->{pk};
        $table->primary_key($pk) if $pk;

        # # foreign keys
        foreach my $fk_column (keys %{ $table_schema->{fk} || {} }) {

            my $params = $table_schema->{fk}->{$fk_column};
            $params = { table => $params } unless ref $params;

            $table->add_constraint(
                name => join('_', 'fk', $table_name, $fk_column, $params->{table}),
                type => 'foreign_key',
                fields => $fk_column,
                reference_fields => 'id',
                reference_table => $self->table_prefix . $params->{table},
                on_delete => $params->{cascade_delete} ? 'CASCADE' : 'NO ACTION'
            );
        }

        # # unique constraints
        foreach my $name (keys %{ $table_schema->{unique} || {} }) {

            $table->add_index(
                name => join('_', 'unique', $table_name, $name),
                type => 'unique',
                fields => $table_schema->{unique}{$name},
            );
        }

        # # index
        foreach my $colname (@{ $table_schema->{index} || [] }) {

            $table->add_index(
                name => join('_', 'idx', $table_name, $colname),
                type => 'normal',
                fields => $colname,
            );
        }
    }

    return 1;
}


sub version { $SCHEMA_VERSION }

sub get_ddl {
    my ($self, $producer) = @_;

    unless ($producer) {

        my $driver = $self->dbh->{Driver}{Name};
        $producer = $driver_to_producer{$driver} || $driver;
    }

    $self->translator->producer($producer);
    $self->translator->translate;
}

sub version_table {
    my $self = shift;

    DBIx::EAV::Table->new(
        dbh       => $self->dbh,
        name      => $self->table_prefix . 'schema_versions',
        columns   => [qw/ id version ddl /]
    );
}

sub version_table_is_installed {
    my $self = shift;

    my $success = 0;

    eval {
        $self->dbh_do(sprintf 'SELECT COUNT(*) FROM %s', $self->table_prefix . 'schema_versions');
        $success = 1;
    };

    $success;
}

sub install_version_table {
    my $self = shift;

    my $sqlt = SQL::Translator->new;
    my $table = $sqlt->schema->add_table( name => $self->version_table->name );

    $table->add_field(
        name => 'id',
        data_type => 'INTEGER',
        is_auto_increment => 1
    );

    $table->add_field(
        name => 'version',
        data_type => 'INTEGER'
    );

    $table->add_field(
        name => 'ddl',
        data_type => 'TEXT'
    );

    $table->primary_key('id');

    # execute ddl
    my $driver = $self->dbh->{Driver}{Name};
    $sqlt->producer($driver_to_producer{$driver} || $driver);

    $self->dbh_do($_)
        for grep { /\w/ } split ';', $sqlt->translate;

}

sub installed_version {
    my $self = shift;
    my $table = $self->version_table;
    my $row;
    eval {
        my ($rv, $sth) = $self->dbh_do(sprintf 'SELECT * FROM %s ORDER BY id DESC', $table->name);
        $row = $sth->fetchrow_hashref;
    };
    return unless $row;
    $row->{version};
}

sub deploy {
    my $self = shift;
    my %options = ( @_, no_comments => 1 );

    $self->translator->$_($options{$_})
        for keys %options;

    # deploy version table
    $self->install_version_table
        unless $self->version_table_is_installed;

    # check we already installed this version
    my $version_table = $self->version_table;
    return if $version_table->select_one({ version => $self->version });

    # deploy ddl
    my $ddl = $self->get_ddl;
    $self->dbh_do($_)
        for grep { /\w/ } split ';', $ddl;

    # create version record
    $version_table->insert({
        version => $self->version,
        ddl => 'DDL'
    });
}


sub dbh_do {
    my ($self, $stmt, $bind) = @_;

    if (SQL_DEBUG) {
        my $i = 0;
        print STDERR "$stmt";
        print STDERR $bind ? sprintf(": %s\n", join('  ', map { $i++.'='.$_ } @{ $bind || [] }))
                           : ";\n";
    }

    my $sth = $self->dbh->prepare($stmt);
    my $rv = $sth->execute(ref $bind eq 'ARRAY' ? @$bind : ());
    die $sth->errstr unless defined $rv;

    return ($rv, $sth);
}

sub table {
    my ($self, $name) = @_;

    return $self->_tables->{$name}
        if exists $self->_tables->{$name};

    my $table_schema = $self->translator->schema->get_table($self->table_prefix . $name);

    croak "Table '$name' does not exist."
        unless $table_schema;

    $self->_tables->{$name} = DBIx::EAV::Table->new(
        dbh       => $self->dbh,
        tenant_id => $self->tenant_id,
        name      => $table_schema->name,
        columns   => [ $table_schema->field_names ]
    );
}

sub has_data_type {
    my ($self, $name) = @_;
    foreach (@{$self->data_types}) {
        return 1 if $_ eq $name;
    }
    0;
}

sub db_driver_name {
    shift->dbh->{Driver}{Name};
}


1;


__END__

=encoding utf-8

=head1 NAME

DBIx::EAV::Schema - Describes the physical EAV database schema.

=head1 SYNOPSIS

    my $schema = DBIx:EAV::Schema->new(
        dbh          => $dbh,               # required
        tables       => \%tables            # required
        tenant_id    => $tenant_id,         # default undef
        table_prefix => 'my_eav_',          # default 'eav_'
    );

=head1 DESCRIPTION

This class represents the physical eav database schema. Will never need to
instantiate an object of this class directly.

=head1 CONSTRUCTOR OPTIONS

=head2 data_types

=over

=item Default: C<[qw/ int decimal varchar text datetime bool /]>

=back

Arrayref of SQL data types that will be available to entity attributes. DBIx::EAV
uses one value table for each data type listed here. See L</values> and L</deploy>.

=head2 static_attributes

=over

=item Default: C<[]>

Arrayref of column definitions which will be available as static attributes for
all entities. A column definition is a string in the form of
C<"$col_name:$data_type:$data_size:$default_value"> or a hashref suitable for
L<SQL::Translator::Schema::Table/add_field>.

Example defining a C<slug VARCHAR(255)> and a C<is_deleted BOOL DEFAULT 0>
attributes. Note that in the definition of C<is_deleted> we wanted to specify
the C<$default_value> but not the C<$data_size> field.

    static_attributes => [qw/ slug:varchar:255 is_deleted:bool::0 /]

=back

=head2 table_prefix

=over

=item Default: C<"eav_">

=back

Prefix added to our tables names to form the real database table name.
See L</TABLES>.

=head2 database_cascade_delete

=over

=item Default: C<1>

=back

When enabled, entities delete operations (via L<DBIx::EAV::Entity/delete> or
L<DBIx::EAV::ResultSet/delete>) are accomplished through a single C<DELETE> SQL command.
Also instructs L</deploy> to create the proper C<ON DELETE CASCADE> constraints.
See L</"CASCADE DELETE">.

=head2 tenant_id

=over

=item Default: C<undef>

=back

Setting this parameter enables the multi-tenancy feature.

=head2 id_type

=over

=item Default: C<"int">

=back

Data type used by L</deploy> for the C<PRIMARY KEY> ('id') and C<FOREIGN KEY> ('*_id') columns.


=head1 TABLES

This section describes the tables used by L<DBIx::EAV>.

=head2 entity_types

=over

=item Columns: id, tenant_id?, name:varchar:255

=item Primary Key: id

=item Index: tenant_id?

=item Unique: name

=back

=head2 attributes

=over

=item Columns: id, entity_type_id, name:varchar:255, data_type:varchar:64

=item Primary Key: id

=item Foreign Key: entity_type_id -> L</entity_types>

=back

=head2 relationships

=over

=item Columns: id, name:varchar:255, left_entity_type_id, right_entity_type_id, is_has_one:bool::0, is_has_many:bool::0, is_many_to_many:bool::0

=item Primary Key: id

=item Foreign Key: left_entity_type_id -> L</entity_types>

=item Foreign Key: right_entity_type_id -> L</entity_types>

=item Unique: left_entity_type_id, name

=back

Stores the relationships definition between L<entity types|/entity_types>.
See L<DBIx::EAV::Manual/RELATIONSHIPS>.

=head2 type_hierarchy

=over

=item Columns: parent_type_id, child_type_id

=item Primary Key: parent_type_id, child_type_id

=item Foreign Key: parent_type_id -> L</entity_types>

=item Foreign Key: child_type_id -> L</entity_types>

=back

Stores the type -> subtype relationship. See L</"TYPE INHERITANCE">.

=head2 entities

=over

=item Columns: id, entity_type_id, (L</static_attributes>)?

=item Primary Key: id

=item Foreign Key: entity_type_id -> L</entity_types>

=back

Stores the main entities rows, which by default contain only the C<id> and
C<entity_type_id> columns. Any defined L</static_attributes> are also added as
real columns of this table. This is a very "tall and skinny" table, tipical of EAV
systems.

=head2 entity_relationships

=over

=item Columns: relationship_id, left_entity_id, right_entity_id

=item Primary Key: id

=item Foreign Key: left_entity_id -> L</entitites> (ON DELETE CASCADE)

=item Foreign Key: right_entity_id -> L</entitites> (ON DELETE CASCADE)

=back

Stores the actual relationship links between L</entities>.

=head2 values

=over

=item Columns: entity_id, attribute_id, value

=item Primary Key: entity_id, attribute_id

=item Foreign Key: entity_id -> L</entitites> (ON DELETE CASCADE)

=item Foreign Key: attribute_id -> L</attributes>

=back

Stores the actual attributes values. One table named
C< $table_prefix . $data_type . "_value" > is created for each data type listed
in L</data_types>.

=head1 METHODS

=head2 table

    my $table = $schema->table($name);

Returns a L<DBIx::EAV::Table> representing the table $name.

=head2 dbh_do

=head2 has_data_type

=head2 deploy

Create the eav database tables.

    $eav->schema->deploy( add_drop_table => 1 );

=head2 get_ddl

Returns the eav schema DDL in any of the supported L<SQL::Translator> producers.
If no argument is passed a producer for the L<current driver|/db_driver_name> is
used.

    my $mysql_ddl = $eav->schema->get_ddl('MySQL');

=head2 db_driver_name

Shortcut for C<< $self->dbh->{Driver}{Name} >>.

=head1 CASCADE DELETE

Since a single L<entity|DBIx::EAV::Entity>'s data is spread over several value
tables, we can't just delete the entity in a single SQL C<DELETE> command.
We must first send a C<DELETE> for each of those value tables, and one more for
the L</entity_relationships> table. If an entity has attributes of 4 data types,
and has any relationship defined, a total of 6 (six!!) C<DELETE> commands will
be needed to delete a single entity. Four to the L</values> tables, one to the
L</entity_relationships> and one for the actual L</entities> table).

Those extra C<DELETE> commands can be avoided by using database-level
C<ON DELETE CASCADE> for the references from the B<values> and
B<entity_relationships> tables to the B<entities> table.

The current DBIx::EAV implementation can handle both situations, but defaults
to database-level cascade delete. See L</database_cascade_delete> option.

I'll probably drop support for no database-level cascade delete in the future...
if no one points otherwise.


=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
