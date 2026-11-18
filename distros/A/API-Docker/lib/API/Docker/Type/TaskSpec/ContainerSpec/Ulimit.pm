package API::Docker::Type::TaskSpec::ContainerSpec::Ulimit;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Ulimits>
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

API::Docker::Type::TaskSpec::ContainerSpec::Ulimit - One entry of C<TaskSpec.ContainerSpec.Ulimits>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Ulimits> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 name

Name of ulimit.

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
