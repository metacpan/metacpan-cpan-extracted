package API::Docker::Type::Config;
# ABSTRACT: One entry of the C<200> response to C<GET /configs>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ConfigSpec;
use API::Docker::Type::ObjectVersion;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker spec => 'ConfigSpec';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Config - One entry of the C<200> response to C<GET /configs>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Config> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /configs> and the body of the C<200> response to
C<GET /configs/{id}>. The same four fields and the same C<Version> a secret
carries, and the swagger gives an example for none of them;
L<API::Docker::Type::Secret> is where the shapes are written down.

=head2 id

Undocumented upstream. The config's ID, as L<API::Docker::Type::Secret/id>
is a secret's. Serialised as C<ID> -- spelled out, because deriving it from
the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Undocumented upstream. RFC 3339, as L<API::Docker::Type::Secret/created_at>
is.

=head2 updated_at

Undocumented upstream. The same format as L</created_at>.

=head2 spec

Undocumented upstream. The config's name, labels, templating and -- unlike a
secret's -- its actual data, which the daemon does hand back.
L<API::Docker::Role::Entity::Config/decoded_data> is the accessor that
base64-decodes it. See L<API::Docker::Type::ConfigSpec>.

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
