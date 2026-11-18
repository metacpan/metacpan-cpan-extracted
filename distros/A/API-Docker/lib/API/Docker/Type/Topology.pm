package API::Docker::Type::Topology;
# ABSTRACT: A map of topological domains to topological segments
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker segments => { Str, Str }, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Topology - A map of topological domains to topological segments

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Topology> definition of C<spec/v1.51.yaml>.

For in depth details, see documentation for the Topology object in the CSI
specification.

=head2 segments

Undocumented upstream. The map itself -- topological domains for keys,
topological segments for values, which is what the definition above says the
object is. The swagger sends you to the CSI specification's own Topology
object for what those are. B<The keys are the caller's data> and are never
translated.

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
