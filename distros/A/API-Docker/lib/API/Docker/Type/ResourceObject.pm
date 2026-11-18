package API::Docker::Type::ResourceObject;
# ABSTRACT: An object describing the resources which can be advertised by a node and requested by a task
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::GenericResource;
use namespace::clean;


docker nano_cpus => Int, wire => 'NanoCPUs';


docker memory_bytes => Int;


docker generic_resources => [ 'GenericResource' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ResourceObject - An object describing the resources which can be advertised by a node and requested by a task

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ResourceObject> definition of C<spec/v1.51.yaml>.

=head2 nano_cpus

Undocumented upstream. The same units and the same example as
L<API::Docker::Type::Limit/nano_cpus>: C<4000000000> is four whole CPUs.
Serialised as C<NanoCPUs> -- spelled out, because deriving it from the Perl
name would produce C<NanoCpus>.

=head2 memory_bytes

Undocumented upstream. Bytes, and the same example as
L<API::Docker::Type::Limit/memory_bytes>.

=head2 generic_resources

User-defined resources can be either Integer resources (e.g, C<SSD=3>) or
String resources (e.g, C<GPU=UUID1>). See
L<API::Docker::Type::GenericResource>.

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
