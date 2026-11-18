package API::Docker::Type::ServiceSpec::Mode::ReplicatedJob;
# ABSTRACT: The mode used for services with a finite number of tasks that run to a completed state
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker max_concurrent => Int;


docker total_completions => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ServiceSpec::Mode::ReplicatedJob - The mode used for services with a finite number of tasks that run to a completed state

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<ReplicatedJob> schema of C<ServiceSpec.Mode> in
C<spec/v1.51.yaml>.

=head2 max_concurrent

The maximum number of replicas to run simultaneously. The daemon defaults it
to 1.

=head2 total_completions

The total number of replicas desired to reach the Completed state. If unset,
will default to the value of C<MaxConcurrent>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
