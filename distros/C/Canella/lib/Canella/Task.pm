package Canella::Task;
use Moo;
use Canella 'CTX';

has code => (
    is => 'ro',
    required => 1,
);

has name => (
    is => 'ro',
    required => 1,
);

has description => (
    is => 'rw',
);

sub add_guard;

sub execute {
    my $self = shift;

    CTX->stash(current_task => $self);

    my %guards;
    no warnings 'redefine';
    local *add_guard = sub {
        $guards{$_[1]} = $_[2];
    };

    eval {
        $self->code->(@_);
    };
    my $E = $@;

    foreach my $guard (values %guards) {
        if (! $guard->should_fire($self)) {
            $guard->cancel;
        }
    }

    # Make sure to fire the guard objects here
    undef %guards;
    die $E if $E;
}

1;
