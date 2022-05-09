package Author::Daemon::Log::Basic;

use v5.28;
use warnings;
use strict;
use experimental 'signatures';

sub new ( $class, $message = undef ) {
    my $self = {
        'message'   =>  $message,
        'level'     =>  'INFO',
        'levels'    =>  {
            'CRITICAL' => 0,
            'WARN'     => 1,
            'INFO'     => 2,
            'DEBUG'    => 3
        }
    };
    bless $self, $class;
    return $self;
}

sub simple ( $self, $message ) {
    return Author::Daemon::Log::Basic->new($message);
}

sub message ( $self, $set_message = undef ) {
    if ( defined $set_message ) {
        $self->{'message'} = $set_message;
        return $self;
    }
    return $self->{'message'};
}

sub level ( $self, $set_value = undef ) {
    if ( $set_value && defined $self->{'levels'}->{ uc($set_value) } ) {
        $self->{'level'} = uc($set_value);
        return $self;
    }
    return $self->{'level'};
}

1;
