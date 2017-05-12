package AnyEvent::Subprocess::Running::Delegate::MonitorHandle;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::MonitorHandle::VERSION = '1.102912';
}
# ABSTRACT: Running part of the MonitorHandle delegate
use Moose;
use namespace::clean;

with 'AnyEvent::Subprocess::Running::Delegate';

has '_job_delegate' => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Job::Delegate::MonitorHandle',
    handles  => ['_run_callbacks'],
    required => 1,
);

sub build_events {}
sub build_done_delegates {}

sub completion_hook {
    my ($self, $running, $args) = @_;

    my $leftover =
      delete $args->{run}->delegate($self->_job_delegate->handle)->handle->{rbuf};

    $self->_run_callbacks( $leftover ) if $leftover;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::MonitorHandle - Running part of the MonitorHandle delegate

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

