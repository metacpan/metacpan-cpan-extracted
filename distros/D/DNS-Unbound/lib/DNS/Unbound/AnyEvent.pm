package DNS::Unbound::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound::AnyEvent - L<DNS::Unbound> for L<AnyEvent>

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar();

    my $unbound = DNS::Unbound::AnyEvent->new();

    $unbound->resolve_async("perl.org", "A")->then(
        sub {
            my $result = shift;

            # ...
        }
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This class provides native L<AnyEvent> compatibility for L<DNS::Unbound>.

=cut

# This class does NOT need to be an FDFHStorer because AnyEvent
# works with FDs without needing to create Perl filehandles out of them.
use parent 'DNS::Unbound::EventLoopBase';

use AnyEvent ();

# perl -MData::Dumper -MAnyEvent -e'use DNS::Unbound::AnyEvent; my $cv = AnyEvent->condvar(); DNS::Unbound::AnyEvent->new()->resolve_async("perl.org", "A")->then( sub { print Dumper shift } )->finally($cv); $cv->recv()'

my %INSTANCE_WATCHER;

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $INSTANCE_WATCHER{$self} = AnyEvent->io(
        fh => $self->fd(),
        poll => 'r',
        cb => $self->_create_process_cr(),
    );

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    delete $INSTANCE_WATCHER{$self};

    $self->SUPER::DESTROY();
}

1;
