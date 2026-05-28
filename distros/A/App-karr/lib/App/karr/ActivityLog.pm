# ABSTRACT: Activity log writer for karr board operations

package App::karr::ActivityLog;
our $VERSION = '0.300';
use Moo;
use JSON::MaybeXS qw( encode_json );
use POSIX qw( strftime );


has git => (
    is       => 'ro',
    required => 1,
);


sub log_entry {
    my ($self, %entry) = @_;
    $entry{ts} //= strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
    my $identity = $self->_identity;
    my $ref = "refs/karr/log/$identity";
    my $existing = $self->git->read_ref($ref);
    my $line = encode_json(\%entry);
    my $new = $existing ? "$existing\n$line" : $line;
    return $self->git->write_ref($ref, $new);
}

sub _identity {
    my ($self) = @_;
    my $email = $self->git->git_user_email || 'unknown';
    $email =~ s/[^a-zA-Z0-9._-]/_/g;
    return $email;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::ActivityLog - Activity log writer for karr board operations

=head1 VERSION

version 0.300

=head1 SYNOPSIS

    use App::karr::ActivityLog;
    use App::karr::Git;

    my $git = App::karr::Git->new(dir => '.');
    my $log = App::karr::ActivityLog->new(git => $git);

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
    );

=head1 DESCRIPTION

Writes append-style JSON log entries to C<refs/karr/log/E<lt>identityE<gt>>
refs. Each entry receives an automatic timestamp if not provided.

The identity is derived from the Git user email, sanitized for use in ref
names.

=head1 METHODS

=head2 log_entry

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
        ts      => '2026-05-15T10:00:00Z',  # optional, auto-generated
    );

Writes a JSON log line to the per-identity ref. The ref path is
C<refs/karr/log/E<lt>sanitized_emailE<gt>>.

Returns the result of L<Git/write_ref>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
