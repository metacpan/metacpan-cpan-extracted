package API::Docker::Type::NodeSpec;
# ABSTRACT: The body of a C<POST /nodes/{id}/update> request
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker labels => { Str, Str };


docker role => Str, enum => [qw( worker manager )];


docker availability => Str, enum => [qw( active pause drain )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::NodeSpec - The body of a C<POST /nodes/{id}/update> request

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<NodeSpec> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/nodes/{id}/update> request.

=head2 name

Name for the node.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 role

Role of the node. The swagger enumerates C<worker> and C<manager>.

=head2 availability

Availability of the node. The swagger enumerates C<active>, C<pause> and
C<drain>.

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
