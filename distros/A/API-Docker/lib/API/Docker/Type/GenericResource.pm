package API::Docker::Type::GenericResource;
# ABSTRACT: User-defined resources can be either Integer resources (e.g, C<SSD=3>) or String resources (e.g, C<GPU=UUID1>)
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::GenericResource::DiscreteResourceSpec;
use API::Docker::Type::GenericResource::NamedResourceSpec;
use namespace::clean;


docker named_resource_spec => 'GenericResource::NamedResourceSpec';


docker discrete_resource_spec => 'GenericResource::DiscreteResourceSpec';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::GenericResource - User-defined resources can be either Integer resources (e.g, C<SSD=3>) or String resources (e.g, C<GPU=UUID1>)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<GenericResources> definition of C<spec/v1.51.yaml>.

=head2 named_resource_spec

Undocumented upstream. The pair when the resource is named, which the
enclosing C<GenericResources> calls a String resource: C<GPU=UUID1> in its
example. See L<API::Docker::Type::GenericResource::NamedResourceSpec>.

=head2 discrete_resource_spec

Undocumented upstream. The C<Kind>/C<Value> pair when the resource counts,
which the enclosing C<GenericResources> calls an Integer resource: C<SSD=3>
in its example. See
L<API::Docker::Type::GenericResource::DiscreteResourceSpec>.

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
