package
    Other::ProbeRapper;

use Moose;
use Assert::Conditional qw(:all);

extends "Some::TestRapper";
with "Alien::Snatch";

around my_data => sub {
    my($next, $self, @args) = @_;
    #say "another wrapper with has_data"; 
    $self->$next(@args);
} if 0;

sub safe_data {
    my($self, @args) = @_;
    $self->our_data(@args);
}


1;

