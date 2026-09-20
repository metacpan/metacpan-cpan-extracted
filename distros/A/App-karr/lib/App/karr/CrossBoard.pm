# ABSTRACT: Cross-board dependencies -- a link from a card here to a card on another board

package App::karr::CrossBoard;
our $VERSION = '0.601';
use Moo;
use Path::Tiny;
use Try::Tiny;
# Imported, not called through the package: App::karr::Encoding owns every
# character/octet crossing, and the fleet config file is one of them.
use App::karr::Encoding qw( yaml_load );
use App::karr::Git;
use App::karr::BoardStore;


use constant NEEDS_PREFIX          => 'needs:';
use constant ESCALATED_FROM_PREFIX => 'escalated-from:';

# A board name may not contain a path separator, a '#', a ',', a ':' or
# whitespace: the first is what keeps a machine-local path off a card, the rest
# are the characters the reference syntax and the tag list are made of. It may
# not start with '-' or '.' either, so a name can never be mistaken for an
# option or for a relative path.
my $BOARD_RE = qr/[A-Za-z0-9_][A-Za-z0-9._-]*/;
my $REF_RE   = qr/\A($BOARD_RE)\#([0-9]+)\z/;

sub parse_ref {
    my ( $class, $flag, $raw ) = @_;
    $raw = '' unless defined $raw;
    my ( $board, $id ) = $raw =~ $REF_RE;
    # The same "Usage error:" marker App::karr::Role::ExitCodes emits and
    # F<bin/karr> maps to exit 2, raised from a plain class so the commands do
    # not each repeat the sentence -- the arrangement App::karr::Config's
    # validate_* helpers already use.
    die sprintf
      "Usage error: invalid %s reference \"%s\" (expected BOARD#ID -- the "
      . "other board's name and a task id on it; a path is not a board name)\n",
      $flag, $raw
      unless defined $board;
    return { board => $board, id => $id + 0 };
}


sub parse_refs {
    my ( $class, $flag, $value ) = @_;
    my ( @refs, %seen );
    for my $raw ( split /,/, ( defined $value ? $value : '' ) ) {
        my $ref = $class->parse_ref( $flag, $raw );
        push @refs, $ref unless $seen{ $class->format_ref($ref) }++;
    }
    die "Usage error: $flag requires at least one BOARD#ID reference\n"
      unless @refs;
    return \@refs;
}


sub format_ref {
    my ( $class, $ref ) = @_;
    return sprintf '%s#%d', $ref->{board}, $ref->{id};
}


sub needs_tag {
    my ( $class, $ref ) = @_;
    return NEEDS_PREFIX . $class->format_ref($ref);
}

sub escalated_from_tag {
    my ( $class, $ref ) = @_;
    return ESCALATED_FROM_PREFIX . $class->format_ref($ref);
}


sub _refs_from_tags {
    my ( $class, $task, $prefix ) = @_;
    my @refs;
    for my $tag ( @{ $task->tags } ) {
        next unless index( $tag, $prefix ) == 0;
        my $raw = substr $tag, length $prefix;
        my ( $board, $id ) = $raw =~ $REF_RE or next;
        push @refs, { board => $board, id => $id + 0 };
    }
    return @refs;
}

sub needs_of {
    my ( $class, $task ) = @_;
    return $class->_refs_from_tags( $task, NEEDS_PREFIX );
}

sub escalated_from_of {
    my ( $class, $task ) = @_;
    return $class->_refs_from_tags( $task, ESCALATED_FROM_PREFIX );
}


sub add_needs {
    my ( $class, $task, $refs ) = @_;
    my %have = map { $_ => 1 } @{ $task->tags };
    my @new = grep { !$have{$_} } map { $class->needs_tag($_) } @$refs;
    push @{ $task->tags }, @new;
    return scalar @new;
}

sub remove_needs {
    my ( $class, $task, $refs ) = @_;
    my %drop = map { $class->needs_tag($_) => 1 } @$refs;
    my $before = @{ $task->tags };
    $task->tags( [ grep { !$drop{$_} } @{ $task->tags } ] );
    return $before - @{ $task->tags };
}


# ---------------------------------------------------------------------------
# Resolution: board name -> directory on this machine -> the far card
# ---------------------------------------------------------------------------

has overrides => (
    is      => 'ro',
    default => sub { {} },
);


has config_file => (
    is        => 'ro',
    predicate => 1,
);


has config_data => (
    is        => 'ro',
    predicate => 1,
);


has _candidates => ( is => 'lazy' );

has _stores => (
    is      => 'ro',
    default => sub { {} },
);

sub _config_data {
    my ($self) = @_;

    if ( $self->has_config_data ) {
        my $data = $self->config_data;
        return ref $data eq 'HASH' ? $data : {};
    }

    my $file = $self->config_file;
    my $explicit = $self->has_config_file && defined $file && length $file;
    $file = path( $ENV{HOME} // '' )->child(qw( .config karr-foundation config.yml ))
      unless $explicit;
    $file = path($file);

    unless ( $file->is_file ) {
        die "Fleet config not found: $file\n" if $explicit;
        return {};
    }

    my $data = try { yaml_load( $file->slurp_utf8 ) }
    catch { die "Cannot parse fleet config $file: $_" };
    return ref $data eq 'HASH' ? $data : {};
}

# Board name -> the directories on this machine that could be it. Both of
# karr-foundation's discovery keys feed it: `dirs:` names repository roots
# outright, `scan:` names parents whose direct children are candidates. Nothing
# here asks whether a candidate actually holds a board -- that question is
# answered once, later, by the board itself in _store_for, so a `scan:` parent
# with fifty unrelated subdirectories costs a hash and not fifty git opens.
sub _build__candidates {
    my ($self) = @_;
    my $data = $self->_config_data;

    my %by_name;
    my $add = sub {
        my ($dir) = @_;
        push @{ $by_name{ $dir->basename } }, $dir;
    };

    for my $dir ( @{ $data->{dirs} // [] } ) {
        my $p = path($dir);
        $add->($p) if $p->is_dir;
    }
    for my $scan ( @{ $data->{scan} // [] } ) {
        my $p = path($scan);
        next unless $p->is_dir;
        for my $child ( $p->children ) {
            $add->($child) if $child->is_dir;
        }
    }

    # A repository reachable through both keys is one candidate, not an
    # ambiguity -- the same realpath collapse App::karr::Foundation makes for
    # the same reason (#166).
    for my $name ( keys %by_name ) {
        my ( %seen, @uniq );
        for my $dir ( @{ $by_name{$name} } ) {
            my $key = try { $dir->realpath } catch { $dir->absolute };
            push @uniq, $dir unless $seen{"$key"}++;
        }
        $by_name{$name} = \@uniq;
    }
    return \%by_name;
}

sub resolve {
    my ( $self, $name ) = @_;

    my $override = $self->overrides->{$name};
    return ( path($override), undef ) if defined $override && length $override;

    my $found = $self->_candidates->{$name} // [];
    return ( undef,
        "unknown board '$name' (no repository of that name in this machine's "
          . "fleet config; name it with --board $name=PATH)" )
      unless @$found;
    return ( undef,
        "ambiguous board '$name' (" . join( ', ', map { "$_" } @$found )
          . "; name the one you mean with --board $name=PATH)" )
      if @$found > 1;
    return ( $found->[0], undef );
}


# The far board, or undef when that directory holds no karr board. Cached per
# directory: a report over a dozen cards waiting on the same board opens it
# once.
sub _store_for {
    my ( $self, $dir ) = @_;
    my $key = "$dir";
    return $self->_stores->{$key} if exists $self->_stores->{$key};

    my $store = try {
        return undef unless $dir->is_dir;
        my $s = App::karr::BoardStore->new(
            git => App::karr::Git->new( dir => "$dir" ) );
        return $s->board_exists ? $s : undef;
    }
    catch { undef };
    return $self->_stores->{$key} = $store;
}

sub link_state {
    my ( $self, $ref, %opt ) = @_;

    my %state = (
        ref      => $self->format_ref($ref),
        board    => $ref->{board},
        task     => $ref->{id},
        verified => 0,
    );

    my ( $dir, $why ) = $self->resolve( $ref->{board} );
    return { %state, state => 'unknown-board', detail => $why } unless $dir;

    my $store = $self->_store_for($dir);
    return {
        %state,
        state  => 'no-board',
        detail => "no karr board in $dir",
    } unless $store;

    my $far = try { $store->find_task( $ref->{id} ) } catch { undef };

    # kanban-md treats a dependency on an id its board does not have as
    # satisfied, so a dependent card is recoverable after a hard delete
    # (internal/board/filter.go:151). karr already declines that for
    # depends_on (App::karr::Role::DependencyCheck, #123) and declines it
    # harder here: settling a link because the ticket somebody was waiting for
    # cannot be found would unblock a card on the strength of a card nobody can
    # read. It is reported and left alone.
    return {
        %state,
        state  => 'missing',
        detail => sprintf( 'task %d does not exist on board %s', $ref->{id}, $ref->{board} ),
    } unless $far;

    # The far board's own terminal statuses, never a hardcoded `done`: a fleet
    # member imported from kanban-md may call its final column anything (#67).
    my $settled = $store->is_terminal_status( $far->status );

    my @back = $self->escalated_from_of($far);
    my $origin = $opt{origin};
    my $verified = 0;
    if ($origin) {
        my $want = $self->format_ref($origin);
        $verified = ( grep { $self->format_ref($_) eq $want } @back ) ? 1 : 0;
    }

    return {
        %state,
        state    => $settled ? 'settled' : 'open',
        status   => $far->status,
        title    => $far->title,
        verified => $verified,
        ( @back ? ( back_refs => [ map { $self->format_ref($_) } @back ] ) : () ),
        detail => sprintf( '%s (%s)', $far->status, $settled ? 'settled' : 'open' ),
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::CrossBoard - Cross-board dependencies -- a link from a card here to a card on another board

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    # the syntax half -- class methods, no board needed
    my $refs = App::karr::CrossBoard->parse_refs( '--needs', 'other-repo#7' );
    my @open = App::karr::CrossBoard->needs_of($task);

    # the resolution half -- needs to know where the other board is
    my $fleet = App::karr::CrossBoard->new( overrides => { 'other-repo' => $path } );
    my $state = $fleet->link_state( $refs->[0], origin => { board => 'home', id => 5 } );

=head1 DESCRIPTION

C<--depends-on> is board-local. In a fleet the most common real interruption is
"this cannot be done until X is fixed somewhere else", and that X lives in
another repository. The escalation protocol karr-foundation's spec writes down
(C<karr get-refs refs/karr-foundation/spec/fleet-execution.md>) is a convention
and nothing more: raise a card in the other repository tagged
C<< escalated-from:<repo>#<id> >>, block your own, release the claim and leave.
Nothing checks that the two cards name each other, and nothing lifts the block
when the other card is closed.

This module is the explicit link that makes both ends resolvable (ticket #192).
It has two halves that deliberately do not know about each other:

=over 4

=item * B<the syntax> -- what a cross-board reference is, how it is written on
a card and how it is read back. Class methods, usable anywhere, no repository
involved.

=item * B<the resolution> -- which directory on I<this machine> a board name
means, and what state the card at the far end is in. An object, because that
answer is per-machine configuration and has to be built before it can be asked.

=back

=head2 What the card carries, and what it does not

A reference is C<< <board>#<id> >>: a board B<name> and a task id. Never a
path. That split is the epic's dividing line -- coordination is shared and
travels in refs, execution is local -- and a path fails it on the first test:
two clones of the same fleet have the same cards and different directories, so
a path written onto a card is wrong on every machine but the one that wrote it.
L</parse_ref> therefore refuses anything with a C</> in the board name, rather
than accepting it and letting the mistake travel.

The name is the fleet's own name for the repository, which is its directory
basename -- the name C<karr-foundation --status> already prints and the name
the spec's C<< escalated-from:<repo>#<id> >> convention already uses. Turning
that name into a directory is L</resolve>'s job, from local configuration.

=head2 Why a tag and not a frontmatter field

The link is stored as a tag: C<< needs:<board>#<id> >> on the waiting card,
C<< escalated-from:<board>#<id> >> on the card raised in the other repository.

A new frontmatter field was the obvious alternative and is the worse one. The
task document is interop-compatible with kanban-md, which unmarshals into a Go
struct and marshals back out of it: a key it does not model survives being read
and is B<dropped the first time it writes the card>. karr keeps unknown keys
(L<App::karr::Task/extra>), kanban-md does not reciprocate, so a cross-board
link stored that way would disappear through exactly the bridge the shared
format exists for. C<tags> is modelled on both sides and survives. The field
that would otherwise be the natural home, C<depends_on>, cannot take it at all:
it is an C<IntSlice> over there, and a string in it makes the card unreadable
rather than merely lossy.

The cost is stated rather than hidden: C<< karr edit --add-tag needs:whatever >>
bypasses the validation this module does, and C<--remove-tag> can break a link.
That is true of every convention layered on a free-text field; the typed doors
(C<< karr create --needs >>, C<< karr edit --add-needs >>, C<karr needs>) are
the documented ones, and they are what makes the link explicit -- not the slot
it is stored in.

=head2 What a link does not do

Nothing. A cross-board link blocks no command, exactly as C<depends_on> blocks
none (ticket #123): C<karr pick> hands the card over and says what it is
waiting on, and L<App::karr::Foundation::Picker> does not filter on it either,
because foundation must not become stricter than the board it coordinates
(ticket #185).

What keeps the waiting card out of the assignable set is the C<blocked> flag
the escalating agent sets on purpose -- the link is the fact, C<blocked> is the
decision. C<< karr needs --resolve >> is the missing half: when the last link
on a card settles, it drops the link and lifts that block.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Needs>, L<App::karr::Task>,
L<App::karr::Role::DependencyCheck>, L<App::karr::Foundation>

=head2 parse_ref

    my $ref = App::karr::CrossBoard->parse_ref( '--needs', 'other-repo#7' );

Parses one C<< <board>#<id> >> reference into C<< { board => 'other-repo', id
=> 7 } >>, with the id numified so it round-trips as a number through YAML and
C<--json>. Anything else is a usage error (exit 2) naming the flag and the
value -- including, deliberately, anything path-shaped, because a path on a
card is wrong on every machine but the one that wrote it.

=head2 parse_refs

    my $refs = App::karr::CrossBoard->parse_refs( '--needs', 'a#1,b#2' );

L</parse_ref> over a comma-separated list, in order, duplicates collapsed --
the shape L<App::karr::Role::DependencyArgs/parse_dependency_ids> gives the
local dependency flags, and refused on the same terms: one bad reference
condemns the whole invocation, because it is wrong for every id in a batch at
once. An empty value is a usage error rather than an empty list.

=head2 format_ref

    my $text = App::karr::CrossBoard->format_ref($ref);   # "other-repo#7"

The inverse of L</parse_ref>: the canonical text form of a reference, which is
also what goes on the card behind the tag prefix.

=head2 needs_tag

=head2 escalated_from_tag

    my $tag = App::karr::CrossBoard->needs_tag($ref);   # "needs:other-repo#7"

The tag a reference is stored as: C<needs:> on the waiting card,
C<escalated-from:> on the card raised in the other repository. See
L</Why a tag and not a frontmatter field>.

=head2 needs_of

=head2 escalated_from_of

    my @refs = App::karr::CrossBoard->needs_of($task);

The cross-board references a card carries, in tag order, as the hashrefs
L</parse_ref> returns. A tag that carries the prefix but not a well-formed
reference is skipped rather than reported: C<tags> is a free-text field, karr
owns the doors that write these, and a third state for a hand-typed tag would
be surface bought with nothing measured.

=head2 add_needs

=head2 remove_needs

    App::karr::CrossBoard->add_needs( $task, $refs );

Append-unique and remove, the shape C<--add-tag>/C<--remove-tag> and
C<--add-depends-on>/C<--remove-depends-on> already have, returning how many
tags actually changed. Removing a link the card does not carry is a no-op and
stays legal -- it is how a link to a card that was deleted on the other board
is cleaned up.

=head2 overrides

Board name to directory, supplied by the invocation (C<< karr needs --board
NAME=PATH >>) and consulted before the fleet config. What it is for: a fleet
member the local config does not list, a one-off check, and tests, which must
never depend on the developer's own C<~/.config>.

=head2 config_file

The fleet config to read board locations from, defaulting to
F<~/.config/karr-foundation/config.yml> when not given. That file is where this
machine's view of the fleet already lives -- C<dirs:>, C<scan:> and C<hub:> --
and a second local file describing the same fleet would be a second thing to
keep in step with it, which is the argument L<App::karr::Foundation> used for
resolving the hub exactly once.

A config file that was named explicitly and is not there is an error; the
default location simply being absent is not, because most repositories are not
part of a fleet at all.

=head2 config_data

The same fleet config, B<already parsed>, for a caller that has read it
itself -- L<App::karr::Foundation> holds it as it runs, and its chain executor
resolves cross-board links out of that (L<App::karr::Foundation::Executor>).
Supplied, it wins over L</config_file> and nothing on disk is read.

It is not a second source: it is the one source, read once. Handing the
directories over instead would be, because C<dirs:>, C<scan:> and the basename
match that turns them into a board name are one rule and belong in one place.
Reading the file again here would be a second answer where the caller's own
copy came from somewhere else -- C<--config>, or a foundation constructed with
its configuration in hand -- and the two would then disagree about which fleet
this machine is part of.

=head2 resolve

    my ( $dir, $why ) = $fleet->resolve('other-repo');

Turns a board name into a directory on this machine, or into a sentence saying
why it could not: L</overrides> first, then the fleet config's C<dirs:> and the
direct children of its C<scan:> parents, matched on the directory basename --
the name C<karr-foundation --status> prints and the name the escalation
convention already uses.

An unknown name and an ambiguous one are both answers, not failures. A machine
that holds four repositories of a six-repository fleet still has an honest
report to give about the four, and a command that died on the first name it
could not place would give none.

=head2 link_state

    my $state = $fleet->link_state( $ref, origin => { board => 'home', id => 5 } );

What is known about one link right now, as a plain hashref carrying C<ref>,
C<board>, C<task>, C<state>, C<verified> and a human C<detail> sentence, plus
C<status>/C<title>/C<back_refs> where the far card could be read. C<state> is
one of:

=over 4

=item * C<settled> -- the far card is in one of the B<far> board's own terminal
statuses. This is the only state C<< karr needs --resolve >> acts on.

=item * C<open> -- the far card exists and is not finished.

=item * C<missing> -- the board is here, the card is not.

=item * C<unknown-board> -- the name could not be placed on this machine.
C<detail> says how to place it.

=item * C<no-board> -- the directory is there and holds no karr board.

=back

C<origin> is the near card as a reference, and is what turns the far card's
C<< escalated-from:<board>#<id> >> tag into a verdict: C<verified> is true only
when the far card names this card back. That is the half of the escalation
protocol nothing checked before -- a convention both ends merely believed in.

Nothing is fetched. The far board is read exactly as it stands in that working
copy, so what this reports is as fresh as that repository's last C<karr sync>.
Pulling somebody else's repository from inside a command run here would be a
transport decision taken behind the operator's back, and a fleet run syncs each
repository as it reaches it anyway.

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
