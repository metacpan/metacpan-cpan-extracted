package API::Docker::Type::ThrottleDevice;
# ABSTRACT: A per-device block IO rate limit
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker path => Str;


docker rate => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ThrottleDevice - A per-device block IO rate limit

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ThrottleDevice> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Resources.BlkioDeviceReadBps>,
C<Resources.BlkioDeviceReadIOps>, C<Resources.BlkioDeviceWriteBps> and
C<Resources.BlkioDeviceWriteIOps>.

=head2 path

Device path.

=head2 rate

Rate. What it counts depends on the field this device sits in: bytes per
second under C<blkio_device_read_bps> and C<blkio_device_write_bps>, IO
operations per second under C<blkio_device_read_iops> and
C<blkio_device_write_iops>.

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
