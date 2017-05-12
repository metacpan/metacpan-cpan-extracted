package AnyEvent::Subprocess::Running::Delegate::CaptureHandle;
BEGIN {
  $AnyEvent::Subprocess::Running::Delegate::CaptureHandle::VERSION = '1.102912';
}
# ABSTRACT: Running part of the CaptureHandle delegate
use Moose;
use AnyEvent::Subprocess::Done::Delegate::CaptureHandle;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'output' => (
    traits   => ['String'],
    init_arg => undef,
    is       => 'ro',
    isa      => 'Str',
    default  => '',
    handles  => {
        '_append_output' => 'append',
    },
);

sub build_done_delegates {
    my ($self, $running) = @_;

    return AnyEvent::Subprocess::Done::Delegate::CaptureHandle->new(
        name   => $self->name,
        output => $self->output,
    );
}

sub build_events {}
sub completion_hook {}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Running::Delegate::CaptureHandle - Running part of the CaptureHandle delegate

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

