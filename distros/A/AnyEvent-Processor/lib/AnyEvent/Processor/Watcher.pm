package AnyEvent::Processor::Watcher;
# ABSTRACT: A watcher echoing a process messages, base class
$AnyEvent::Processor::Watcher::VERSION = '0.006';
use Moose;
use AnyEvent;


has delay   => ( is => 'rw', isa => 'Int', default => 1 );

has action  => ( is => 'rw', does => 'AnyEvent::Processor::WatchableTask' );

has stopped => ( is => 'rw', isa => 'Int', default => 0 );

has wait => ( is => 'rw' );


sub start {
    my $self = shift;

    $self->action->start_message(),
    $self->wait( AnyEvent->timer(
        after => $self->delay,
        interval => $self->delay,
        cb    => sub {
            $self->action()->process_message(),
        },
    ) );
}


sub stop {
    my $self = shift;
    $self->action->end_message();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Processor::Watcher - A watcher echoing a process messages, base class

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 delay

Delay between cal to L<action> process_message call

=head2 action

L<AnyEvent::Processor::WatchableTask> class to call.

=head1 METHODS

=head2 start

=head2 stop

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
