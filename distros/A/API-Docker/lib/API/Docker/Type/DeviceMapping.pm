package API::Docker::Type::DeviceMapping;
# ABSTRACT: A device mapping between the host and container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker path_on_host => Str;


docker path_in_container => Str;


docker cgroup_permissions => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::DeviceMapping - A device mapping between the host and container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<DeviceMapping> definition of C<spec/v1.51.yaml>. None
of its three fields carries a description upstream; the example the swagger
gives is C<< { PathOnHost: "/dev/deviceName", PathInContainer:
"/dev/deviceName", CgroupPermissions: "mrw" } >>.

=head2 path_on_host

Undocumented upstream. The device's path on the host, per the swagger's
example.

=head2 path_in_container

Undocumented upstream. The path the device is to appear under inside the
container, per the swagger's example.

=head2 cgroup_permissions

Undocumented upstream. The cgroup device permissions, C<"mrw"> in the
swagger's example.

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
