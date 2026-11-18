package API::Docker::Type::TaskSpec::ContainerSpec::Config;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Configs>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Config::File;
use namespace::clean;


docker file => 'TaskSpec::ContainerSpec::Config::File';


docker runtime => Any;


docker config_id => Str, wire => 'ConfigID';


docker config_name => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::ContainerSpec::Config - One entry of C<TaskSpec.ContainerSpec.Configs>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Configs> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=head2 file

File represents a specific target that is backed by a file.

> B<Note>: C<Configs.File> and C<Configs.Runtime> are mutually exclusive.
See L<API::Docker::Type::TaskSpec::ContainerSpec::Config::File>.

=head2 runtime

Runtime represents a target that is not mounted into the container but is
used by the task

> B<Note>: C<Configs.File> and C<Configs.Runtime> are mutually > exclusive.

=head2 config_id

ConfigID represents the ID of the specific config that we're referencing.
Serialised as C<ConfigID> -- spelled out, because deriving it from the Perl
name would produce C<ConfigId>.

=head2 config_name

ConfigName is the name of the config that this references, but this is just
provided for lookup/display purposes. The config in the reference will be
identified by its ID.

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
