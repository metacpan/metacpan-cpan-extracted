package API::Docker::Type::EventMessage;
# ABSTRACT: The information an event contains
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EventActor;
use namespace::clean;


docker type => Str,
  enum => [qw(
    builder config container daemon image network node plugin secret service
    volume
  )];


docker action => Str;


docker actor => 'EventActor';


docker scope => Str, wire => 'scope', enum => [qw( local swarm )];


docker time => Int, wire => 'time';


docker time_nano => Int, wire => 'timeNano';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EventMessage - The information an event contains

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EventMessage> definition of C<spec/v1.51.yaml>.

=head2 type

The type of object emitting the event. The swagger enumerates C<builder>,
C<config>, C<container>, C<daemon>, C<image>, C<network>, C<node>,
C<plugin>, C<secret>, C<service> and C<volume>.

=head2 action

The type of event.

=head2 actor

Actor describes something that generates events, like a container, network,
or a volume. See L<API::Docker::Type::EventActor>.

=head2 scope

Scope of the event. Engine events are C<local> scope. Cluster (Swarm) events
are C<swarm> scope. Serialised as C<scope> -- spelled out, because deriving
it from the Perl name would produce C<Scope>.

=head2 time

Timestamp of event. Serialised as C<time> -- spelled out, because deriving
it from the Perl name would produce C<Time>.

=head2 time_nano

Timestamp of event, with nanosecond accuracy. Serialised as C<timeNano> --
spelled out, because deriving it from the Perl name would produce
C<TimeNano>.

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
