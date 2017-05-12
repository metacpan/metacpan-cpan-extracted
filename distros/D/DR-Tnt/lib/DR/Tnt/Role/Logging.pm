use utf8;
use strict;
use warnings;

package DR::Tnt::Role::Logging;
use Mouse::Role;

has logger  =>
    is          => 'rw',
    isa         => 'CodeRef',
    default     => sub {
        sub {
            my ($level, $msg) = @_;

            goto $level;

            warning:
            warn:
            error:
                warn "$level: $msg";
                return;

            info:
            debug:
        }
};

sub _log {
    my ($self, $level, $fmt, @arg) = @_;
    return unless $self->logger;
    my $msg;

    if (@arg) {
        $msg = sprintf $fmt, @arg;
    } else {
        $msg = $fmt;
    }

    for ($msg) {
        s/\s*\z/\n/;
    }
    $self->logger->($level, $msg);
}

1;
