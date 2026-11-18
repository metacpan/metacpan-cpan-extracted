package API::Docker::Type::BuildInfo;
# ABSTRACT: One event of the stream a C<POST /build> answers with
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ErrorDetail;
use API::Docker::Type::ImageID;
use API::Docker::Type::ProgressDetail;
use namespace::clean;


docker id => Str, wire => 'id';


docker stream => Str, wire => 'stream';


docker error => Str, wire => 'error';


docker error_detail => 'ErrorDetail', wire => 'errorDetail';


docker status => Str, wire => 'status';


docker progress => Str, wire => 'progress';


docker progress_detail => 'ProgressDetail', wire => 'progressDetail';


docker aux => 'ImageID', wire => 'aux';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::BuildInfo - One event of the stream a C<POST /build> answers with

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<BuildInfo> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing references it and no path names it as a
schema, because it is not a response body: C<POST /build> answers C<200> and
then writes one of these objects per line until the daemon closes the
connection. A failed build is still C<200>, and arrives as an event carrying
C<errorDetail>.

=head2 id

Undocumented upstream. The build stream captured in
F<t/fixtures/images_build_stream.ndjson> carries no C<id> at all. The same
field on a pull, L<API::Docker::Type::CreateImageInfo/id>, names the layer
each event is about. Serialised as C<id> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=head2 stream

Undocumented upstream. The build log the way the daemon writes it, one line
per event with the newline included -- C<< {"stream":"STEP 1/2: FROM
alpine:3\n"} >> opens F<t/fixtures/images_build_stream.ndjson>. Nine of that
capture's ten events are this field; the tenth is L</aux>. Serialised as
C<stream> -- spelled out, because deriving it from the Perl name would
produce C<Stream>.

=head2 error

Errors encountered during the operation.

> B<Deprecated>: This field is deprecated since API v1.4, and will be
omitted in a future API version. Use the information in errorDetail instead.
Serialised as C<error> -- spelled out, because deriving it from the Perl
name would produce C<Error>.

=head2 error_detail

Undocumented upstream. The failure, structured. The C<error> field beside it
carries the same text and the swagger deprecates it in favour of this one:
F<t/fixtures/images_build_error_stream.ndjson> ends with both, spelling
C<"building at STEP \"RUN exit 7\": while running runtime: exit status 7">
twice. See L<API::Docker::Type::ErrorDetail>. Serialised as C<errorDetail>
-- spelled out, because deriving it from the Perl name would produce
C<ErrorDetail>.

=head2 status

Undocumented upstream. The same phase line a pull reports through
L<API::Docker::Type::CreateImageInfo/status>; the captured build stream
carries L</stream> instead and no C<status> at all. Serialised as C<status>
-- spelled out, because deriving it from the Perl name would produce
C<Status>.

=head2 progress

Progress is a pre-formatted presentation of progressDetail.

> B<Deprecated>: This field is deprecated since API v1.8, and will be
omitted in a future API version. Use the information in progressDetail
instead. Serialised as C<progress> -- spelled out, because deriving it from
the Perl name would produce C<Progress>.

=head2 progress_detail

Undocumented upstream. The numbers behind L</progress>, which the swagger
describes as a pre-formatted presentation of this field. See
L<API::Docker::Type::ProgressDetail>. Serialised as C<progressDetail> --
spelled out, because deriving it from the Perl name would produce
C<ProgressDetail>.

=head2 aux

Image ID or Digest. See L<API::Docker::Type::ImageID>. Serialised as C<aux>
-- spelled out, because deriving it from the Perl name would produce C<Aux>.

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
