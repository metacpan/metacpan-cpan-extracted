package Data::YADV::CheckerASub;

use strict;
use warnings;

use base 'Data::YADV::Checker';

sub new {
    my $class = shift;
    my $cb = shift;

    my $self = $class->SUPER::new(@_);
    $self->{cb} = $cb;

    $self;
}

sub verify {
    my $self = shift;

    $self->{cb}->($self, $self->structure->get_structure, @_);
}

1;
