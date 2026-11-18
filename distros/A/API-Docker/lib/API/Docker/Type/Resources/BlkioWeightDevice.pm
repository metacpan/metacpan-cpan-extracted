package API::Docker::Type::Resources::BlkioWeightDevice;
# ABSTRACT: A per-device block IO weight
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker path => Str;


docker weight => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Resources::BlkioWeightDevice - A per-device block IO weight

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Resources.BlkioWeightDevice>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Neither the
schema nor its two fields carry a description upstream; the form the swagger
shows for the enclosing field is C<< [{"Path": "device_path", "Weight":
weight}] >>.

=head2 path

Undocumented upstream. The device path, per the swagger's example form.

=head2 weight

Undocumented upstream. The relative weight for that device; the swagger
constrains it to 0 or above and nothing else.

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
