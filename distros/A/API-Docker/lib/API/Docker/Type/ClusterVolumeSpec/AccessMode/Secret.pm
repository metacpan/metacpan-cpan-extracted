package API::Docker::Type::ClusterVolumeSpec::AccessMode::Secret;
# ABSTRACT: One cluster volume secret entry
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker key => Str, since => '1.44';


docker secret => Str, since => '1.44';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ClusterVolumeSpec::AccessMode::Secret - One cluster volume secret entry

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<ClusterVolumeSpec.AccessMode.Secrets> in C<spec/v1.51.yaml>.

Defines a key-value pair that is passed to the plugin.

=head2 key

Key is the name of the key of the key-value pair passed to the plugin.

=head2 secret

Secret is the swarm Secret object from which to read data. This can be a
Secret name or ID. The Secret data is retrieved by swarm and used as the
value of the key-value pair passed to the plugin.

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
