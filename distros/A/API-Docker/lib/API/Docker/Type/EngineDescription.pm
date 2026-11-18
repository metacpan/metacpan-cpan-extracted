package API::Docker::Type::EngineDescription;
# ABSTRACT: EngineDescription provides information about an engine
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EngineDescription::Plugin;
use namespace::clean;


docker engine_version => Str;


docker labels => { Str, Str };


docker plugins => [ 'EngineDescription::Plugin' ];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::EngineDescription - EngineDescription provides information about an engine

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<EngineDescription> definition of C<spec/v1.51.yaml>.

=head2 engine_version

Undocumented upstream. The engine's version as the node's agent reports it,
C<17.06.0> in the swagger's example -- the value C<GET /version> answers as
L<API::Docker::Type::SystemVersion/version>.

=head2 labels

Undocumented upstream. The engine's own labels, C<< {"foo": "bar"} >> in the
swagger's example. These are the C<engine.labels> a task placement
constraint can match on; see
L<API::Docker::Type::TaskSpec::Placement/constraints>. B<The keys are the
caller's data> and are never translated.

=head2 plugins

Undocumented upstream. One entry per plugin the engine has. The swagger's
example lists seventeen -- eight C<Log>, six C<Network> and three C<Volume>.
C<GET /info> reports the same ground in a different shape, as
L<API::Docker::Type::PluginsInfo>. See
L<API::Docker::Type::EngineDescription::Plugin>.

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
