package Class::DBI::Plugin::Iterator::mysql;
use strict;
use base qw/Class::DBI::Plugin::Iterator/;

sub count {
    my $self = shift;
    return $self->{_count} if defined $self->{_count};
    return $self->SUPER::count if $self->class->iterator_count_type;

    my $sql = $self->sql;
    $sql =~ s/SELECT(?:\s+(ALL|DISTINCT|DISTINCTROW))?\s+/SELECT $1 SQL_CALC_FOUND_ROWS /;
    $sql .= ' LIMIT 1';

    my $dbh = $self->class->db_Main;
    eval {
        my $sth = $dbh->prepare($sql);
        $sth->execute(@{$self->{_args}});
        $sth->finish;
    };
    if ($@) {
        $self->class->iterator_count_type('mysql3');
        return $self->SUPER::count;
    }

    my $sth_rows = $dbh->prepare('SELECT FOUND_ROWS()');
    $sth_rows->execute;
    $self->{_count} = $sth_rows->fetch->[0];
    $sth_rows->finish;

    $self->{_count};
}

sub slice {
    my ($self, $start, $end) = @_;
    $end ||= $start;

    my $count = $end - $start + 1;
    $count = 1 if $count < 1;
    $start = 0 if $start < 0;
    my $sql = $self->sql . sprintf ' LIMIT %d, %d', $start, $count;
    my $sth = $self->class->db_Main->prepare($sql);
    $self->class->sth_to_objects($sth, $self->{_args});
}


1;
