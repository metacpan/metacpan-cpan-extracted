package API::Docker::Type::ContainerNetworkStats;
# ABSTRACT: Aggregates the network stats of one container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker rx_bytes => Int, wire => 'rx_bytes', since => '1.51';


docker rx_packets => Int, wire => 'rx_packets', since => '1.51';


docker rx_errors => Int, wire => 'rx_errors', since => '1.51';


docker rx_dropped => Int, wire => 'rx_dropped', since => '1.51';


docker tx_bytes => Int, wire => 'tx_bytes', since => '1.51';


docker tx_packets => Int, wire => 'tx_packets', since => '1.51';


docker tx_errors => Int, wire => 'tx_errors', since => '1.51';


docker tx_dropped => Int, wire => 'tx_dropped', since => '1.51';


docker endpoint_id => Str, wire => 'endpoint_id', since => '1.51';


docker instance_id => Str, wire => 'instance_id', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerNetworkStats - Aggregates the network stats of one container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerNetworkStats> definition of
C<spec/v1.51.yaml>.

=head2 rx_bytes

Bytes received. Windows and Linux. Serialised as C<rx_bytes> -- spelled out,
because deriving it from the Perl name would produce C<RxBytes>.

=head2 rx_packets

Packets received. Windows and Linux. Serialised as C<rx_packets> -- spelled
out, because deriving it from the Perl name would produce C<RxPackets>.

=head2 rx_errors

Received errors. Not used on Windows.

This field is Linux-specific and always zero for Windows containers.
Serialised as C<rx_errors> -- spelled out, because deriving it from the Perl
name would produce C<RxErrors>.

=head2 rx_dropped

Incoming packets dropped. Windows and Linux. Serialised as C<rx_dropped> --
spelled out, because deriving it from the Perl name would produce
C<RxDropped>.

=head2 tx_bytes

Bytes sent. Windows and Linux. Serialised as C<tx_bytes> -- spelled out,
because deriving it from the Perl name would produce C<TxBytes>.

=head2 tx_packets

Packets sent. Windows and Linux. Serialised as C<tx_packets> -- spelled out,
because deriving it from the Perl name would produce C<TxPackets>.

=head2 tx_errors

Sent errors. Not used on Windows.

This field is Linux-specific and always zero for Windows containers.
Serialised as C<tx_errors> -- spelled out, because deriving it from the Perl
name would produce C<TxErrors>.

=head2 tx_dropped

Outgoing packets dropped. Windows and Linux. Serialised as C<tx_dropped> --
spelled out, because deriving it from the Perl name would produce
C<TxDropped>.

=head2 endpoint_id

Endpoint ID. Not used on Linux.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<endpoint_id> -- spelled out, because deriving it from the Perl name
would produce C<EndpointId>.

=head2 instance_id

Instance ID. Not used on Linux.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<instance_id> -- spelled out, because deriving it from the Perl name
would produce C<InstanceId>.

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
