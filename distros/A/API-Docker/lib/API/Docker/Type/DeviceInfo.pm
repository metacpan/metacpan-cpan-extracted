package API::Docker::Type::DeviceInfo;
# ABSTRACT: A device that can be used by a container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker source => Str, since => '1.51';


docker id => Str, wire => 'ID', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::DeviceInfo - A device that can be used by a container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<DeviceInfo> definition of C<spec/v1.51.yaml>.

=head2 source

The origin device driver.

=head2 id

The unique identifier for the device within its source driver. For CDI
devices, this would be an FQDN like "vendor.com/gpu=0". Serialised as C<ID>
-- spelled out, because deriving it from the Perl name would produce C<Id>.

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
