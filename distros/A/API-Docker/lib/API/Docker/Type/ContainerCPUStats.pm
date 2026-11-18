package API::Docker::Type::ContainerCPUStats;
# ABSTRACT: CPU related info of the container
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerCPUUsage;
use API::Docker::Type::ContainerThrottlingData;
use namespace::clean;


docker cpu_usage => 'ContainerCPUUsage', wire => 'cpu_usage', since => '1.51';


docker system_cpu_usage => Int, wire => 'system_cpu_usage', since => '1.51';


docker online_cpus => Int, wire => 'online_cpus', since => '1.51';


docker throttling_data => 'ContainerThrottlingData',
  wire => 'throttling_data', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerCPUStats - CPU related info of the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerCPUStats> definition of C<spec/v1.51.yaml>.

=head2 cpu_usage

All CPU stats aggregated since container inception. See
L<API::Docker::Type::ContainerCPUUsage>. Serialised as C<cpu_usage> --
spelled out, because deriving it from the Perl name would produce
C<CpuUsage>.

=head2 system_cpu_usage

System Usage.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<system_cpu_usage> -- spelled out, because deriving it from the Perl
name would produce C<SystemCpuUsage>.

=head2 online_cpus

Number of online CPUs.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<online_cpus> -- spelled out, because deriving it from the Perl name
would produce C<OnlineCpus>.

=head2 throttling_data

CPU throttling stats of the container. See
L<API::Docker::Type::ContainerThrottlingData>. Serialised as
C<throttling_data> -- spelled out, because deriving it from the Perl name
would produce C<ThrottlingData>.

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
