package API::Docker::Type::Service;
# ABSTRACT: One entry of the C<200> response to C<GET /services>
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::Service::Endpoint;
use API::Docker::Type::Service::JobStatus;
use API::Docker::Type::Service::ServiceStatus;
use API::Docker::Type::Service::UpdateStatus;
use API::Docker::Type::ServiceSpec;
use namespace::clean;


docker id => Str, wire => 'ID';


docker version => 'ObjectVersion';


docker created_at => Str;


docker updated_at => Str;


docker spec => 'ServiceSpec';


docker endpoint => 'Service::Endpoint';


docker update_status => 'Service::UpdateStatus';


docker service_status => 'Service::ServiceStatus';


docker job_status => 'Service::JobStatus';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service - One entry of the C<200> response to C<GET /services>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Service> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /services> and the body of the C<200> response to
C<GET /services/{id}>.

=head2 id

Undocumented upstream. The service's ID, C<9mnpnzenvg8p8tdbtq4wvbkcz> in the
swagger's example -- the value that example's companion C<Task> repeats as
its C<ServiceID>. Serialised as C<ID> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=head2 version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=head2 created_at

Undocumented upstream. RFC 3339 with nanoseconds,
C<2016-06-07T21:05:51.880065305Z> in the swagger's example.

=head2 updated_at

Undocumented upstream. The same format, and in that example some
ninety-eight seconds later than L</created_at>.

=head2 spec

User modifiable configuration for a service. See
L<API::Docker::Type::ServiceSpec>.

=head2 endpoint

Undocumented upstream. The ports and virtual IPs the swarm actually gave the
service. What was asked for is the C<EndpointSpec> inside L</spec>, and the
endpoint repeats it as its own C<Spec> -- in the swagger's example all three
copies of the port entry agree. See L<API::Docker::Type::Service::Endpoint>.

=head2 update_status

The status of a service update. See
L<API::Docker::Type::Service::UpdateStatus>.

=head2 service_status

The status of the service's tasks. Provided only when requested as part of a
ServiceList operation. See L<API::Docker::Type::Service::ServiceStatus>.

=head2 job_status

The status of the service when it is in one of ReplicatedJob or GlobalJob
modes. Absent on Replicated and Global mode services. The JobIteration is an
ObjectVersion, but unlike the Service's version, does not need to be sent
with an update request. See L<API::Docker::Type::Service::JobStatus>.

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
