package DBIx::Insert::Multi::Batch;
use Moo;

=head1 NAME

DBIx::Insert::Multi::Batch -- Batch of records to insert

=cut

use Carp;
use autobox::Core;
use autobox::Transform;
use Scalar::Util qw/ blessed /;



has dbh                        => ( is => "ro", required => 1 );
has table                      => ( is => "ro", required => 1 );
has records                    => ( is => "ro", required => 1 );
has insert_sql_fragment        => ( is => "ro", required => 1 );
has is_last_insert_id_required => ( is => "ro", required => 1 );



has column_names => ( is => "lazy" );
sub _build_column_names {
    my $self = shift;
    my $record = $self->records->[0] or return [];
    return $record->keys->order,  # Assume all records are uniform
}

has record_placeholders => ( is => "lazy" );
sub _build_record_placeholders {
    my $self = shift;
    my $record = "    (" . $self->column_names->map(sub { "?" })->join(", ") . ")";
    return $self->records->map(sub { $record })->join(",\n") . "\n";
}

has record_values => ( is => "lazy" );
sub _build_record_values {
    my $self = shift;
    my @columns = $self->column_names->elements;
    return $self->records
        ->map(sub { @{ $_ }{ @columns } })
        ->map(sub { blessed($_) ? "$_" : $_ }); # Stringify objects
}

has sql => ( is => "lazy" );
sub _build_sql {
    my $self = shift;
    $self->column_names->length or return undef;

    my $table = $self->table;
    my $dbh = $self->dbh;
    my $column_names = $self->column_names
        ->map(sub { $dbh->quote_identifier($_) })
        ->join(", ");

    return sprintf(
        "%s %s (%s) VALUES\n%s",
        $self->insert_sql_fragment,
        $dbh->quote_identifier($table),
        $column_names,
        $self->record_placeholders,
    );
}

# For MySQL this is the id of the first of the rows
# For Postgres, this seems to be the id of the last of the rows
sub _get_insert_id {
    my $self = shift;
    my ($dbh) = @_;

    my $last_insert_id = $dbh->last_insert_id(
        undef, undef, $self->table, undef,
    );
    # This will return 0 if any of the inserts failed and you were
    # using ->insert_sql_fragment "INSERT IGNORE INTO".
    if( ! defined $last_insert_id ) {
        if($self->is_last_insert_id_required) {
            croak("No dbh last_insert_id returned");
        }
        return undef;
    }

    return $last_insert_id;
}

=head2 insert() :

Perform the insert into ->table of all the records in ->records.

The return value not specified. If the query fails, die.

=cut

sub insert {
    my $self = shift;
    my $sql = $self->sql or return undef;
    my $dbh = $self->dbh;
    $dbh->do( $sql, {}, $self->record_values->elements )
        or croak( "Could not insert rows: " . $dbh->errstr );
    return $self->_get_insert_id( $dbh );
}

1;
