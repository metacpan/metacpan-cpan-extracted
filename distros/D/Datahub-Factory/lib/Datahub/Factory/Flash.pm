package Datahub::Factory::Flash;

use Datahub::Factory::Sane;

use Moo::Role;
use MooX::Aliases;
use namespace::clean;
use Term::ANSIColor qw(:constants);

has verbose => ( is => 'rw' );

sub info {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say YELLOW, $msg;
    }
}

sub error {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say BRIGHT_RED, "\x{2716} - $msg";
    }
}

sub success {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say BRIGHT_GREEN, "\x{2714} - $msg";
    }
}

1;

__END__
