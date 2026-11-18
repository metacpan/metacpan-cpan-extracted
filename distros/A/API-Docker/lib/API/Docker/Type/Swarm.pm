package API::Docker::Type::Swarm;
# ABSTRACT: The body of the C<200> response to C<GET /swarm>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::JoinTokens;
use namespace::clean;


docker_extends 'ClusterInfo';

docker join_tokens => 'JoinTokens';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Swarm - The body of the C<200> response to C<GET /swarm>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Swarm> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of the
C<200> response to C<GET /swarm>, which is C<allOf [ $ref ClusterInfo, { 1
properties } ]>. The reference becomes a superclass, so a C<Swarm> carries
the 10 fields of L<API::Docker::Type::ClusterInfo> as well as the 1 declared
here -- 11 in all. See L<API::Docker::Type/C<allOf> becomes inheritance>.

=head2 join_tokens

JoinTokens contains the tokens workers and managers need to join the swarm.
See L<API::Docker::Type::JoinTokens>.

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
