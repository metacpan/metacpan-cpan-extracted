package API::Docker::Type::Service::UpdateStatus;
# ABSTRACT: The status of a service update
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker state => Str, enum => [qw( updating paused completed )];


docker started_at => Str;


docker completed_at => Str;


docker message => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Service::UpdateStatus - The status of a service update

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<UpdateStatus> schema of the C<Service>
definition in C<spec/v1.51.yaml>.

=head2 state

Undocumented upstream. How far the rolling update has got. L</started_at>
and L</completed_at> bracket it in time and L</message> says in words what
it is doing. The swagger enumerates C<updating>, C<paused> and C<completed>.

=head2 started_at

Undocumented upstream. RFC 3339, with no example given.

=head2 completed_at

Undocumented upstream. The other end of L</started_at>, in the same format.

=head2 message

Undocumented upstream. Free text about the update, the human-readable half
of L</state>.

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
