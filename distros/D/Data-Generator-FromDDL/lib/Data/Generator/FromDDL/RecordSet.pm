package Data::Generator::FromDDL::RecordSet;
# Data::Generator::FromDDL::RecordSet is columnar-oriented storage.
# To output each generated record, it's needed to convert columns into rows.

use strict;
use warnings;
use POSIX qw(ceil);
use List::Util qw(first);
use Compress::Zlib qw(compress uncompress);
use bytes ();
use Class::Accessor::Lite (
    rw => [qw(table n columns)],
);

use constant RECORDS_PER_CHUNK => 100_000;

sub new {
    my ($class, $table, $n) = @_;
    return bless {
        table => $table,
        n => $n,
        columns => [],
    }, $class;
}

sub set_column_values {
    my ($self, $field, $values) = @_;

    my $n = $self->n;
    my $offset = 0;
    my $size;
    my @chunks;
    while ($n > 0) {
        $size = $n >= RECORDS_PER_CHUNK ? RECORDS_PER_CHUNK : $n;
        my @sliced_values = @$values[$offset..($offset + $size - 1)];
        push @chunks, _store_values_into_chunk(\@sliced_values);

        $n -= $size;
        $offset += $size;
    }

    push @{$self->{columns}}, {
        field => $field,
        chunks => \@chunks,
    };
}

sub get_column_values {
    my ($self, $field_name) = @_;
    my $col = first { $_->{field}->name eq $field_name } @{$self->columns};
    if ($col) {
        return map { _fetch_values_from_chunk($_) } @{$col->{chunks}};
    } else {
        return;
    }
}

sub _store_values_into_chunk {
    my ($values) = @_;
    return compress(join ',', @$values);
}

sub _fetch_values_from_chunk {
    my ($chunk) = @_;
    my $joined_chunk = uncompress($chunk);
    return split ',', $joined_chunk;
}

sub iterate_through_chunks(&) {
    my ($self, $code) = @_;
    my $columns = $self->columns;
    my $num_of_chunks = ceil($self->n / RECORDS_PER_CHUNK);

    my $table = $self->table;
    my @fields = map { $_->{field} } @{$self->columns};
    for my $chunk_no (0..($num_of_chunks - 1)) {
        my @rows = $self->_construct_rows_with_chunk_no($chunk_no);
        $code->($table, \@fields, \@rows);
    }
}

sub _construct_rows_with_chunk_no {
    my ($self, $chunk_no) = @_;
    my $n = $self->n;
    my $columns = $self->columns;
    my $chunk_size
        = ($n - ($chunk_no * RECORDS_PER_CHUNK)) >= RECORDS_PER_CHUNK
        ? RECORDS_PER_CHUNK
        : $n % RECORDS_PER_CHUNK
        ;
    my @all_columns_values
        = map {
            my @values = _fetch_values_from_chunk($_->{chunks}->[$chunk_no]);
            \@values;
        } @$columns;

    my @rows;
    my $last_idx_of_columns = scalar(@$columns) - 1;
    for my $row_idx (0..($chunk_size - 1)) {
        my @row;
        for my $col_idx (0..$last_idx_of_columns) {
            $row[$col_idx] = $all_columns_values[$col_idx]->[$row_idx];
        }
        push @rows, \@row;
    }

    return @rows;
}

1;
