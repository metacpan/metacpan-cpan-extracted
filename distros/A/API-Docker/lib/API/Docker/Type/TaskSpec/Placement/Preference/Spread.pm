package API::Docker::Type::TaskSpec::Placement::Preference::Spread;
# ABSTRACT: The node attribute a task is spread over
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker spread_descriptor => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::Placement::Preference::Spread - The node attribute a task is spread over

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Spread> schema of
C<TaskSpec.Placement.Preferences> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 spread_descriptor

Label descriptor, such as C<engine.labels.az>.

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
