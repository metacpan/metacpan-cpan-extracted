package Class::DBI::Plugin::Iterator::subquery;
use strict;
use base qw/Class::DBI::Plugin::Iterator/;

sub count {
    my $self = shift;
    return $self->{_count} if defined $self->{_count};
    return $self->SUPER::count if $self->class->iterator_count_type;

    my $sql = sprintf 'SELECT COUNT(*) FROM ( %s ) AS __GROUP_BY__', $self->sql;

    eval {
        my $sth = $self->class->db_Main->prepare($sql);
        $sth->execute(@{$self->{_args}});
        $self->{_count} = $sth->fetch->[0];
        $sth->finish;
    };
    if ($@) {
        $self->class->iterator_count_type('no subquery');
        return $self->SUPER::count;
    }

    $self->{_count};
}

1;
