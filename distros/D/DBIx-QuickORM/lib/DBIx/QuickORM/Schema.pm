package DBIx::QuickORM::Schema;
use strict;
use warnings;

our $VERSION = '0.000025';

use Carp qw/confess croak/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::Util qw/merge_hash_of_objs column_key/;

use DBIx::QuickORM::Link;

use Object::HashBase qw{
    <name
    +tables
    <created
    <compiled
    <row_class
    +_links
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Schema - Object representing a database schema.

=head1 DESCRIPTION

This object represents a single schema in the database. This includes tables,
indexes, columns, etc.

=head1 SYNOPSIS

In your custom ORM package:

    package My::ORM;
    use strict;
    use warnings;

    use DBIx::QuickORM;

    orm MyORM => sub {
        schema MySchema => sub {
            ...
        };
        ...
    }

In other code:

    use My::ORM qw/orm/;

    my $schema = orm('MyORM')->schema;

=head1 ATTRIBUTES

=over 4

=item name

The name of the schema.

=item tables

Hashref of table name to L<DBIx::QuickORM::Schema::Table> instance.

=item created

Trace string for where the schema was initially defined.

=item compiled

Trace string for where the schema was compiled.

=item row_class

The row class used by default when fetching rows from this schema.

=back

=cut

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    $self->{+ROW_CLASS} //= 'DBIx::QuickORM::Row';

    $self->_resolve_links;

    for my $table ($self->tables) {
        my $autofill = $table->row_class_autofill or next;
        $autofill->define_autorow($table->row_class, $table);
    }
}

=pod

=head1 PUBLIC METHODS

=over 4

=item @tables = $schema->tables()

Get all table objects. Each item is an instance of
L<DBIx::QuickORM::Schema::Table>.

=item $table = $schema->table($name)

Get the table of the specified name. An exception will be thrown if the table
is not defined.

=item $table_or_undef = $schema->maybe_table($table_name)

Get the table with the specified name. Return undef if the table is not
defined.

=cut

sub tables      { values %{$_[0]->{+TABLES}} }
sub table       { $_[0]->{+TABLES}->{$_[1]} or croak "Table '$_[1]' is not defined" }
sub maybe_table { return $_[0]->{+TABLES}->{$_[1]} // undef }

=pod

=item $schema->add_table($table_name, $table_ref)

Add a table to the schema. Requires a table name and an
L<DBIx::QuickORM::Schema::Table> instance.

An exception will be thrown if a table of the given name already exists.

=cut

sub add_table {
    my $self = shift;
    my ($name, $table) = @_;

    croak "Table '$name' already defined" if $self->{+TABLES}->{$name};

    return $self->{+TABLES}->{$name} = $table;
}

=pod

=item $schema3 = $schema->merge($schema2)

Merge 2 schema objects into a single third one.

=cut

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+TABLES}    //= merge_hash_of_objs($self->{+TABLES}, $other->{+TABLES});
    $params{+NAME}      //= $self->{+NAME} if $self->{+NAME};
    $params{+ROW_CLASS} //= $other->{+ROW_CLASS};

    return ref($self)->new(%$self, %$other, %params);
}

=pod

=item $new_schema = $schema->clone(%overrides)

Create a copy of the schema, with any attributes you wish to have changed in
the copy.

=back

=cut

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+TABLES}  //= {map { $_ => $self->{+TABLES}->{$_}->clone } keys %{$self->{+TABLES}}};
    $params{+NAME}    //= $self->{+NAME} if $self->{+NAME};

    return blessed($self)->new(%$self, %params);
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $links = $schema->_links()

Internal accessor that fetches and clears the pending raw link definitions.

=cut

sub _links { delete $_[0]->{+_LINKS} }

=pod

=item $schema->_resolve_links()

Resolve the raw link definitions collected from the schema and its tables into
L<DBIx::QuickORM::Link> objects attached to the relevant tables.

=back

=cut

sub _resolve_links {
    my $self = shift;

    my @links = @{$self->_links // []};
    push @links => @{$_->_links // []} for values %{$self->{+TABLES}};

    for my $link (@links) {
        my ($local_set, $other_set, $debug) = @$link;
        $debug //= 'unknown';

        my ($local_tname, $local_cols, $local_alias) = @$local_set;
        my ($other_tname, $other_cols, $other_alias) = @$other_set;

        my $local_table = $self->{+TABLES}->{$local_tname} or confess "Cannot find table '$local_tname' ($debug)";
        my $other_table = $self->{+TABLES}->{$other_tname} or confess "Cannot find table '$other_tname' ($debug)";

        my $local_unique = $other_table->unique->{column_key(@{$other_cols})} ? 1 : 0;
        my $other_unique = $local_table->unique->{column_key(@{$local_cols})} ? 1 : 0;

        push @{$local_table->links} => DBIx::QuickORM::Link->new(
            local_table   => $local_tname,
            local_columns => $local_cols,
            other_table   => $other_tname,
            other_columns => $other_cols,
            unique        => $local_unique,
            aliases       => [grep { $_ } $local_alias],
            created       => $debug,
        );

        push @{$other_table->links} => DBIx::QuickORM::Link->new(
            local_table   => $other_tname,
            local_columns => $other_cols,
            other_table   => $local_tname,
            other_columns => $local_cols,
            unique        => $other_unique,
            aliases       => [grep { $_ } $other_alias],
            created       => $debug,
        );
    }

    return;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
