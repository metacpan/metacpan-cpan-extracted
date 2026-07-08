# ABSTRACT: Activity log writer for karr board operations

package App::karr::ActivityLog;
our $VERSION = '0.400';
use Moo;
use JSON::MaybeXS qw( encode_json decode_json );
use POSIX qw( strftime );


has git => (
    is       => 'ro',
    required => 1,
);


has role => (
    is      => 'ro',
    default => sub { $ENV{KARR_ROLE} || 'user' },
);

sub _sanitize {
    my ($self, $s) = @_;
    $s //= '';
    $s =~ s/[^a-zA-Z0-9._-]/_/g;
    return $s;
}

sub _email {
    my ($self) = @_;
    return $self->git->git_user_email || 'unknown';
}


sub identity {
    my ($self) = @_;
    return $self->_sanitize($self->role) . '/' . $self->_sanitize($self->_email);
}

sub _ref {
    my ($self) = @_;
    return 'refs/karr/log/' . $self->identity;
}

# Pre-role logs were keyed by bare sanitized email. Read them back for the
# default 'user' role so existing history is not orphaned.
sub _legacy_ref {
    my ($self) = @_;
    return 'refs/karr/log/' . $self->_sanitize($self->_email);
}


sub log_entry {
    my ($self, %entry) = @_;
    $entry{ts} //= strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
    my $ref = $self->_ref;
    my $existing = $self->git->read_ref($ref);
    my $line = encode_json(\%entry);
    my $new = $existing ? "$existing\n$line" : $line;
    return $self->git->write_ref($ref, $new);
}


sub entries {
    my ($self) = @_;
    my $content = $self->git->read_ref($self->_ref);
    if ((!defined $content || !length $content) && $self->role eq 'user') {
        $content = $self->git->read_ref($self->_legacy_ref);
    }
    return () unless defined $content && length $content;
    my @entries;
    for my $line (split /\n/, $content) {
        next unless length $line;
        my $decoded = eval { decode_json($line) };
        push @entries, $decoded if $decoded;
    }
    return @entries;
}


sub last_entry {
    my ($self) = @_;
    my @entries = $self->entries;
    return @entries ? $entries[-1] : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::ActivityLog - Activity log writer for karr board operations

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    use App::karr::ActivityLog;
    use App::karr::Git;

    my $git = App::karr::Git->new(dir => '.');
    my $log = App::karr::ActivityLog->new(git => $git, role => 'agent');

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
    );

=head1 DESCRIPTION

Writes append-style JSON log entries to C<refs/karr/log/E<lt>identityE<gt>>
refs. Each entry receives an automatic timestamp if not provided.

The identity is C<E<lt>roleE<gt>/E<lt>emailE<gt>>: the Git user email
(sanitized for ref names) qualified by a B<role> (C<user> or C<agent>). The
role disambiguates a human and an AI agent that share one Git config. It
defaults to the C<KARR_ROLE> environment variable, or C<user>.

=head1 METHODS

=head2 role

The actor role, C<user> (default) or C<agent>. Read from C<KARR_ROLE> when not
given explicitly.

=head2 identity

    my $id = $log->identity;   # e.g. "agent/getty_conflict.industries"

The sanitized C<E<lt>roleE<gt>/E<lt>emailE<gt>> string keying this actor's log.

=head2 log_entry

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
        ts      => '2026-05-15T10:00:00Z',  # optional, auto-generated
    );

Writes a JSON log line to the per-identity ref. The ref path is
C<refs/karr/log/E<lt>roleE<gt>/E<lt>sanitized_emailE<gt>>.

Returns the result of L<Git/write_ref>.

=head2 entries

    my @entries = $log->entries;

Returns the decoded log entries for this identity, oldest first. For the
C<user> role, falls back to the legacy bare-email ref when the role-qualified
ref does not yet exist.

=head2 last_entry

    my $entry = $log->last_entry;

The most recent decoded log entry for this identity, or C<undef> if none.

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
