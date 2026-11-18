package API::Docker::Type::GenericResource::NamedResourceSpec;
# ABSTRACT: A string-valued user-defined resource
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker kind => Str;


docker value => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::GenericResource::NamedResourceSpec - A string-valued user-defined resource

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<NamedResourceSpec> schema of the
C<GenericResources> definition in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. The C<Kind>/C<Value> pair for a named resource,
C<GPU=UUID1> in the swagger's example.

=head2 kind

Undocumented upstream. The resource's name, C<GPU> in that example.

=head2 value

Undocumented upstream. The name of the one unit, C<UUID1> in that example.
The example carries two such objects, C<UUID1> and C<UUID2>, rather than one
object listing both -- a node advertising two GPUs advertises two entries.

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
