package AnyEvent::Subprocess::Job::Delegate::CompletionCondvar;
BEGIN {
  $AnyEvent::Subprocess::Job::Delegate::CompletionCondvar::VERSION = '1.102912';
}
# ABSTRACT: provide a condvar to indicate completion
use AnyEvent::Subprocess::Running::Delegate::CompletionCondvar;
use Moose;

with 'AnyEvent::Subprocess::Job::Delegate';

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::CompletionCondvar->new(
          name => $self->name,
      );
}

sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_setup_hook {}
sub parent_finalize_hook {}
sub build_code_args {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AnyEvent::Subprocess::Job::Delegate::CompletionCondvar - provide a condvar to indicate completion

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

