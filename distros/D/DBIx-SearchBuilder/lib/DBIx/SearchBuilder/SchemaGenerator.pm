use strict;
use warnings;

package DBIx::SearchBuilder::SchemaGenerator;

use base qw(Class::Accessor);
use DBIx::DBSchema;
use Class::ReturnValue;

# Public accessors
__PACKAGE__->mk_accessors(qw(handle));
# Internal accessors: do not use from outside class
__PACKAGE__->mk_accessors(qw(_db_schema));

=head2 new HANDLE

Creates a new C<DBIx::SearchBuilder::SchemaGenerator> object.  The single
required argument is a C<DBIx::SearchBuilder::Handle>.

=cut

sub new {
    my $class = shift;
    my $handle = shift;
    my $self = $class->SUPER::new();

    $self->handle($handle);

    my $schema = DBIx::DBSchema->new;
    $self->_db_schema($schema);

    return $self;
}

=for public_doc AddModel MODEL

Adds a new model class to the SchemaGenerator.  Model should either be an object
of a subclass of C<DBIx::SearchBuilder::Record>, or the name of such a subclass; in the
latter case, C<AddModel> will instantiate an object of the subclass.

The model must define the instance methods C<Schema> and C<Table>.

Returns true if the model was added successfully; returns a false C<Class::ReturnValue> error
otherwise.

=cut

sub AddModel {
    my $self = shift;
    my $model = shift;

    # $model could either be a (presumably unfilled) object of a subclass of
    # DBIx::SearchBuilder::Record, or it could be the name of such a subclass.

    unless (ref $model and UNIVERSAL::isa($model, 'DBIx::SearchBuilder::Record')) {
        my $new_model;
        eval { $new_model = $model->new; };

        if ($@) {
            return $self->_error("Error making new object from $model: $@");
        }

        return $self->_error("Didn't get a DBIx::SearchBuilder::Record from $model, got $new_model")
            unless UNIVERSAL::isa($new_model, 'DBIx::SearchBuilder::Record');

        $model = $new_model;
    }

    my $table_obj = $self->_DBSchemaTableFromModel($model);

    $self->_db_schema->addtable($table_obj);

    1;
}

=for public_doc CreateTableSQLStatements

Returns a list of SQL statements (as strings) to create tables for all of
the models added to the SchemaGenerator.

=cut

sub CreateTableSQLStatements {
    my $self = shift;
    # The sort here is to make it predictable, so that we can write tests.
    return sort $self->_db_schema->sql($self->handle->dbh);
}

=for public_doc CreateTableSQLText

Returns a string containing a sequence of SQL statements to create tables for
all of the models added to the SchemaGenerator.

=cut

sub CreateTableSQLText {
    my $self = shift;

    return join "\n", map { "$_ ;\n" } $self->CreateTableSQLStatements;
}

=for private_doc _DBSchemaTableFromModel MODEL

Takes an object of a subclass of DBIx::SearchBuilder::Record; returns a new
C<DBIx::DBSchema::Table> object corresponding to the model.

=cut

sub _DBSchemaTableFromModel {
    my $self = shift;
    my $model = shift;

    my $table_name = $model->Table;
    my $schema     = $model->Schema;

    my $primary = "id"; # TODO allow override
    my $primary_col = DBIx::DBSchema::Column->new({
        name => $primary,
        type => 'serial',
        null => 'NOT NULL',
    });

    my @cols = ($primary_col);

    # The sort here is to make it predictable, so that we can write tests.
    for my $field (sort keys %$schema) {
        # Skip foreign keys

        next if defined $schema->{$field}->{'REFERENCES'} and defined $schema->{$field}->{'KEY'};

        # TODO XXX FIXME
        # In lieu of real reference support, make references just integers
        $schema->{$field}{'TYPE'} = 'integer' if $schema->{$field}{'REFERENCES'};

        push @cols, DBIx::DBSchema::Column->new({
            name    => $field,
            type    => $schema->{$field}{'TYPE'},
            null    => 'NULL',
            default => $schema->{$field}{'DEFAULT'},
        });
    }

    my $table = DBIx::DBSchema::Table->new({
        name => $table_name,
        primary_key => $primary,
        columns => \@cols,
    });

    return $table;
}

=for private_doc _error STRING

Takes in a string and returns it as a Class::ReturnValue error object.

=cut

sub _error {
    my $self = shift;
    my $message = shift;

    my $ret = Class::ReturnValue->new;
    $ret->as_error(errno => 1, message => $message);
    return $ret->return_value;
}


1; # Magic true value required at end of module

__END__

=head1 NAME

DBIx::SearchBuilder::SchemaGenerator - Generate table schemas from DBIx::SearchBuilder records

=head1 SYNOPSIS

    use DBIx::SearchBuilder::SchemaGenerator;
