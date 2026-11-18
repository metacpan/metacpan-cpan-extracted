package API::Docker::Type::ServiceSpec::RollbackConfig;
# ABSTRACT: Specification for the rollback strategy of the service
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker parallelism => Int;


docker delay => Int;


docker failure_action => Str, enum => [qw( continue pause )];


docker monitor => Int;


docker max_failure_ratio => Num;


docker order => Str, enum => [qw( stop-first start-first )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ServiceSpec::RollbackConfig - Specification for the rollback strategy of the service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<RollbackConfig> schema of the C<ServiceSpec>
definition in C<spec/v1.51.yaml>.

=head2 parallelism

Maximum number of tasks to be rolled back in one iteration (0 means
unlimited parallelism).

=head2 delay

Amount of time between rollback iterations, in nanoseconds.

=head2 failure_action

Action to take if an rolled back task fails to run, or stops running during
the rollback. The swagger enumerates C<continue> and C<pause>.

=head2 monitor

Amount of time to monitor each rolled back task for failures, in
nanoseconds.

=head2 max_failure_ratio

The fraction of tasks that may fail during a rollback before the failure
action is invoked, specified as a floating point number between 0 and 1. The
daemon defaults it to 0.

=head2 order

The order of operations when rolling back a task. Either the old task is
shut down before the new task is started, or the new task is started before
the old task is shut down. The swagger enumerates C<stop-first> and
C<start-first>.

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
