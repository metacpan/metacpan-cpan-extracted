package Data::Enumerator::Range;
use strict;
use warnings;
use base qw/Data::Enumerator::Base/;

sub new {
    my ( $class, $start, $end, $succ ) = @_;
    return bless {
        start => $start,
        end   => $end,
        succ  => $succ,
    }, $class;
}

sub iterator {
    my ( $self ) = @_;
    my $counter = $self->{start};
    my $end     = $self->{end};
    my $succ    = $self->{succ};
    my $succ_func = (ref $succ) ? $succ : sub{ $_[0]+$succ};
    return sub{
        return $self->LAST if $counter >= $end;
        my $prev = $counter;
        $counter = $succ_func->($counter);
        return $prev;
    };
}
1;
