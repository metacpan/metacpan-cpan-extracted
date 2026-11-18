package API::Docker::Type::HealthConfig;
# ABSTRACT: A test to perform to check that the container is healthy
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker test => [Str];


docker interval => Int;


docker timeout => Int;


docker retries => Int;


docker start_period => Int;


docker start_interval => Int, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::HealthConfig - A test to perform to check that the container is healthy

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<HealthConfig> definition of C<spec/v1.51.yaml>.

Healthcheck commands should be side-effect free.

=head2 test

The test to perform. Possible values are:

=over 4

=item * C<[]> inherit healthcheck from image or parent image

=item * C<["NONE"]> disable healthcheck

=item * C<["CMD", args...]> exec arguments directly

=item * C<["CMD-SHELL", command]> run command with system's default shell

=back

A non-zero exit code indicates a failed healthcheck:

=over 4

=item * C<0> healthy

=item * C<1> unhealthy

=item * C<2> reserved (treated as unhealthy)

=item * other values: error running probe

=back

=head2 interval

The time to wait between checks in nanoseconds. It should be 0 or at least
1000000 (1 ms). 0 means inherit.

=head2 timeout

The time to wait before considering the check to have hung. It should be 0
or at least 1000000 (1 ms). 0 means inherit.

If the health check command does not complete within this timeout, the check
is considered failed and the health check process is forcibly terminated
without a graceful shutdown.

=head2 retries

The number of consecutive failures needed to consider a container as
unhealthy. 0 means inherit.

=head2 start_period

Start period for the container to initialize before starting health-retries
countdown in nanoseconds. It should be 0 or at least 1000000 (1 ms). 0 means
inherit.

=head2 start_interval

The time to wait between checks in nanoseconds during the start period. It
should be 0 or at least 1000000 (1 ms). 0 means inherit.

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
