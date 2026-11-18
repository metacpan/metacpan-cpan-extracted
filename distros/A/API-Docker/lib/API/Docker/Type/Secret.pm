package API::Docker::Type::Secret;
# ABSTRACT: One entry of the C<200> response to C<GET /secrets>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::SecretSpec;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker spec => 'SecretSpec';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Secret - One entry of the C<200> response to C<GET /secrets>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Secret> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /secrets> and the body of the C<200> response to
C<GET /secrets/{id}>.

=head2 id

Undocumented upstream. The secret's ID. The swagger's example is a
25-character Swarm ID, C<blt1owaxmitz71s9v5zh81zun>; the C<GET /secrets>
capture in F<t/fixtures/secrets_list.json>, from Podman 5.4.2 (API 1.41),
answers 25 hex characters instead. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Undocumented upstream. RFC 3339 with nanoseconds,
C<2017-07-20T13:55:28.678958722Z> in the swagger's example.

=head2 updated_at

Undocumented upstream. The same format as L</created_at>, and identical to
it on a secret that has never been updated -- both captured secrets in
F<t/fixtures/secrets_list.json> carry the same instant in both fields.

=head2 spec

Undocumented upstream. The secret's name, driver and labels. Not its value:
the daemon hands that to containers and never back over C</secrets>, so C<<
$secret->spec->data >> reads C<undef> on anything an engine sent;
L<API::Docker::Role::Entity::Secret> says why. See
L<API::Docker::Type::SecretSpec>.

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
