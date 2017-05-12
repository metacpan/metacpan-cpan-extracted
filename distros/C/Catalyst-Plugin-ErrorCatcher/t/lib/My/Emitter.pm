package My::Emitter;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

sub new {
    my $proto   = shift;
    my $argref  = shift;
    my $class   = ref($proto) || $proto; 
    my $self    = {
        jason => 'tired',
    };
    bless( $self, $class );

    $argref->{c}->config->{"My::Emitter"}{set_in_new} = 1;
    
    return $self;
}

sub emit {
    my $self    = shift;
    my $c       = shift;
    $c->config->{"My::Emitter"}{set_in_emit} = 1;
}

1;
