package API::Docker::Type::TaskSpec::RestartPolicy;
# ABSTRACT: Specification for the restart policy which applies to containers created as part of this service
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker condition => Str, enum => [qw( none on-failure any )];


docker delay => Int;


docker max_attempts => Int;


docker window => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::RestartPolicy - Specification for the restart policy which applies to containers created as part of this service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<RestartPolicy> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

=head2 condition

Condition for restart. The swagger enumerates C<none>, C<on-failure> and
C<any>.

=head2 delay

Delay between restart attempts.

=head2 max_attempts

Maximum attempts to restart a given container before giving up (default
value is 0, which is ignored).

=head2 window

Windows is the time window used to evaluate the restart policy (default
value is 0, which is unbounded).

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
