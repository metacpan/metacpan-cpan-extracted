package API::Docker::Type::ContainerConfig;
# ABSTRACT: Configuration for a container that is portable between hosts
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;
use namespace::clean;


docker hostname => Str;


docker domainname => Str;


docker user => Str;


docker attach_stdin => Bool;


docker attach_stdout => Bool;


docker attach_stderr => Bool;


docker exposed_ports => { Str, Any };


docker tty => Bool;


docker open_stdin => Bool;


docker stdin_once => Bool;


docker env => [Str];


docker cmd => [Str];


docker healthcheck => 'HealthConfig';


docker args_escaped => Bool;


docker image => Str;


docker volumes => { Str, Any };


docker working_dir => Str;


docker entrypoint => [Str];


docker network_disabled => Bool;


docker mac_address => Str;


docker on_build => [Str];


docker labels => { Str, Str };


docker stop_signal => Str;


docker stop_timeout => Int;


docker shell => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerConfig - Configuration for a container that is portable between hosts

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerConfig> definition of C<spec/v1.51.yaml>.

=head2 hostname

The hostname to use for the container, as a valid RFC 1123 hostname.

=head2 domainname

The domain name to use for the container.

=head2 user

Commands run as this user inside the container. If omitted, commands run as
the user specified in the image the container was started from.

Can be either user-name or UID, and optional group-name or GID, separated by
a colon (C<< <user-name|UID>[<:group-name|GID>] >>).

=head2 attach_stdin

Whether to attach to C<stdin>. The daemon defaults it to false.

=head2 attach_stdout

Whether to attach to C<stdout>. The daemon defaults it to true.

=head2 attach_stderr

Whether to attach to C<stderr>. The daemon defaults it to true.

=head2 exposed_ports

An object mapping ports to an empty object in the form:

C<< {"<port>/<tcp|udp|sctp>": {}} >> B<The keys are the caller's data> and
are never translated.

=head2 tty

Attach standard streams to a TTY, including C<stdin> if it is not closed.
The daemon defaults it to false.

=head2 open_stdin

Open C<stdin> The daemon defaults it to false.

=head2 stdin_once

Close C<stdin> after one attached client disconnects. The daemon defaults it
to false.

=head2 env

A list of environment variables to set inside the container in the form
C<["VAR=value", ...]>. A variable without C<=> is removed from the
environment, rather than to have an empty value.

=head2 cmd

Command to run specified as a string or an array of strings.

=head2 healthcheck

A test to perform to check that the container is healthy. See
L<API::Docker::Type::HealthConfig>.

=head2 args_escaped

Command is already escaped (Windows only). The daemon defaults it to false.

=head2 image

The name (or reference) of the image to use when creating the container, or
which was used when the container was created.

=head2 volumes

An object mapping mount point paths inside the container to empty objects.
B<The keys are the caller's data> and are never translated.

=head2 working_dir

The working directory for commands to run in.

=head2 entrypoint

The entry point for the container as a string or an array of strings.

If the array consists of exactly one empty string (C<[""]>) then the entry
point is reset to system default (i.e., the entry point used by docker when
there is no C<ENTRYPOINT> instruction in the C<Dockerfile>).

=head2 network_disabled

Disable networking for the container.

=head2 mac_address

MAC address of the container.

Deprecated: this field is deprecated in API v1.44 and up. Use
EndpointSettings.MacAddress instead.

=head2 on_build

C<ONBUILD> metadata that were defined in the image's C<Dockerfile>.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 stop_signal

Signal to stop a container as a string or unsigned integer.

=head2 stop_timeout

Timeout to stop a container in seconds. The daemon defaults it to 10.

=head2 shell

Shell for when C<RUN>, C<CMD>, and C<ENTRYPOINT> uses a shell.

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
