package AnyEvent::Subprocess::Running::Delegate::CompletionCondvar;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::CompletionCondvar::VERSION = '1.102912';
}
# ABSTRACT: Running part of the CompletionCondvar delegate
use Moose;
use AnyEvent;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'condvar' => (
    is       => 'ro',
    isa      => 'AnyEvent::CondVar',
    default  => sub { AnyEvent->condvar },
    handles  => [qw[send recv]],
    required => 1,
);

sub completion_hook {
    my ($self, $running, $args) = @_;
    $self->send($args->{done});
}

sub build_events {}
sub build_done_delegates {}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::CompletionCondvar - Running part of the CompletionCondvar delegate

=head1 VERSION

version 1.102912

=head1 ATTRIBUTES

=head2 condvar

An L<AnyEvent::Condvar> that is invoked with the C<Done> instance when
the process exits.

=head3 send

=head3 recv

These methods are delegated from the condvar to this class, to save a
bit of typing.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

