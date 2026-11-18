package API::Docker::Type::ServiceSpec;
# ABSTRACT: User modifiable configuration for a service
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::EndpointSpec;
use API::Docker::Type::NetworkAttachmentConfig;
use API::Docker::Type::ServiceSpec::Mode;
use API::Docker::Type::ServiceSpec::RollbackConfig;
use API::Docker::Type::ServiceSpec::UpdateConfig;
use API::Docker::Type::TaskSpec;
use namespace::clean;


docker name => Str;


docker labels => { Str, Str };


docker task_template => 'TaskSpec';


docker mode => 'ServiceSpec::Mode';


docker update_config => 'ServiceSpec::UpdateConfig';


docker rollback_config => 'ServiceSpec::RollbackConfig';


docker networks => [ 'NetworkAttachmentConfig' ];


docker endpoint_spec => 'EndpointSpec';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ServiceSpec - User modifiable configuration for a service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ServiceSpec> definition of C<spec/v1.51.yaml>.

=head2 name

Name of the service.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 task_template

User modifiable task configuration. See L<API::Docker::Type::TaskSpec>.

=head2 mode

Scheduling mode for the service. See
L<API::Docker::Type::ServiceSpec::Mode>.

=head2 update_config

Specification for the update strategy of the service. See
L<API::Docker::Type::ServiceSpec::UpdateConfig>.

=head2 rollback_config

Specification for the rollback strategy of the service. See
L<API::Docker::Type::ServiceSpec::RollbackConfig>.

=head2 networks

Specifies which networks the service should attach to.

Deprecated: This field is deprecated since v1.44. The Networks field in
TaskSpec should be used instead. See
L<API::Docker::Type::NetworkAttachmentConfig>.

=head2 endpoint_spec

Properties that can be configured to access and load balance a service. See
L<API::Docker::Type::EndpointSpec>.

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
