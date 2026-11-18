package API::Docker::Type::Plugin::Config::User;
# ABSTRACT: The user and group a plugin's process runs as
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker uid => Int, wire => 'UID';


docker gid => Int, wire => 'GID';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Plugin::Config::User - The user and group a plugin's process runs as

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<User> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=head2 uid

Undocumented upstream. A C<uint32>; the swagger's example is C<1000>.
Serialised as C<UID> -- spelled out, because deriving it from the Perl name
would produce C<Uid>.

=head2 gid

Undocumented upstream. A C<uint32> too, C<1000> in the same example.
Serialised as C<GID> -- spelled out, because deriving it from the Perl name
would produce C<Gid>.

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
