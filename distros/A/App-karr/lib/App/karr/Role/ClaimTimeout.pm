# ABSTRACT: Shared claim timeout logic

package App::karr::Role::ClaimTimeout;
our $VERSION = '0.102';
use Moo::Role;
use Time::Piece;


sub _parse_timeout {
    my ($self, $timeout_str) = @_;
    return 3600 unless $timeout_str;
    if ($timeout_str =~ /^(\d+)h$/) { return $1 * 3600; }
    if ($timeout_str =~ /^(\d+)m$/) { return $1 * 60; }
    return 3600;
}

sub _claim_expired {
    my ($self, $task, $timeout_secs) = @_;
    return 0 unless $task->has_claimed_at;
    my $claimed = eval { Time::Piece->strptime($task->claimed_at =~ s/Z$//r, '%Y-%m-%dT%H:%M:%S') };
    return 0 unless $claimed;
    return (gmtime() - $claimed) > $timeout_secs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ClaimTimeout - Shared claim timeout logic

=head1 VERSION

version 0.102

=head1 DESCRIPTION

Shared helper role for commands that need to interpret C<claim_timeout> values
and determine whether an existing claim should still block other agents.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
