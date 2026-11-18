package API::Docker::Type::TaskSpec::ContainerSpec::Secret;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Secrets>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Secret::File;
use namespace::clean;


docker file => 'TaskSpec::ContainerSpec::Secret::File';


docker secret_id => Str, wire => 'SecretID';


docker secret_name => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Secret - One entry of C<TaskSpec.ContainerSpec.Secrets>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Secrets> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 file

File represents a specific target that is backed by a file. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Secret::File>.

=head2 secret_id

SecretID represents the ID of the specific secret that we're referencing.
Serialised as C<SecretID> -- spelled out, because deriving it from the Perl
name would produce C<SecretId>.

=head2 secret_name

SecretName is the name of the secret that this references, but this is just
provided for lookup/display purposes. The secret in the reference will be
identified by its ID.

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
