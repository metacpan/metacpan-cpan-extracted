# ABSTRACT: Activity log writer for karr board operations

package App::karr::ActivityLog;
our $VERSION = '0.601';
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

# A log ref is rewritten in full on every append -- that is what a ref blob
# is -- so an uncapped one makes the write path O(n): after 10,000 entries of
# the ~93 bytes karr writes, the blobs written add up to ~93*10000**2/2, about
# 4.6 GB of objects for a log that is 1 MB (#171). Capping a segment caps that:
# a single entry never costs more than one blob of this size, and the total
# written grows linearly. 8 KiB is roughly 80 karr entries, so a board gains
# about one extra ref per 80 mutating commands.
use constant SEGMENT_MAX_BYTES => 8192;

# The one source for the action vocabulary of the board activity log. Every
# entry is written either by a command's log_action (the command's own name,
# hyphenated -- create, move, edit, delete, archive, handoff, needs) or by the
# explicit 'pick' of C<karr pick> (Role::BoardAccess/append_log), so this is
# exactly the set that can appear in refs/karr/log/*. C<karr log --action>
# validates against it and prints it in the usage error, instead of keeping a
# second hand-maintained list that drifts from what the commands actually write
# (ticket #278).
use constant ACTIONS => qw( archive create delete edit handoff move needs pick );


has segment_max_bytes => (
    is      => 'ro',
    default => sub { SEGMENT_MAX_BYTES },
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

# One identity's log is a chain of segment refs, not a single ref:
#
#   refs/karr/log/<role>/<email>          segment 0 -- the only ref karr wrote
#                                         before #171, and still the first one
#                                         written on a fresh board
#   refs/karr/log/<role>/<email>+000001   segment 1, opened when 0 is full
#
# '+' is legal in a git ref name and _encode_component never produces one (it
# encodes to %2B), so a segment name can collide with no identity's own ref.
# The segments are *siblings* of segment 0 rather than children of it, which
# rules out the more obvious .../<email>/000001 spelling: git cannot hold a ref
# and a directory of the same name, so that layout would be unwritable on every
# board that already has a log.
#
# Nothing marks the format. The encoding switch needed refs/karr/meta/encoding
# (see App::karr::Cmd::Repair) because the content could not tell you which of
# two spellings it was in; here the layout is the ref names themselves. A board
# written before #171 has segment 0 and nothing else, which is exactly what a
# board that has not rotated yet looks like, so it is read -- and appended to --
# without migration, and needs no repair pass.
sub _segment_ref {
    my ( $self, $index ) = @_;
    return $index ? sprintf( '%s+%06d', $self->_ref, $index ) : $self->_ref;
}

# The exact set of ref names this identity's log occupies, as one regex: the
# base ref and its '+NNNNNN' segments, nothing else. Takes the base as an
# argument because _ref reaches into libgit2's config for the mail address
# every time, which is nothing per command and a lot per ref in a loop.
sub _own_ref_re {
    my ( $self, $base ) = @_;
    $base //= $self->_ref;
    return qr/\A\Q$base\E(?:\+([0-9]+))?\z/;
}

sub _segment_index {
    my ( $self, $ref ) = @_;
    return $ref =~ $self->_own_ref_re ? ( $1 // 0 ) + 0 : 0;
}

# Every segment of this identity that exists, oldest first -- which is also
# chronological order, because a segment is only ever appended to while it is
# the newest one. The glob is the base ref name, so it also catches any other
# identity whose encoded email merely starts with this one's; the regex is
# what makes the match exact.
sub _segment_refs {
    my ($self) = @_;
    my $base = $self->_ref;
    my $re   = $self->_own_ref_re($base);
    my %index;
    for my $ref ( $self->git->list_refs($base) ) {
        $index{$ref} = ( $1 // 0 ) + 0 if $ref =~ $re;
    }
    return sort { $index{$a} <=> $index{$b} } keys %index;
}

# The segment an append goes to: the newest existing one, or segment 0 when
# this identity has never logged. Read through read_ref_with_oid so the caller
# gets the content together with the OID to guard the write against.
sub _active_segment {
    my ($self) = @_;
    my @refs = $self->_segment_refs;
    return ( $self->_ref, undef, '' ) unless @refs;
    my ( $oid, $content ) = $self->git->read_ref_with_oid( $refs[-1] );
    return ( $refs[-1], $oid, $content // '' );
}


sub owns_ref {
    my ( $self, $ref ) = @_;
    return 0 unless defined $ref;
    return $ref =~ $self->_own_ref_re ? 1 : 0;
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
    #
    # What the CAS is taken against is the *newest segment*, re-resolved on
    # every attempt: rotation is as much a lost race as an append is, and a
    # writer that cached the segment it saw before backing off would append to
    # a segment another writer has already sealed.
    return try {
        $self->git->retry_contended( "log entry to $ref", sub {
            my ( $segment, $current_oid, $current ) = $self->_active_segment;

            # Rotate before the append, never after, so no segment is ever
            # written past the cap and no entry is written twice. A full
            # segment is simply left where it is -- immutable from here on --
            # and the entry opens the next one guarded with expected_old =>
            # undef, i.e. "only if that ref does not exist yet". Two writers
            # rotating at the same moment therefore cannot clobber each other:
            # the loser gets 0, re-reads, and appends to the segment the winner
            # opened. An entry bigger than the whole cap still lands, in a
            # segment of its own, rather than looping forever.
            if ( length($current)
                && length($current) + 1 + length($line) > $self->segment_max_bytes )
            {
                $segment = $self->_segment_ref( $self->_segment_index($segment) + 1 );
                ( $current_oid, $current ) = ( undef, '' );
            }

            my $new = length $current ? "$current\n$line" : $line;
            return $self->git->write_ref_cas( $segment, $new, $current_oid ) ? 1 : ();
        } );
    } catch {
        warn "karr: activity log write to '$ref' failed: $_";
        0;
    };
}


sub entries {
    my ($self) = @_;
    return map { $self->_entries_from($_) }
        ( $self->_legacy_refs, $self->_segment_refs );
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
    for my $ref ( reverse( $self->_legacy_refs, $self->_segment_refs ) ) {
        my @entries = $self->_entries_from($ref);
        return $entries[-1] if @entries;
    }
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::ActivityLog - Activity log writer for karr board operations

=head1 VERSION

version 0.601

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

=head2 Segments

One identity's log is a chain of refs, not one ref:

    refs/karr/log/<role>/<email>          segment 0
    refs/karr/log/<role>/<email>+000001   segment 1
    refs/karr/log/<role>/<email>+000002   ...

An entry is appended to the newest segment until that segment reaches
L</segment_max_bytes>; the next entry then opens the following one, and the
full segment is never rewritten again. A ref blob is rewritten whole on every
append, so a single unbounded log ref made each entry cost a copy of the entire
history: 10,000 entries of the ~93 bytes karr writes added up to about 4.6 GB
of objects for a 1 MB log, growing quadratically (#171). Segmenting bounds one
write by the cap instead of by the history, which makes the total linear.

The layout needs no marker ref and no migration, unlike the encoding switch
that C<refs/karr/meta/encoding> and L<App::karr::Cmd::Repair> exist for: which
segments a log has is visible in the ref names. A board written before the
split has segment 0 and nothing else -- indistinguishable from a board that has
not rotated yet -- so it keeps being read and appended to as it was.

Everything that reads the whole log by walking C<refs/karr/log/*> --
C<karr log>, C<karr context> -- picks the segments up unchanged. C<karr
context>, which excludes the invoking identity's own entries, uses
L</owns_ref> rather than an equality test so a rotated segment does not read as
another agent.

=head2 git

The L<App::karr::Git> instance this log reads and writes refs through.
Required.

=head2 role

The actor role, C<user> (default) or C<agent>. Read from C<KARR_ROLE> when not
given explicitly.

=head2 segment_max_bytes

How large (in characters) the active log segment may grow before the next entry
opens a new one; 8192 by default. Set explicitly only by the tests, which have
to see rotation without writing the thousands of entries the real cap needs.

=head1 METHODS

=head2 identity

    my $id = $log->identity;   # e.g. "agent/getty%40conflict.industries"

The percent-encoded C<E<lt>roleE<gt>/E<lt>emailE<gt>> string keying this
actor's log. Always a legal pair of git ref components; see
L</decode_identity> for the inverse.

=head2 decode_identity

    my ($role, $email) = App::karr::ActivityLog->decode_identity($id);

Turns an encoded identity -- the part of a C<refs/karr/log/*> ref name below
C<refs/karr/log/> -- back into the role and mail address it was built from.

=head2 owns_ref

    next if $log->owns_ref($ref);

True when C<$ref> is one of this identity's log refs under the current naming
scheme -- segment 0 (C<refs/karr/log/>L</identity>) or any of its rotated
segments. Refs left behind by the pre-#75 schemes are not claimed;
the internal C<_legacy_refs> is what reads those.

C<karr context> uses this to leave the invoking identity's own entries out of
the cross-agent activity it summarises: comparing against L</identity> alone
would have counted every rotated segment as somebody else's log the moment one
identity's history outgrew a single ref.

=head2 log_entry

    $log->log_entry(
        agent   => 'agent-fox',
        action  => 'pick',
        task_id => 5,
        detail  => 'in-progress',
        ts      => '2026-05-15T10:00:00Z',  # optional, auto-generated
    );

Writes a JSON log line to this identity's newest log segment, opening the next
one when that segment has reached L</segment_max_bytes> (see
L</Segments>). The first segment is C<refs/karr/log/E<lt>roleE<gt>/E<lt>encoded_emailE<gt>>.

Returns the result of L<Git/write_ref_cas>, or C<0> after warning if the entry
could not be written. It never dies: by the time a command logs, it has
already written the task the entry describes, so a failure here must not take
the command down with a half-applied mutation behind it (#75).

=head2 entries

    my @entries = $log->entries;

Returns the decoded log entries for this identity, oldest first. Refs written
under the pre-#75 naming schemes are read first and merged in ahead of the
current ref, which is also their chronological order: a board stops being
written under an old scheme the moment it is touched by a karr that knows the
new one. The current scheme's segments (L</Segments>) follow in segment order,
which is chronological for the same reason: only the newest segment is ever
appended to.

=head2 last_entry

    my $entry = $log->last_entry;

The most recent decoded log entry for this identity, or C<undef> if none.

Reads the refs newest-first and stops at the first one that yields an entry, so
on a segmented log this is one small ref read rather than the whole history --
the point of L</Segments> being lost if the cheap write path were paid for with
an expensive read of the last line.

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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
