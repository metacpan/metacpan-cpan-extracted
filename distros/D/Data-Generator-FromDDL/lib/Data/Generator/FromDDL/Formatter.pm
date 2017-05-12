package Data::Generator::FromDDL::Formatter;
use strict;
use warnings;
use Carp qw(croak);
use JSON ();
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(format pretty bytes_per_sql)],
);

sub to_string {
    my ($self, $table, $fields, $rows) = @_;

    my $formatter = do {
        if ($self->format =~ /sql/i) {
            'to_sql';
        } elsif ($self->format =~ /json/i) {
            'to_json';
        } else {
            croak("Unsupported format: " . $self->format . "\n");
        }
    };

    $self->$formatter($table, $fields, $rows);
}

sub to_sql {
    my ($self, $table, $fields, $rows) = @_;

    my $insert_stmt;
    my $record_sep;
    if ($self->pretty) {
        $insert_stmt = "INSERT IGNORE INTO\n    `%s` (%s)\nVALUES\n    ";
        $record_sep = ",\n    ";
    } else {
        $insert_stmt = 'INSERT IGNORE INTO `%s` (%s) VALUES ';
        $record_sep = ',';
    }

    my $columns = join ',', map { '`' . $_->name . '`' } @$fields;
    $insert_stmt = sprintf $insert_stmt, $table->name, $columns;

    my $sqls = '';
    my @values;
    my $sum_bytes = bytes::length($insert_stmt) + 1; # +1 is for trailing semicolon of sql
    my $record_sep_len = bytes::length($record_sep);
    my $bytes_per_sql = $self->bytes_per_sql;
    for my $row (@$rows) {
        my $value = '(' . join(',', @$row) . ')';
        my $v_len = bytes::length($value);
        if ($sum_bytes + $v_len + $record_sep_len > $bytes_per_sql) {
            if (@values) {
                $sqls .= $insert_stmt . (join $record_sep, @values) . ";\n";
                $sum_bytes = bytes::length($insert_stmt) + 1;
                @values = ();
            }
        }
        push @values, $value;
        $sum_bytes += $v_len + $record_sep_len;
    }

    if (@values) {
        $sqls .= $insert_stmt . (join $record_sep, @values) . ';';
    }
    return $sqls;
}

sub to_json {
    my ($self, $table, $fields, $rows) = @_;
    my $json = do {
        if ($self->pretty) {
            JSON->new->pretty;
        } else {
            JSON->new;
        }
    };

    return $json->encode({
        table => $table->name,
        fields => [ map { $_->name } @$fields ],
        values => $rows,
    });
}

1;
