package API::Docker::Type::ImageInspect::Metadata;
# ABSTRACT: Additional metadata of the image in the local cache
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker last_tag_time => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageInspect::Metadata - Additional metadata of the image in the local cache

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Metadata> schema of the C<ImageInspect>
definition in C<spec/v1.51.yaml>.

This information is local to the daemon, and not part of the image itself.

=head2 last_tag_time

Date and time at which the image was last tagged in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

This information is only available if the image was tagged locally, and
omitted otherwise.

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
