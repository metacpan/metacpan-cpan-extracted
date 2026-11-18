package API::Docker::Type::Health;
# ABSTRACT: Information about the container's healthcheck results
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::HealthcheckResult;
use namespace::clean;


docker status => Str, enum => [qw( none starting healthy unhealthy )];


docker failing_streak => Int;


docker log => [ 'HealthcheckResult' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Health - Information about the container's healthcheck results

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Health> definition of C<spec/v1.51.yaml>.

=head2 status

Status is one of C<none>, C<starting>, C<healthy> or C<unhealthy>

=over 4

=item * "none" Indicates there is no healthcheck

=item * "starting" Starting indicates that the container is not yet ready

=item * "healthy" Healthy indicates that the container is running correctly

=item * "unhealthy" Unhealthy indicates that the container has a problem

=back

=head2 failing_streak

FailingStreak is the number of consecutive failures.

=head2 log

Log contains the last few results (oldest first). See
L<API::Docker::Type::HealthcheckResult>.

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
