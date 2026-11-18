package API::Docker::Type::TaskSpec::ContainerSpec;
# ABSTRACT: Container spec for the service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::TaskSpec::ContainerSpec::Config;
use API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges;
use API::Docker::Type::TaskSpec::ContainerSpec::Secret;
use API::Docker::Type::TaskSpec::ContainerSpec::Ulimit;
use namespace::clean;


docker image => Str;


docker labels => { Str, Str };


docker command => [Str];


docker args => [Str];


docker hostname => Str;


docker env => [Str];


docker dir => Str;


docker user => Str;


docker groups => [Str];


docker privileges => 'TaskSpec::ContainerSpec::Privileges';


docker tty => Bool, wire => 'TTY';


docker open_stdin => Bool;


docker read_only => Bool;


docker mounts => [ 'Mount' ];


docker stop_signal => Str;


docker stop_grace_period => Int;


docker health_check => 'HealthConfig';


docker hosts => [Str];


docker dns_config => 'TaskSpec::ContainerSpec::DNSConfig',
  wire => 'DNSConfig';


docker secrets => [ 'TaskSpec::ContainerSpec::Secret' ];


docker oom_score_adj => Int, since => '1.51';


docker configs => [ 'TaskSpec::ContainerSpec::Config' ];


docker isolation => Str, enum => [ 'default', 'process', 'hyperv', '' ];


docker init => Bool;


docker sysctls => { Str, Str };


docker capability_add => [Str];


docker capability_drop => [Str];


docker ulimits => [ 'TaskSpec::ContainerSpec::Ulimit' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec - Container spec for the service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<ContainerSpec> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=head2 image

The image name to use for the container.

=head2 labels

User-defined key/value data. B<The keys are the caller's data> and are never
translated.

=head2 command

The command to be run in the image.

=head2 args

Arguments to the command.

=head2 hostname

The hostname to use for the container, as a valid L<RFC
1123|https://tools.ietf.org/html/rfc1123> hostname.

=head2 env

A list of environment variables in the form C<VAR=value>.

=head2 dir

The working directory for commands to run in.

=head2 user

The user inside the container.

=head2 groups

A list of additional groups that the container process will run as.

=head2 privileges

Security options for the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges>.

=head2 tty

Whether a pseudo-TTY should be allocated. Serialised as C<TTY> -- spelled
out, because deriving it from the Perl name would produce C<Tty>.

=head2 open_stdin

Open C<stdin>.

=head2 read_only

Mount the container's root filesystem as read only.

=head2 mounts

Specification for mounts to be added to containers created as part of the
service. See L<API::Docker::Type::Mount>.

=head2 stop_signal

Signal to stop the container.

=head2 stop_grace_period

Amount of time to wait for the container to terminate before forcefully
killing it.

=head2 health_check

A test to perform to check that the container is healthy. See
L<API::Docker::Type::HealthConfig>.

=head2 hosts

A list of hostname/IP mappings to add to the container's C<hosts> file. The
format of extra hosts is specified in the
L<hosts(5)|http://man7.org/linux/man-pages/man5/hosts.5.html> man page:

IP_address canonical_hostname [aliases...].

=head2 dns_config

Specification for DNS related configurations in resolver configuration file
(C<resolv.conf>). See
L<API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig>. Serialised as
C<DNSConfig> -- spelled out, because deriving it from the Perl name would
produce C<DnsConfig>.

=head2 secrets

Secrets contains references to zero or more secrets that will be exposed to
the service. See L<API::Docker::Type::TaskSpec::ContainerSpec::Secret>.

=head2 oom_score_adj

An integer value containing the score given to the container in order to
tune OOM killer preferences.

=head2 configs

Configs contains references to zero or more configs that will be exposed to
the service. See L<API::Docker::Type::TaskSpec::ContainerSpec::Config>.

=head2 isolation

Isolation technology of the containers running the service. (Windows only).
The swagger enumerates C<default>, C<process>, C<hyperv> and the empty
string.

=head2 init

Run an init inside the container that forwards signals and reaps processes.
This field is omitted if empty, and the default (as configured on the
daemon) is used.

=head2 sysctls

Set kernel namedspaced parameters (sysctls) in the container. The Sysctls
option on services accepts the same sysctls as the are supported on
containers. Note that while the same sysctls are supported, no guarantees or
checks are made about their suitability for a clustered environment, and
it's up to the user to determine whether a given sysctl will work properly
in a Service. B<The keys are the caller's data> and are never translated.

=head2 capability_add

A list of kernel capabilities to add to the default set for the container.

=head2 capability_drop

A list of kernel capabilities to drop from the default set for the
container.

=head2 ulimits

A list of resource limits to set in the container. For example: C<{"Name":
"nofile", "Soft": 1024, "Hard": 2048}>". See
L<API::Docker::Type::TaskSpec::ContainerSpec::Ulimit>.

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
