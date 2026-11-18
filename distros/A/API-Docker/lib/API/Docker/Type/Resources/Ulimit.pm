package API::Docker::Type::Resources::Ulimit;
# ABSTRACT: One resource limit to set in a container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker soft => Int;


docker hard => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Resources::Ulimit - One resource limit to set in a container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Resources.Ulimits> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. Upstream the
schema has no name at all: the class name is this one place where the model
does not follow from the spec mechanically, because C<Ulimits> had to be
made singular by hand. The mapping is recorded in
C<maint/spec-drift-exceptions.yaml>.

=head2 name

Name of ulimit. C<nofile> for instance.

=head2 soft

Soft limit.

=head2 hard

Hard limit.

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
