package API::Docker::Type::Plugin::Config::Args;
# ABSTRACT: The command-line arguments a plugin accepts
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker description => Str;


docker settable => [Str];


docker value => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config::Args - The command-line arguments a plugin accepts

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Args> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 name

Undocumented upstream. C<args> in the swagger's example -- the whole command
line is one named item, not one item per argument.

=head2 description

Undocumented upstream. C<"command line arguments"> in the swagger's example.

=head2 settable

Undocumented upstream. An array of strings, and the swagger never says what
they hold. What a user changes on an installed plugin goes in through C<POST
/plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>.

=head2 value

Undocumented upstream. The arguments themselves, one string each.

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
