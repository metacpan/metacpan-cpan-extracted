package API::Docker::Type::Mount::VolumeOptions;
# ABSTRACT: Optional configuration for the C<volume> type
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Mount::VolumeOptions::DriverConfig;
use namespace::clean;


docker no_copy => Bool;


docker labels => { Str, Str };


docker driver_config => 'Mount::VolumeOptions::DriverConfig';


docker subpath => Str, since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Mount::VolumeOptions - Optional configuration for the C<volume> type

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<VolumeOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>.

=head2 no_copy

Populate volume with data from the target. The daemon defaults it to false.

=head2 labels

User-defined key/value metadata. A label named C<com.example.Some-Label>
reaches the daemon spelled exactly that way. B<The keys are the caller's
data> and are never translated.

=head2 driver_config

The volume driver to create the volume with, and its options. The swagger's
description of this field, "Map of driver specific options", describes the
driver's own options map rather than the object. See
L<API::Docker::Type::Mount::VolumeOptions::DriverConfig>.

=head2 subpath

Source path inside the volume. Must be relative without any back traversals.

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
