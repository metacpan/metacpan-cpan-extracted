package App::RunCron::Reporter::Code;
use strict;
use warnings;

sub new {
    my ($class, $code) = @_;
    bless $code, $class;
}

sub run {
    my ($self, $runner) = @_;
    $self->($runner);
}

1;
