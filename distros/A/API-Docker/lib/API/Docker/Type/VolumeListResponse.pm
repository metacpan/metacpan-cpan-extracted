package API::Docker::Type::VolumeListResponse;
# ABSTRACT: Volume list response
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Volume;
use namespace::clean;


docker volumes => [ 'Volume' ];


docker warnings => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::VolumeListResponse - Volume list response

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<VolumeListResponse> definition of C<spec/v1.51.yaml>.

=head2 volumes

List of volumes. See L<API::Docker::Type::Volume>.

=head2 warnings

Warnings that occurred when fetching the list of volumes.

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
