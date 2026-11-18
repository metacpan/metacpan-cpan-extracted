package API::Docker::Type::ImageID;
# ABSTRACT: Image ID or Digest
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker id => Str, wire => 'ID';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageID - Image ID or Digest

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageID> definition of C<spec/v1.51.yaml>. The only
C<$ref> to it in the whole spec is C<BuildInfo.aux>, so this is the object a
build stream reports the finished image's ID in; see
L<API::Docker::Type::BuildInfo/aux>.

=head2 id

Undocumented upstream. The image ID or digest the definition's own
description names. The swagger's example is
C<sha256:85f05633ddc1c50679be2b16a0479ab6f7637f8884e0cfe0f4d20e1ebb3d6e7c>.
Serialised as C<ID> -- spelled out, because deriving it from the Perl name
would produce C<Id>.

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
