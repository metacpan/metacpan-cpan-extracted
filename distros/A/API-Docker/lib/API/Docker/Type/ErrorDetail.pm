package API::Docker::Type::ErrorDetail;
# ABSTRACT: The value of C<BuildInfo.errorDetail>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker code => Int, wire => 'code';


docker message => Str, wire => 'message';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ErrorDetail - The value of C<BuildInfo.errorDetail>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ErrorDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.errorDetail>, C<CreateImageInfo.errorDetail> and
C<PushImageInfo.errorDetail>. It is what a build, pull or push stream
reports a failure through, and what L<API::Docker::Error::Stream> is croaked
on; neither of its two fields is described either.

=head2 code

Undocumented upstream. An integer. No captured stream under F<t/fixtures/>
carries one -- the C<errorDetail> of
F<t/fixtures/images_build_error_stream.ndjson> has L</message> and nothing
else. Serialised as C<code> -- spelled out, because deriving it from the
Perl name would produce C<Code>.

=head2 message

Undocumented upstream. The reason, as text. It ends in a newline in
F<t/fixtures/images_build_error_stream.ndjson>, which is why
L<API::Docker::Error::Stream/message> strips trailing whitespace before Carp
sees it. Serialised as C<message> -- spelled out, because deriving it from
the Perl name would produce C<Message>.

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
