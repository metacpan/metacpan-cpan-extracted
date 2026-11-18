package API::Docker::Type::TaskSpec::ContainerSpec::Config::File;
# ABSTRACT: A specific target that is backed by a file
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker uid => Str, wire => 'UID';


docker gid => Str, wire => 'GID';


docker mode => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Config::File - A specific target that is backed by a file

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<File> schema of
C<TaskSpec.ContainerSpec.Configs> in C<spec/v1.51.yaml>.

> B<Note>: C<Configs.File> and C<Configs.Runtime> are mutually exclusive.

=head2 name

Name represents the final filename in the filesystem.

=head2 uid

UID represents the file UID. Serialised as C<UID> -- spelled out, because
deriving it from the Perl name would produce C<Uid>.

=head2 gid

GID represents the file GID. Serialised as C<GID> -- spelled out, because
deriving it from the Perl name would produce C<Gid>.

=head2 mode

Mode represents the FileMode of the file.

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
