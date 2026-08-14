# ABSTRACT: Activity log writer for karr board operations

package App::karr::ActivityLog;
our $VERSION = '0.500';
use Moo;
use App::karr::Encoding qw( json_encode json_decode );
use POSIX qw( strftime );
use Encode qw( encode decode FB_CROAK );
use Try::Tiny;
use Git::Native;


has git => (
    is       => 'ro',
    required => 1,
);


has role => (
    is      => 'ro',
    default => sub { $ENV{KARR_ROLE} || 'user' },
);

# Percent-encode one identity component into a single git ref path component.
#
# git-check-ref-format forbids far more than the old s/[^a-zA-Z0-9._-]/_/g
# mapped away: a component may not start with '.', contain '..', or end in '.'
# or '.lock', and the whole name may not contain a space, a control character,
# '~^:?*[', '\' or '@{'. An ordinary address like a..b@example.com therefore
# produced a name libgit2 refuses outright (#75), and because every unsafe
# character collapsed onto '_' four different addresses could share one log.
#
# Encoding the octets instead fixes both: '.' '-' '_' and alphanumerics stay
# literal so the common address remains readable, everything else -- '%'
# included, which is what makes _decode_component an exact inverse -- becomes
# %XX, and the few dots that would still break a ref name are encoded too. The
# result is pure [A-Za-z0-9%._-], always a legal component, never empty.
sub _encode_component {
    my ( $self, $s ) = @_;
    return 'unknown' unless defined $s && length $s;

    # git_user_email arrives straight out of libgit2 as UTF-8 octets, while a
    # value that already crossed karr's character boundary arrives as
    # characters. Upgrade only the latter, so both spellings of one address
    # encode to the same ref name and no email can turn into mojibake.
    my $octets = utf8::is_utf8($s) ? encode( 'UTF-8', $s ) : $s;

    $octets =~ s/([^A-Za-z0-9._-])/sprintf('%%%02X', ord($1))/ge;
    $octets =~ s/(\.{2,})/'%2E' x length($1)/ge;   # no '..'
    $octets =~ s/\A\./%2E/;                        # no leading '.'
    $octets =~ s/\.\z/%2E/;                        # no trailing '.'
    $octets =~ s/\.lock\z/%2Elock/;                # no trailing '.lock'
    return $octets;
}

sub _decode_component {
    my ( $self, $encoded ) = @_;
    return '' unless defined $encoded && length $encoded;
    my $octets = $encoded;
    $octets =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    # A component that is not valid UTF-8 was never written by us; hand back
    # the octets rather than substituting U+FFFD into somebody's address.
    return try { decode( 'UTF-8', $octets, FB_CROAK ) } catch { $octets };
}

sub _email {
    my ($self) = @_;
    return $self->git->git_user_email || 'unknown';
}

# The role attribute can be handed an empty string explicitly, and an empty
# component would make the ref name a legal-looking 'refs/karr/log//x'.
sub _role {
    my ($self) = @_;
    my $role = $self->role;
    return defined $role && length $role ? $role : 'user';
}


sub identity {
    my ($self) = @_;
    return $self->_encode_component( $self->_role ) . '/'
         . $self->_encode_component( $self->_email );
}


sub decode_identity {
    my ( $self, $identity ) = @_;
    my ( $role, $email ) = split m{/}, ( $identity // '' ), 2;
    return ( $self->_decode_component($role), $self->_decode_component($email) );
}

sub _ref {
    my ($self) = @_;
    return 'refs/karr/log/' . $self->identity;
}

# The lossy pre-#75 mapping, kept only to find refs written with it.
sub _legacy_sanitize {
    my ( $self, $s ) = @_;
    $s //= '';
    $s =~ s/[^a-zA-Z0-9._-]/_/g;
    return $s;
}

# Ref names earlier karr versions logged to, oldest scheme first: before the
# role joined the identity the log was keyed by bare sanitized email, and up to
# #75 both components went through _legacy_sanitize. Nothing is migrated -- the
# names are only read (see entries), so no history is orphaned and no entry is
# ever counted twice.
sub _legacy_refs {
    my ($self) = @_;
    my $email = $self->_legacy_sanitize( $self->_email );
    my @refs;
    push @refs, "refs/karr/log/$email" if $self->_role eq 'user';
    push @refs, 'refs/karr/log/'
        . $self->_legacy_sanitize( $self->_role ) . "/$email";
    my $current = $self->_ref;
    return grep { $_ ne $current } @refs;
}


sub log_entry {
    my ($self, %entry) = @_;
    $entry{ts} //= strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
    my $ref = $self->_ref;

    # _encode_component makes this unreachable for any identity; it stays as
    # the guarantee that the check happens before the first write, not as the
    # libgit2 exception halfway through one.
    unless ( Git::Native->reference_name_is_valid($ref) ) {
        warn "karr: not logging activity, '$ref' is not a valid git ref name\n";
        return 0;
    }

    my $line = json_encode(\%entry);
    # Read-modify-write appended to the log ref used unguarded write_ref; two
    # concurrent writers both read the same existing content, both wrote their
    # append, and the loser overwrote the winner -- ticket #156: a task is
    # saved, its log entry is dropped, and the log starts lying about what
    # happened. read_ref_with_oid + write_ref_cas inside retry_contended turns
    # the race into a textbook CAS that backs off and re-reads on contention.
    # retry_contended treats an empty return as "lost the race, try again";
    # write_ref_cas returns 0 on contention, so we map that to () here.
    return try {
        $self->git->retry_contended( "log entry to $ref", sub {
            my ( $current_oid, $current ) = $self->git->read_ref_with_oid($ref);
            my $new = $current ? "$current\n$line" : $line;
            return $self->git->write_ref_cas( $ref, $new, $current_oid ) ? 1 : ();
        } );
    } catch {
        warn "karr: activity log write to '$ref' failed: $_";
        0;
    };
}


sub entries {
    my ($self) = @_;
    return map { $self->_entries_from($_) } ( $self->_legacy_refs, $self->_ref );
}

sub _entries_from {
    my ( $self, $ref ) = @_;
    my $content = $self->git->read_ref($ref);
    return () unless defined $content && length $content;
    my @entries;
    for my $line (split /\n/, $content) {
        next unless length $line;
        my $decoded = eval { json_decode($line) };
        push @entries, $self->git->maybe_repair_legacy($decoded) if $decoded;
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

version 0.500

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
percent-encoded into a ref name and qualified by a B<role> (C<user> or
C<agent>). The role disambiguates a human and an AI agent that share one Git
config. It defaults to the C<KARR_ROLE> environment variable, or C<user>.

=head2 Identity encoding

Git's ref-name grammar is far narrower than what a mail address may contain,
so each component is percent-encoded (L</identity>, L</decode_identity>).
C<[A-Za-z0-9._-]> survives literally to keep the common address readable; every
other octet becomes C<%XX>, including C<%> itself, which makes the mapping
injective -- two different addresses can no longer land on one ref.

Older karr releases replaced every unsafe character with C<_>, which both
collided (C<a b@x> and C<a-b@x> shared a ref) and produced names git rejects
(C<a..b@x>, C<x@y.lock>). Refs written that way are not rewritten: L</entries>
reads them alongside the current one so existing history stays visible.

=head1 METHODS

=head2 role

The actor role, C<user> (default) or C<agent>. Read from C<KARR_ROLE> when not
given explicitly.

=head2 identity

    my $id = $log->identity;   # e.g. "agent/getty%40conflict.industries"

The percent-encoded C<E<lt>roleE<gt>/E<lt>emailE<gt>> string keying this
actor's log. Always a legal pair of git ref components; see
L</decode_identity> for the inverse.

=head2 decode_identity

    my ($role, $email) = App::karr::ActivityLog->decode_identity($id);

Turns an encoded identity -- the part of a C<refs/karr/log/*> ref name below
C<refs/karr/log/> -- back into the role and mail address it was built from.

=head2 log_entry

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
        ts      => '2026-05-15T10:00:00Z',  # optional, auto-generated
    );

Writes a JSON log line to the per-identity ref. The ref path is
C<refs/karr/log/E<lt>roleE<gt>/E<lt>encoded_emailE<gt>>.

Returns the result of L<Git/write_ref>, or C<0> after warning if the entry
could not be written. It never dies: by the time a command logs, it has
already written the task the entry describes, so a failure here must not take
the command down with a half-applied mutation behind it (#75).

=head2 entries

    my @entries = $log->entries;

Returns the decoded log entries for this identity, oldest first. Refs written
under the pre-#75 naming schemes are read first and merged in ahead of the
current ref, which is also their chronological order: a board stops being
written under an old scheme the moment it is touched by a karr that knows the
new one.

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
