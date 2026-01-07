package Async::Redis::Transaction;

use strict;
use warnings;
use 5.018;

use Future::AsyncAwait;

sub new {
    my ($class, %args) = @_;
    return bless {
        redis    => $args{redis},
        commands => [],
    }, $class;
}

# Queue a command for execution in the transaction
# Returns a placeholder (the actual result comes from EXEC)
sub _queue_command {
    my ($self, $cmd, @args) = @_;
    push @{$self->{commands}}, [$cmd, @args];
    return scalar(@{$self->{commands}}) - 1;  # index of this command
}

# Generate AUTOLOAD to capture any command call
our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $cmd = $AUTOLOAD;
    $cmd =~ s/.*:://;
    return if $cmd eq 'DESTROY';

    # Queue the command
    $self->_queue_command(uc($cmd), @_);
    return;  # Transaction commands don't return Futures individually
}

# Allow explicit command() calls too
sub command {
    my ($self, $cmd, @args) = @_;
    $self->_queue_command($cmd, @args);
    return;
}

sub commands { @{shift->{commands}} }

1;

__END__

=head1 NAME

Async::Redis::Transaction - Transaction command collector

=head1 DESCRIPTION

This class collects commands during a transaction callback. Commands
are queued locally and then sent as MULTI/commands.../EXEC.

=cut
