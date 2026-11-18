package API::Docker::Type::ManagerStatus;
# ABSTRACT: The status of a manager
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker leader => Bool;


docker reachability => Str, enum => [qw( unknown unreachable reachable )];


docker addr => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ManagerStatus - The status of a manager

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ManagerStatus> definition of C<spec/v1.51.yaml>.

It provides the current status of a node's manager component, if the node is
a manager.

=head2 leader

Undocumented upstream. Of the manager component this class describes:
whether it is the one leading. Defaulted to C<false> upstream and C<true> in
the example.

=head2 reachability

Reachability represents the reachability of a node. The swagger enumerates
C<unknown>, C<unreachable> and C<reachable>.

=head2 addr

The IP address and port at which the manager is reachable.

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
