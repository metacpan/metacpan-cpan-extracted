package API::Docker::Type::ContainerCPUUsage;
# ABSTRACT: All CPU stats aggregated since container inception
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker total_usage => Int, wire => 'total_usage', since => '1.51';


docker percpu_usage => [Int], wire => 'percpu_usage', since => '1.51';


docker usage_in_kernelmode => Int,
  wire => 'usage_in_kernelmode', since => '1.51';


docker usage_in_usermode => Int, wire => 'usage_in_usermode', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerCPUUsage - All CPU stats aggregated since container inception

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerCPUUsage> definition of C<spec/v1.51.yaml>.

=head2 total_usage

Total CPU time consumed in nanoseconds (Linux) or 100's of nanoseconds
(Windows). Serialised as C<total_usage> -- spelled out, because deriving it
from the Perl name would produce C<TotalUsage>.

=head2 percpu_usage

Total CPU time (in nanoseconds) consumed per core (Linux).

This field is Linux-specific when using cgroups v1. It is omitted when using
cgroups v2 and Windows containers. Serialised as C<percpu_usage> -- spelled
out, because deriving it from the Perl name would produce C<PercpuUsage>.

=head2 usage_in_kernelmode

Time (in nanoseconds) spent by tasks of the cgroup in kernel mode (Linux),
or time spent (in 100's of nanoseconds) by all container processes in kernel
mode (Windows).

Not populated for Windows containers using Hyper-V isolation. Serialised as
C<usage_in_kernelmode> -- spelled out, because deriving it from the Perl
name would produce C<UsageInKernelmode>.

=head2 usage_in_usermode

Time (in nanoseconds) spent by tasks of the cgroup in user mode (Linux), or
time spent (in 100's of nanoseconds) by all container processes in kernel
mode (Windows).

Not populated for Windows containers using Hyper-V isolation. Serialised as
C<usage_in_usermode> -- spelled out, because deriving it from the Perl name
would produce C<UsageInUsermode>.

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
