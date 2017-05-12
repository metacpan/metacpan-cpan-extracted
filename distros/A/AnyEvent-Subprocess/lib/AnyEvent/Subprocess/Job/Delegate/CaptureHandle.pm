package AnyEvent::Subprocess::Job::Delegate::CaptureHandle;
BEGIN {
  $AnyEvent::Subprocess::Job::Delegate::CaptureHandle::VERSION = '1.102912';
}
# ABSTRACT: capture the data that comes in via a handle
use Moose;
use AnyEvent::Subprocess::Running::Delegate::CaptureHandle;

with 'AnyEvent::Subprocess::Job::Delegate';

has 'handle' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::CaptureHandle->new(
        name => $self->name,
    );
}

sub parent_setup_hook {
    my ($self, $job, $run) = @_;

    $run->delegate($self->handle)->handle->on_read( sub {
        my ($handle) = @_;
        my $buf = delete $handle->{rbuf};
        $run->delegate($self->name)->_append_output($buf);
    });
}

sub build_code_args {}
sub child_finalize_hook {}
sub child_setup_hook {}
sub parent_finalize_hook {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Job::Delegate::CaptureHandle - capture the data that comes in via a handle

=head1 VERSION

version 1.102912

=head1 DESCRIPTION

If you have a Handle delegate and just want to save the output
somewhere, use this delegate.  It accepts the name of the delegate,
reads from the handle while the process is running, and makes all the
output available via the Done instance.

=head1 INITARGS

=head2 handle

The name of the handle you want to capture's delegate.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

