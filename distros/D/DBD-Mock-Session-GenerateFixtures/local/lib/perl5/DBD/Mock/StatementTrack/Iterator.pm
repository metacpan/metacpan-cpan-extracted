package DBD::Mock::StatementTrack::Iterator;

use strict;
use warnings;

sub new {
    my ( $class, $history ) = @_;
    bless {
        pointer => 0,
        history => $history || []
    } => $class;
}

sub next {
    my ($self) = @_;
    return unless $self->{pointer} < scalar( @{ $self->{history} } );
    return $self->{history}->[ $self->{pointer}++ ];
}

sub reset { (shift)->{pointer} = 0 }

1;
