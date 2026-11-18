package API::Docker::Type::Volume::UsageData;
# ABSTRACT: Usage details about the volume
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker size => Int;


docker ref_count => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Volume::UsageData - Usage details about the volume

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<UsageData> schema of the C<Volume> definition in
C<spec/v1.51.yaml>.

This information is used by the C<GET /system/df> endpoint, and omitted in
other endpoints.

=head2 size

Amount of disk space used by the volume (in bytes). This information is only
available for volumes created with the C<"local"> volume driver. For volumes
created with other volume drivers, this field is set to C<-1> ("not
available"). The daemon defaults it to -1.

=head2 ref_count

The number of containers referencing this volume. This field is set to C<-1>
if the reference-count is not available. The daemon defaults it to -1.

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
