package API::Docker::Type::ContainerPidsStats;
# ABSTRACT: PidsStats contains Linux-specific stats of a container's process-IDs (PIDs)
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker current => Int, wire => 'current', since => '1.51';


docker limit => Int, wire => 'limit', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerPidsStats - PidsStats contains Linux-specific stats of a container's process-IDs (PIDs)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerPidsStats> definition of C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=head2 current

Current is the number of PIDs in the cgroup. Serialised as C<current> --
spelled out, because deriving it from the Perl name would produce
C<Current>.

=head2 limit

Limit is the hard limit on the number of pids in the cgroup. A "Limit" of 0
means that there is no limit. Serialised as C<limit> -- spelled out, because
deriving it from the Perl name would produce C<Limit>.

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
