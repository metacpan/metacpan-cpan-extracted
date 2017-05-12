package # hide from PAUSE
    MyTask;

use AnyEvent::Task::Logger;

sub new {
    my ($class) = @_;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub times7 {
    my ($self, $arg) = @_;

    logger->info("Hello from PID $$");

    select undef,undef,undef,1; # sleep for a second to demonstrate blocking

    return $arg * 7;
}

1;
