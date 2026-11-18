package API::Docker::Type::DeviceRequest;
# ABSTRACT: A request for devices to be sent to device drivers
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker driver => Str;


docker count => Int;


docker device_ids => [Str], wire => 'DeviceIDs';


docker capabilities => [[Str]];


docker options => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::DeviceRequest - A request for devices to be sent to device drivers

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<DeviceRequest> definition of C<spec/v1.51.yaml>.

=head2 driver

Undocumented upstream. The swagger's example is C<"nvidia">.

=head2 count

Undocumented upstream. The swagger's example is C<-1>.

=head2 device_ids

Undocumented upstream. The swagger's example is C<< ["0", "1",
"GPU-fef8089b-4820-abfc-e83e-94318197576e"] >>. Serialised as C<DeviceIDs>
-- spelled out, because deriving it from the Perl name would produce
C<DeviceIds>.

=head2 capabilities

A list of capabilities; an OR list of AND lists of capabilities. An ArrayRef
of ArrayRefs of strings: C<< [["gpu", "nvidia", "compute"]] >> asks for a
device that has all three.

=head2 options

Driver-specific options, specified as a key/value pairs. These options are
passed directly to the driver. B<The keys are the caller's data> and are
never translated.

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
