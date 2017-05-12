package Class::DBI::Plugin::Iterator::mysql4;
use strict;
use base qw/Class::DBI::Plugin::Iterator/;

sub count {
    my $self = shift;
    return $self->{_count} if defined $self->{_count};

    my $sql = $self->sql;
    $sql =~ s/SELECT(?:\s+(ALL|DISTINCT|DISTINCTROW))?\s+/SELECT $1 SQL_CALC_FOUND_ROWS /;
    $sql .= ' LIMIT 1';

    my $dbh = $self->class->db_Main;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@{$self->{_args}});
    $sth->finish;

    my $sth_rows = $dbh->prepare('SELECT FOUND_ROWS()');
    $sth_rows->execute;
    $self->{_count} = $sth_rows->fetch->[0];
    $sth_rows->finish;

    $self->{_count};
}

1;
