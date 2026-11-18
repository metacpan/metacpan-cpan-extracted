package API::Docker::Type::ImageConfig;
# ABSTRACT: Configuration of the image
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;
use namespace::clean;


docker user => Str;


docker exposed_ports => { Str, Any };


docker env => [Str];


docker cmd => [Str];


docker healthcheck => 'HealthConfig';


docker args_escaped => Bool;


docker volumes => { Str, Any };


docker working_dir => Str;


docker entrypoint => [Str];


docker on_build => [Str];


docker labels => { Str, Str };


docker stop_signal => Str;


docker shell => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageConfig - Configuration of the image

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageConfig> definition of C<spec/v1.51.yaml>.

These fields are used as defaults when starting a container from the image.

=head2 user

The user that commands are run as inside the container.

=head2 exposed_ports

An object mapping ports to an empty object in the form:

C<< {"<port>/<tcp|udp|sctp>": {}} >> B<The keys are the caller's data> and
are never translated.

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

=head2 on_build

C<ONBUILD> metadata that were defined in the image's C<Dockerfile>.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 stop_signal

Signal to stop a container as a string or unsigned integer.

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
