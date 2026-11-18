package API::Docker::Type::TaskSpec::Resources;
# ABSTRACT: Resource requirements which apply to each individual container created as part of the service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Limit;
use API::Docker::Type::ResourceObject;
use namespace::clean;


docker limits => 'Limit';


docker reservations => 'ResourceObject';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::Resources - Resource requirements which apply to each individual container created as part of the service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Resources> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

=head2 limits

Define resources limits. See L<API::Docker::Type::Limit>.

=head2 reservations

Define resources reservation. See L<API::Docker::Type::ResourceObject>.

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
