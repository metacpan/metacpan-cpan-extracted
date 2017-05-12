package AnyEvent::Subprocess::Job::Delegate::PrintError;
BEGIN {
  $AnyEvent::Subprocess::Job::Delegate::PrintError::VERSION = '1.102912';
}
# ABSTRACT: Print errors to a filehandle
use Moose;
use namespace::autoclean;
with 'AnyEvent::Subprocess::Job::Delegate';

has 'handle' => (
    is      => 'ro',
    isa     => 'GlobRef',
    default => sub { \*STDERR },
);

has 'callback' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        my $self = shift;
        return sub {
            my $msg = join '', @_;
            $msg .= "\n" unless $msg =~ /\n$/;
            print {$self->handle} ($msg);
        }
    },
);

sub receive_child_error {
    my ($self, $job, $error) = @_;
    $self->callback->($error);
}

sub build_run_delegates {}
sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_setup_hook {}
sub parent_finalize_hook {}
sub build_code_args {}
sub receive_child_result {}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Job::Delegate::PrintError - Print errors to a filehandle

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

