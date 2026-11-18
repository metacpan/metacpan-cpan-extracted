package API::Docker::Type::EngineDescription::Plugin;
# ABSTRACT: One entry of C<EngineDescription.Plugins>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker type => Str;


docker name => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EngineDescription::Plugin - One entry of C<EngineDescription.Plugins>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<EngineDescription.Plugins> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 type

Undocumented upstream. What the plugin plugs into: C<Log>, C<Network> and
C<Volume> are the three the swagger's example uses.

=head2 name

Undocumented upstream. Its name -- a bare word for the built-in drivers
(C<json-file>, C<overlay>, C<local>), and a full image reference for an
installed one: C<localhost:5000/vieux/sshfs:latest> in the same example.

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
