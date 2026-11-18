package API::Docker::Type::PluginPrivilege;
# ABSTRACT: Describes a permission the user has to accept upon installing the plugin
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker description => Str;


docker value => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::PluginPrivilege - Describes a permission the user has to accept upon installing the plugin

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<PluginPrivilege> definition of C<spec/v1.51.yaml>.

=head2 name

Undocumented upstream. What the permission is over, C<network> in the
swagger's example.

=head2 description

Undocumented upstream.

=head2 value

Undocumented upstream. What is being asked for, one string each: C<<
["host"] >> beside that C<network> in the swagger's example.

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
