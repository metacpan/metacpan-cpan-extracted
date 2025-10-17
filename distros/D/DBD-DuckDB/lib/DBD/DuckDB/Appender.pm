package DBD::DuckDB::Appender;

use strict;
use warnings;

use DBD::DuckDB::FFI       qw(:all);
use DBD::DuckDB::Constants qw(:all);

my %DUCKDB_APPEND_VALUE = (
    DUCKDB_TYPE_BIGINT()    => \&duckdb_append_int64,
    DUCKDB_TYPE_BOOLEAN()   => \&duckdb_append_bool,
    DUCKDB_TYPE_DATE()      => \&duckdb_append_date,
    DUCKDB_TYPE_DOUBLE()    => \&duckdb_append_double,
    DUCKDB_TYPE_FLOAT()     => \&duckdb_append_float,
    DUCKDB_TYPE_HUGEINT()   => \&duckdb_append_hugeint,
    DUCKDB_TYPE_INTEGER()   => \&duckdb_append_int32,
    DUCKDB_TYPE_INTERVAL()  => \&duckdb_append_interval,
    DUCKDB_TYPE_SMALLINT()  => \&duckdb_append_int16,
    DUCKDB_TYPE_TIME()      => \&duckdb_append_time,
    DUCKDB_TYPE_TIMESTAMP() => \&duckdb_append_timestamp,
    DUCKDB_TYPE_TINYINT()   => \&duckdb_append_int8,
    DUCKDB_TYPE_UBIGINT()   => \&duckdb_append_uint64,
    DUCKDB_TYPE_UHUGEINT()  => \&duckdb_append_uhugeint,
    DUCKDB_TYPE_UINTEGER()  => \&duckdb_append_uint32,
    DUCKDB_TYPE_USMALLINT() => \&duckdb_append_uint16,
    DUCKDB_TYPE_UTINYINT()  => \&duckdb_append_uint8,
    DUCKDB_TYPE_VARCHAR()   => \&duckdb_append_varchar,
);

sub new {

    my ($class, %params) = @_;

    my $dbh    = delete $params{dbh}   or Carp::croak 'Missing DB handler';
    my $table  = delete $params{table} or Carp::croak 'Missing appender table';
    my $schema = delete $params{schema} // 'main';

    my $rc = duckdb_appender_create($dbh->{duckdb_conn}, $schema, $table, \my $appender);
    return $dbh->set_err(1, "duckdb_appender_create failed for '$schema.$table'") if $rc;

    my $name    = $dbh->quote_identifier($schema, $table);
    my $columns = [];

    my $sth = $dbh->prepare("PRAGMA table_info($name)");
    $sth->execute;

    my $rows = $sth->fetchall_arrayref;
    @$columns = map { $_->[1] } @$rows if $rows;

    my $self = {dbh => $dbh, appender => $appender, table => $table, schema => $schema, columns => $columns};

    return bless $self, $class;
}

sub error { duckdb_appender_error(shift->{appender}) }

sub append {

    my ($self, $value, $type) = @_;

    return $self->{dbh}->set_err(1, 'appender flushed') if $self->{closed};

    unless (defined $value) {
        return duckdb_append_null($self->{appender});
    }

    if ($type == DUCKDB_TYPE_BLOB) {
        return duckdb_append_blob($value, length($value));
    }

    if (defined $DUCKDB_APPEND_VALUE{$type}) {
        return $DUCKDB_APPEND_VALUE{$type}->($self->{appender}, $value);
    }

}

sub _guess_type {

    my $value = shift;

    return DUCKDB_TYPE_INTEGER if defined $value && $value =~ /^-?\d+\z/;
    return DUCKDB_TYPE_DOUBLE  if defined $value && $value =~ /^-?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?\z/;
    return DUCKDB_TYPE_BOOLEAN if defined $value && $value =~ /^(?:true|false|0|1)\z/i;
    return DUCKDB_TYPE_VARCHAR;

}

sub append_row {

    my ($self, %data) = @_;

    my $cols = $self->{columns} // [];
    $self->begin_row or return;

    for my $col (@$cols) {
        my $value = $data{$col};
        my $type  = _guess_type($value);
        $self->append($value, $type);
    }

    $self->end_row;

}

sub begin_row {

    my $self = shift;
    my $rc   = duckdb_appender_begin_row($self->{appender});

    if ($rc) {
        return $self->{dbh}->set_err(1, $self->error // 'duckdb_appender_begin_row failed');
    }

    return 1;

}

sub end_row {

    my $self = shift;
    my $rc   = duckdb_appender_end_row($self->{appender});

    if ($rc) {
        return $self->{dbh}->set_err(1, $self->error // 'duckdb_appender_end_row failed');
    }

    return 1;

}

sub flush {

    my $self = shift;
    my $rc   = duckdb_appender_flush($self->{appender});

    if ($rc) {
        return $self->{dbh}->set_err(1, $self->error // 'duckdb_appender_flush failed');
    }

    return 1;

}

sub close {

    my $self = shift;
    my $rc   = duckdb_appender_close($self->{appender});

    if ($rc) {
        return $self->{dbh}->set_err(1, $self->error // 'duckdb_appender_close failed');
    }

    return 1;

}

sub destroy {

    my $self = shift;
    my $rc   = duckdb_appender_destroy(\$self->{appender});

    if ($rc) {
        return $self->{dbh}->set_err(1, $self->error // 'duckdb_appender_destroy failed');
    }

    $self->{closed} = 1;

    return 1;

}

sub DESTROY {
    my $self = shift;
    $self->destroy unless $self->{closed};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::DuckDB::Appender - Appender helper for DuckDB

    use DBI;
    use DBD::DuckDB::Constants qw(:duckdb_types);

    my $dbh = DBI->connect("dbi:DuckDB:dbname=$dbname");

    my $appender = $dbh->x_duckdb_appender('people');

    $appender->append(1,            DUCKDB_TYPE_INTEGER);
    $appender->append('Larry Wall', DUCKDB_TYPE_VARCHAR);
    $appender->end_row;

    $appender->append_row(id => 1, name => 'Larry Wall');

=head1 DESCRIPTION

Appenders are the most efficient way of loading data into DuckDB from within 
the C interface, and are recommended for fast data loading. The appender is 
much faster than using prepared statements or individual INSERT INTO statements.

=head1 METHODS

=head3 B<append>

    $appender->append($value, $type);

Append a single column.

=head3 B<append_row>

    $appender->append_row(%row_data);

Append a single row.

=head3 B<error>

    my $err = $appender->error;

Returns the error message associated with the appender. If the appender has no error
message, this returns undef instead.

=head3 B<destroy>

    my $rc = $appender->destroy;

Closes the appender by flushing all intermediate states to the table and 
destroying it. By destroying it, this function de-allocates all memory 
associated with the appender. If flushing the data triggers a constraint 
violation, then all data is invalidated, and this function returns error.

=head3 B<flush>

    my $rc = $appender->flush;

Flush the appender to the table, forcing the cache of the appender to be 
cleared. If flushing the data triggers a constraint violation or any other 
error, then all data is invalidated, and this function returns error. It 
is not possible to append more values.

=head3 B<close>

    my $rc = $appender->close;

Closes the appender by flushing all intermediate states and closing it for 
further appends. If flushing the data triggers a constraint violation or any 
other error, then all data is invalidated, and this function returns error.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-DBD-DuckDB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-DBD-DuckDB>

    git clone https://github.com/giterlizzi/perl-DBD-DuckDB.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
