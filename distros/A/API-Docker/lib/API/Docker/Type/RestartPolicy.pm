package API::Docker::Type::RestartPolicy;
# ABSTRACT: The behavior to apply when the container exits
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str,
  enum => [ '', 'no', 'always', 'unless-stopped', 'on-failure' ];


docker maximum_retry_count => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::RestartPolicy - The behavior to apply when the container exits

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<RestartPolicy> definition of C<spec/v1.51.yaml>.

The default is not to restart.

An ever increasing delay (double the previous delay, starting at 100ms) is
added before each restart to prevent flooding the server.

=head2 name

=over 4

=item * Empty string means not to restart

=item * C<no> Do not automatically restart

=item * C<always> Always restart

=item * C<unless-stopped> Restart always except when the user has manually
stopped the container

=item * C<on-failure> Restart only when the container exit code is non-zero

=back

=head2 maximum_retry_count

If C<on-failure> is used, the number of times to retry before giving up.

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
