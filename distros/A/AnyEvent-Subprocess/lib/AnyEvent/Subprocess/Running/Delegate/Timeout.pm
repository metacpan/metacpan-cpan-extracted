package AnyEvent::Subprocess::Running::Delegate::Timeout;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::Timeout::VERSION = '1.102912';
}
# ABSTRACT: Running part of Timeout delegate
use Moose;
use namespace::autoclean;
use AnyEvent::Subprocess::Done::Delegate::Timeout;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'timer' => (
    is       => 'ro',
    clearer  => 'clear_timer',
);

has 'killed_by_timer' => (
    init_arg => undef,
    accessor => 'killed_by_timer',
    default  => sub { undef },
);

sub completion_hook {
    my $self = shift;
    $self->clear_timer;
}

sub build_done_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Done::Delegate::Timeout->new(
        name      => $self->name,
        timed_out => $self->killed_by_timer,
    );
}

sub build_events {}
sub build_code_args {}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::Timeout - Running part of Timeout delegate

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

