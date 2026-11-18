package API::Docker::Type::ImageHistoryResponseItem;
# ABSTRACT: individual image layer information in response to ImageHistory operation
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker id => Str, required => 1;


docker created => Int, required => 1;


docker created_by => Str, required => 1;


docker tags => [Str], required => 1;


docker size => Int, required => 1;


docker comment => Str, required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageHistoryResponseItem - individual image layer information in response to ImageHistory operation

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageHistoryResponseItem> definition of
C<spec/v1.51.yaml>. The swagger describes none of the six fields, but the
example response it gives for C<GET /images/{name}/history> shows all six
across three layers. That example is not the last word: measured against
Podman 5.8.4 (API 1.44), a locally built image answers ten entries that
contradict it on three of the six, so L</id>, L</tags> and L</comment> each
say what the spec shows and what the engine sent.

=head2 id

Undocumented upstream. The swagger's example response spells this as a bare
hex digest with no C<sha256:> prefix. The engine does not. Measured against
Podman 5.8.4 (API 1.44), a locally built image answers ten entries of which
exactly one -- the image's own top layer -- carries a real C<sha256:...>
digest; the other nine carry the literal string C<< sha256:<missing> >>,
which is a marker and not an ID. Handing that to C<GET /images/{id}/json>
looks up nothing, so test for it before treating this field as a reference
to anything. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=head2 created

Undocumented upstream. A Unix timestamp in seconds -- C<1398108230> in the
swagger's example response, the same form the spec spells out for
L<API::Docker::Type::ImageSummary/created>, and the form measured against
Podman 5.8.4 (API 1.44), which answers C<1787794246> for the top layer of a
locally built image. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 created_by

Undocumented upstream. What created the layer, C<< "/bin/sh -c #(nop) ADD
file:eb15... in /" >> in the swagger's example response. Measured against
Podman 5.8.4 (API 1.44), one response mixes two forms: that C<< "/bin/sh -c
..." >> shell wrapping on the older layers, and bare Dockerfile instructions
on the ones a BuildKit build produced -- C<< CMD ["perl5.40.5" "-de0"] >>,
C<WORKDIR /usr/src/app>, C<< COPY *.patch /usr/src/perl/ # buildkit >>. Do
not parse it expecting either one. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 tags

Undocumented upstream. The image names pointing at this layer, C<<
["ubuntu:lucid", "ubuntu:10.04"] >> in the swagger's example response, which
writes C<[]> for a layer that has none. The engine writes C<null> there
instead: measured against Podman 5.8.4 (API 1.44), all ten entries of an
untagged image answer C<null>. An empty list is not what an absent tag looks
like on the wire. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 size

Undocumented upstream. The layer's size in bytes: C<182964289> for the one
that adds the root filesystem in the swagger's example response, C<0> for
the two that only carry metadata. Measured against Podman 5.8.4 (API 1.44),
the ten entries of one locally built image run from C<0> to C<410969600>,
and C<0> is not reserved for metadata layers -- a C<#(nop) COPY> among them
reports C<4262912>. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 comment

Undocumented upstream. The message set when the layer was committed or
imported, which is what L<API::Docker::Type::ImageInspect/comment> describes
for a whole image. The swagger's example response leaves it empty on two
layers and gives C<"Imported from -"> on the third. Measured against Podman
5.8.4 (API 1.44) it is always present, never absent, and where the layer has
a provenance it carries that: on one locally built image,
C<"buildkit.dockerfile.v0"> on five entries, C<"debuerreotype 0.17"> on the
base layer, C<< "FROM docker.io/library/perl:5.40-slim" >> on one more, and
the empty string on the remaining three. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

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
