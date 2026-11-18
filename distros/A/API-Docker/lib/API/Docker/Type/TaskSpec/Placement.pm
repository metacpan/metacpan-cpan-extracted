package API::Docker::Type::TaskSpec::Placement;
# ABSTRACT: Where in the swarm a task may be scheduled
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Platform;
use API::Docker::Type::TaskSpec::Placement::Preference;
use namespace::clean;


docker constraints => [Str];


docker preferences => [ 'TaskSpec::Placement::Preference' ];


docker max_replicas => Int;


docker platforms => [ 'Platform' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::Placement - Where in the swarm a task may be scheduled

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Placement> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Hard
constraints, soft preferences, the platforms the task can run on, and a cap
on how many replicas one node may take.

=head2 constraints

An array of constraint expressions to limit the set of nodes where a task
can be scheduled. Constraint expressions can either use a I<match> (C<==>)
or I<exclude> (C<!=>) rule. Multiple constraints find nodes that satisfy
every expression (AND match). Constraints can match node or Docker Engine
labels as follows:

node attribute | matches | example
---------------------|--------------------------------|-----------------------------------------------
C<node.id> | Node ID | C<node.id==2ivku8v2gvtg4> C<node.hostname> | Node
hostname | C<node.hostname!=node-2> C<node.role> | Node role
(C<manager>/C<worker>) | C<node.role==manager> C<node.platform.os> | Node
operating system | C<node.platform.os==windows> C<node.platform.arch> | Node
architecture | C<node.platform.arch==x86_64> C<node.labels> | User-defined
node labels | C<node.labels.security==high> C<engine.labels> | Docker
Engine's labels | C<engine.labels.operatingsystem==ubuntu-24.04>

C<engine.labels> apply to Docker Engine labels like operating system,
drivers, etc. Swarm administrators add C<node.labels> for operational
purposes by using the [C<node update endpoint>](#operation/NodeUpdate).

=head2 preferences

Preferences provide a way to make the scheduler aware of factors such as
topology. They are provided in order from highest to lowest precedence. See
L<API::Docker::Type::TaskSpec::Placement::Preference>.

=head2 max_replicas

Maximum number of replicas for per node (default value is 0, which is
unlimited).

=head2 platforms

Platforms stores all the platforms that the service's image can run on. This
field is used in the platform filter for scheduling. If empty, then the
platform filter is off, meaning there are no scheduling restrictions. See
L<API::Docker::Type::Platform>.

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
