package API::Docker::Type::SwarmSpec::Raft;
# ABSTRACT: Raft configuration
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker snapshot_interval => Int;


docker keep_old_snapshots => Int;


docker log_entries_for_slow_followers => Int;


docker election_tick => Int;


docker heartbeat_tick => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::SwarmSpec::Raft - Raft configuration

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<Raft> schema of the C<SwarmSpec> definition in
C<spec/v1.51.yaml>.

=head2 snapshot_interval

The number of log entries between snapshots.

=head2 keep_old_snapshots

The number of snapshots to keep beyond the current snapshot.

=head2 log_entries_for_slow_followers

The number of log entries to keep around to sync up slow followers after a
snapshot is created.

=head2 election_tick

The number of ticks that a follower will wait for a message from the leader
before becoming a candidate and starting an election. C<ElectionTick> must
be greater than C<HeartbeatTick>.

A tick currently defaults to one second, so these translate directly to
seconds currently, but this is NOT guaranteed.

=head2 heartbeat_tick

The number of ticks between heartbeats. Every HeartbeatTick ticks, the
leader will send a heartbeat to the followers.

A tick currently defaults to one second, so these translate directly to
seconds currently, but this is NOT guaranteed.

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
