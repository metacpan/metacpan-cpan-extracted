package API::Docker::Type::TaskSpec::Placement::Preference;
# ABSTRACT: One scheduling preference of a task
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::Placement::Preference::Spread;
use namespace::clean;


docker spread => 'TaskSpec::Placement::Preference::Spread';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::Placement::Preference - One scheduling preference of a task

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.Placement.Preferences> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 spread

Undocumented upstream. The only kind of preference the swagger defines, and
the only field of this object. Its own C<SpreadDescriptor> is described
upstream as a label descriptor; the example under
L<API::Docker::Type::TaskSpec::Placement/preferences> spreads over
C<node.labels.datacenter> first and C<node.labels.rack> second, preferences
being listed from highest precedence to lowest. See
L<API::Docker::Type::TaskSpec::Placement::Preference::Spread>.

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
