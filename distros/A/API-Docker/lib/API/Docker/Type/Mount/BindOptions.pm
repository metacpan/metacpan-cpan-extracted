package API::Docker::Type::Mount::BindOptions;
# ABSTRACT: Optional configuration for the C<bind> type
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker propagation => Str,
  enum => [qw( private rprivate shared rshared slave rslave )];


docker non_recursive => Bool;


docker create_mountpoint => Bool, since => '1.44';


docker read_only_non_recursive => Bool, since => '1.44';


docker read_only_force_recursive => Bool, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Mount::BindOptions - Optional configuration for the C<bind> type

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<BindOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>. Upstream it has no name of its own -- it is an object
written straight into C<Mount>, and the class is named after the definition
that declares it.

=head2 propagation

A propagation mode with the value C<[r]private>, C<[r]shared>, or
C<[r]slave>. The swagger enumerates C<private>, C<rprivate>, C<shared>,
C<rshared>, C<slave> and C<rslave>.

=head2 non_recursive

Disable recursive bind mount. The daemon defaults it to false.

=head2 create_mountpoint

Create mount point on host if missing. The daemon defaults it to false.

=head2 read_only_non_recursive

Make the mount non-recursively read-only, but still leave the mount
recursive (unless NonRecursive is set to C<true> in conjunction).

Added in v1.44, before that version all read-only mounts were non-recursive
by default. To match the previous behaviour this will default to C<true> for
clients on versions prior to v1.44.

=head2 read_only_force_recursive

Raise an error if the mount cannot be made recursively read-only. The daemon
defaults it to false.

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
