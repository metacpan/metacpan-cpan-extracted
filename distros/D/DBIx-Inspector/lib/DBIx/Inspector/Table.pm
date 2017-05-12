package DBIx::Inspector::Table;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw/inspector/);
use DBIx::Inspector::Column;
use DBIx::Inspector::ForeignKey::Pg;
use DBIx::Inspector::Iterator::Null;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless {%args}, $class;
}

sub columns {
    my ($self, $column) = @_;
    return $self->inspector->columns($self->name, $column);
}

sub column {
    my ($self, $column) = @_;
    return $self->columns($column)->next;
}

sub primary_key {
    my $self = shift;
    return $self->inspector->primary_key($self->name);
}

sub pk_foreign_keys {
    my ($self, $opt) = @_;

    return $self->inspector->foreign_keys(
        $self->inspector->catalog,
        $self->inspector->schema,
        $self->name,
        $opt->{fk_catalog} || $self->inspector->catalog,
        $opt->{fk_schema}  || $self->inspector->schema,
        $opt->{fk_table},
    );
}

sub fk_foreign_keys {
    my ($self, $opt) = @_;

    return $self->inspector->foreign_keys(
        $opt->{pk_catalog} || $self->inspector->catalog,
        $opt->{pk_schema}  || $self->inspector->schema,
        $opt->{pk_table},
        $self->inspector->catalog,
        $self->inspector->schema,
        $self->name
    );
}

sub name    { $_[0]->{TABLE_NAME} }
sub catalog { $_[0]->{TABLE_CAT} }
sub schema  { $_[0]->{TABLE_SCHEM} }
sub type    { $_[0]->{TABLE_TYPE} }

1;
__END__

=head1 NAME

DBIx::Inspector::Table - table object

=head1 METHODS

=over 4

=item $table->catalog()

=item $table->schema()

=item $table->type()

=item $table->name()

Get each attributes.

=item my @columns = $table->columns();

Get L<DBIx::Inspector::Column> objects.

=item my $column = $table->column($name);

Get L<DBIx::Inspector::Column> object for $name.

=item my @pk = $table->primary_key();

Get L<DBIx::Inspector::Column> objects for primary keys.

=back

=head1 SEE ALSO

L<DBIx::Inspector>

