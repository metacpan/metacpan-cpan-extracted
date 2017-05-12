package Class::DBI::Plugin::Iterator::mysql3;
use strict;
use base qw/Class::DBI::Plugin::Iterator/;

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
