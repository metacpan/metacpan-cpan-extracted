package AnyEvent::Subprocess::Job::Delegate;
BEGIN {
  $AnyEvent::Subprocess::Job::Delegate::VERSION = '1.102912';
}
# ABSTRACT: role that delegates on the Job class must implement
use Moose::Role;

with 'AnyEvent::Subprocess::Delegate';

requires 'build_run_delegates';
requires 'child_setup_hook';
requires 'child_finalize_hook';
requires 'parent_setup_hook';
requires 'parent_finalize_hook';
requires 'build_code_args';
requires 'receive_child_result';
requires 'receive_child_error';

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Job::Delegate - role that delegates on the Job class must implement

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
