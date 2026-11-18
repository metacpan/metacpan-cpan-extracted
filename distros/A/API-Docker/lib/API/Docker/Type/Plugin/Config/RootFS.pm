package API::Docker::Type::Plugin::Config::RootFS;
# ABSTRACT: The root filesystem of a plugin
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker type => Str, wire => 'type';


docker diff_ids => [Str], wire => 'diff_ids';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config::RootFS - The root filesystem of a plugin

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<rootfs> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. The two fields are
spelled in lower case upstream, C<type> and C<diff_ids>, and the property
itself is C<rootfs>; the class is named C<RootFS> to match
C<ImageInspect.RootFS>, which is recorded in
C<maint/spec-drift-exceptions.yaml>.

=head2 type

Undocumented upstream. C<layers> in the swagger's example, the same value an
image answers with under L<API::Docker::Type::ImageInspect::RootFS/type>.
Serialised as C<type> -- spelled out, because deriving it from the Perl name
would produce C<Type>.

=head2 diff_ids

Undocumented upstream. One C<sha256:...> digest per layer, two of them in
the swagger's example -- what
L<API::Docker::Type::ImageInspect::RootFS/layers> holds for an image.
Serialised as C<diff_ids> -- spelled out, because deriving it from the Perl
name would produce C<DiffIds>.

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
