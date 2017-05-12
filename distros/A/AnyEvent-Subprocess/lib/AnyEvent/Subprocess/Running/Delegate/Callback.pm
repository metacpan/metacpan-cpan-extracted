package AnyEvent::Subprocess::Running::Delegate::Callback;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::Callback::VERSION = '1.102912';
}
# ABSTRACT: the C<Running> part of the Callback delegate
use Moose;

use AnyEvent::Subprocess::Done::Delegate::State; # name change

with 'AnyEvent::Subprocess::Running::Delegate';

has 'completion_hook' => (
    init_arg => 'completion_hook',
    reader   => '_completion_hook',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);


has 'state' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub { +{} },
);

sub completion_hook {
    my ($self, $running, @args) = @_;
    $self->_completion_hook->($self, @args);
}

sub build_done_delegates {
    my ($self) = @_;
    return AnyEvent::Subprocess::Done::Delegate::State->new(
        name  => $self->name,
        state => $self->state,
    );
}
sub build_events {}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::Callback - the C<Running> part of the Callback delegate

=head1 VERSION

version 1.102912

=head1 DESCRIPTION

Calls the completion hook that was setup in the Job delegate, passes
saved state to the Done delegate.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

