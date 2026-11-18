package API::Docker::Type::ServiceSpec::Mode;
# ABSTRACT: Scheduling mode for the service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ServiceSpec::Mode::Replicated;
use API::Docker::Type::ServiceSpec::Mode::ReplicatedJob;
use namespace::clean;


docker replicated => 'ServiceSpec::Mode::Replicated';


docker global => Any;


docker replicated_job => 'ServiceSpec::Mode::ReplicatedJob';


docker global_job => Any;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ServiceSpec::Mode - Scheduling mode for the service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Mode> schema of the C<ServiceSpec> definition in
C<spec/v1.51.yaml>.

=head2 replicated

Undocumented upstream. The mode for a service with a fixed number of tasks;
the count is L<API::Docker::Type::ServiceSpec::Mode::Replicated/replicas>,
and the swagger's C<Service> example carries C<< {"Replicated": {"Replicas":
1}} >>. Of the four modes only C<ReplicatedJob> and C<GlobalJob> are
described upstream. See L<API::Docker::Type::ServiceSpec::Mode::Replicated>.

=head2 global

Undocumented upstream. One task on every valid node: the same reach the
swagger gives C<GlobalJob>, which it describes as running a task to the
completed state on each valid node, without the running-to-completion part.
An empty object -- naming the mode is the whole of it.

=head2 replicated_job

The mode used for services with a finite number of tasks that run to a
completed state. See L<API::Docker::Type::ServiceSpec::Mode::ReplicatedJob>.

=head2 global_job

The mode used for services which run a task to the completed state on each
valid node.

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
