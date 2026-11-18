package API::Docker::Type::ContainerThrottlingData;
# ABSTRACT: CPU throttling stats of the container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker periods => Int, wire => 'periods', since => '1.51';


docker throttled_periods => Int, wire => 'throttled_periods', since => '1.51';


docker throttled_time => Int, wire => 'throttled_time', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerThrottlingData - CPU throttling stats of the container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerThrottlingData> definition of
C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=head2 periods

Number of periods with throttling active. Serialised as C<periods> --
spelled out, because deriving it from the Perl name would produce
C<Periods>.

=head2 throttled_periods

Number of periods when the container hit its throttling limit. Serialised as
C<throttled_periods> -- spelled out, because deriving it from the Perl name
would produce C<ThrottledPeriods>.

=head2 throttled_time

Aggregated time (in nanoseconds) the container was throttled for. Serialised
as C<throttled_time> -- spelled out, because deriving it from the Perl name
would produce C<ThrottledTime>.

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
