package API::Docker::Type::SwarmSpec;
# ABSTRACT: User modifiable swarm configuration
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::SwarmSpec::CAConfig;
use API::Docker::Type::SwarmSpec::Dispatcher;
use API::Docker::Type::SwarmSpec::EncryptionConfig;
use API::Docker::Type::SwarmSpec::Orchestration;
use API::Docker::Type::SwarmSpec::Raft;
use API::Docker::Type::SwarmSpec::TaskDefaults;
use namespace::clean;


docker name => Str;


docker labels => { Str, Str };


docker orchestration => 'SwarmSpec::Orchestration';


docker raft => 'SwarmSpec::Raft';


docker dispatcher => 'SwarmSpec::Dispatcher';


docker ca_config => 'SwarmSpec::CAConfig', wire => 'CAConfig';


docker encryption_config => 'SwarmSpec::EncryptionConfig';


docker task_defaults => 'SwarmSpec::TaskDefaults';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SwarmSpec - User modifiable swarm configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<SwarmSpec> definition of C<spec/v1.51.yaml>.

=head2 name

Name of the swarm.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 orchestration

Orchestration configuration. See
L<API::Docker::Type::SwarmSpec::Orchestration>.

=head2 raft

Raft configuration. See L<API::Docker::Type::SwarmSpec::Raft>.

=head2 dispatcher

Dispatcher configuration. See L<API::Docker::Type::SwarmSpec::Dispatcher>.

=head2 ca_config

CA configuration. See L<API::Docker::Type::SwarmSpec::CAConfig>. Serialised
as C<CAConfig> -- spelled out, because deriving it from the Perl name would
produce C<CaConfig>.

=head2 encryption_config

Parameters related to encryption-at-rest. See
L<API::Docker::Type::SwarmSpec::EncryptionConfig>.

=head2 task_defaults

Defaults for creating tasks in this cluster. See
L<API::Docker::Type::SwarmSpec::TaskDefaults>.

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
