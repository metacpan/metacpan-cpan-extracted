# ABSTRACT: Role providing minimal board discovery and config access

package App::karr::Role::BoardDiscovery;
our $VERSION = '0.500';
use Moo::Role;
use MooX::Options;
# Both loaded without importing, and every call below is qualified. A Moo::Role
# composes every sub in its package into its consumers, imported ones included,
# so `use Path::Tiny;` here made Path::Tiny's path() a method on ~20 command
# classes -- a silent collision waiting for the first command that wants an
# attribute called `path` (#38). App::karr::Role::Output states the same rule.
use Path::Tiny ();
use App::karr::Error ();
use App::karr::Role::ExitCodes;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Config;

# Every command that composes this role (directly or via BoardAccess) inherits
# the exit-code contract's option-parse half: an unknown option / bad option
# value exits 2, not 1. See App::karr::Role::ExitCodes and ADR 0002. The four
# board-less commands (agent-name, get-refs, set-refs, skill) compose ExitCodes
# on their own.
with 'App::karr::Role::ExitCodes';


# The board-discovery seed. Available on every command that composes this role
# (directly or via BoardAccess), so both `karr CMD --dir PATH` and, via the
# MooX::Cmd command_chain, the root form `karr --dir PATH CMD` resolve the same
# board. format=s also registers dir in _options_data, so positional_args never
# mistakes `--dir PATH` (or its value) for a positional argument.
option dir => (
  is        => 'ro',
  format    => 's',
  doc       => 'Path used as the starting point for Git repository discovery',
  predicate => 1,
);

has git_root => (
    is  => 'lazy',
    isa => sub {
        die "git_root must be a Path::Tiny object" unless eval { $_[0]->isa('Path::Tiny') };
    },
);

has store => (
    is => 'lazy',
);

has git => (
    is => 'lazy',
);

has config => (
    is => 'lazy',
);

# Actor role for the activity log identity: 'user' (default) or 'agent'.
# Carried to nested karr calls via the KARR_ROLE env var (foundation sets
# 'agent'); a --role option on a command overrides this attribute.
has role => (
    is      => 'lazy',
    builder => sub { $ENV{KARR_ROLE} || 'user' },
);

# The effective --dir for this command. A command's own --dir (the
# `karr CMD --dir PATH` form) always wins. Otherwise, when MooX::Cmd dispatched
# us as a subcommand, the root form `karr --dir PATH CMD` leaves --dir on an
# ancestor in the command_chain rather than on this Cmd instance, so adopt it
# from there. Consulted from the lazy _build_git_root builder, so the value is
# picked up before git_root/store are ever built -- including from
# SyncLifecycle's sync_before, which triggers store.
sub _effective_dir {
    my ($self) = @_;
    return $self->dir if $self->has_dir;

    if ( $self->can('command_chain') && ( my $chain = $self->command_chain ) ) {
        for my $cmd (@$chain) {
            next if $cmd == $self;
            return $cmd->dir if $cmd->can('has_dir') && $cmd->has_dir;
        }
    }
    return undef;
}

sub _build_git_root {
    my ($self) = @_;

    my $dir = $self->_effective_dir;
    my $start = defined $dir
        ? Path::Tiny::path($dir)->absolute
        : Path::Tiny::path('.')->absolute;

    while (1) {
        my $git = App::karr::Git->new( dir => $start->stringify );
        my $root = $git->repo_root;
        return $root if $root;
        last if $start->is_rootdir;
        $start = $start->parent;
    }
    # Not croak: this is the first thing anyone who runs karr outside a
    # repository sees, and Carp would append this builder's own file and line
    # to it (#77). Where karr keeps its source is not the reader's problem.
    App::karr::Error::user_error("Not a git repository. karr requires Git.");
}

sub _build_store {
    my ($self) = @_;
    my $git = App::karr::Git->new( dir => $self->git_root->stringify );
    return App::karr::BoardStore->new( git => $git );
}

sub _build_git {
    my ($self) = @_;
    return $self->store->git;
}

sub _build_config {
    my ($self) = @_;
    my $merged = $self->store->effective_config;
    return App::karr::Config->from_merged($merged);
}


sub require_board {
    my ($self) = @_;
    my $store = $self->store;
    return 1 if $store->board_exists;

    # Nothing under refs/karr/ at all: the sentence every board-less repository
    # has always got, and the same one Backup/Destroy/Materialize/Repair raise
    # off has_board_refs, where it means exactly this. No mention of 'karr sync'
    # here, unlike the read-side message in require_local_board: this method is
    # called after sync_before, so the pull has already run and found nothing.
    die "No karr board found. Run 'karr init' to create one.\n"
        unless $store->has_board_refs;

    # Refs are there, only refs/karr/config is missing. Saying "no board found"
    # here was a lie with consequences: an agent got it on a repository holding
    # 21 tickets, believed the repository had never had a board, and never
    # looked for them (#133). Name the state, count what is at stake, and say
    # that completing it keeps the tasks -- not 'karr repair', which only
    # migrates double-encoded UTF-8 and would die with this very sentence on a
    # repository that has no refs.
    my $tasks = $self->_task_refs_held;
    my $held =
          $tasks == 0 ? "board metadata is"
        : $tasks == 1 ? "1 task ref is"
        :               "$tasks task refs are";
    die "Half-initialized karr board: refs/karr/config is missing, but $held\n"
        . "already under refs/karr/, so this repository is not empty.\n"
        . "Run 'karr init' to complete the board -- it writes the missing config\n"
        . "and keeps what is already there.\n";
}


sub require_local_board {
    my ( $self, %args ) = @_;
    my $store = $self->store;
    return 1 if $store->board_exists;

    if ( $store->has_board_refs ) {
        my $tasks = $self->_task_refs_held;
        my $held =
              $tasks == 0 ? "no task refs are"
            : $tasks == 1 ? "1 task ref is"
            :               "$tasks task refs are";
        # Never suppressed by --json or --quiet: there is no field in any of
        # these payloads that could carry it, so STDERR is the only channel.
        print STDERR
            "Note: refs/karr/config is missing, so this board is half-initialized:\n"
          . "$held under refs/karr/, and the name, statuses and defaults shown are\n"
          . "karr's own, not the board's. Run 'karr init' to complete it -- it keeps\n"
          . "what is already there.\n";
        return 1;
    }

    my $advice = $store->git->has_remote
        ? "'git clone' does not fetch refs/karr/*, so a fresh clone starts out like\n"
        . "this. Run 'karr sync' to fetch the board, or 'karr init' to start one here.\n"
        : "Run 'karr init' to create one.\n";
    die "No karr board in this repository: nothing is stored under refs/karr/.\n"
      . "This is not an empty board -- nothing was read here at all.\n"
      . $advice
      . ( defined $args{hint} ? $args{hint} : '' );
}

# How many task refs the repository holds. Through a list, because
# list_task_refs returns through sort and would answer the number of arguments
# sort was handed if it were called in scalar context.
sub _task_refs_held {
    my ($self) = @_;
    my @ids = $self->store->git->list_task_refs;
    return scalar @ids;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::BoardDiscovery - Role providing minimal board discovery and config access

=head1 VERSION

version 0.500

=head1 DESCRIPTION

This role provides the minimal interface for discovering the board's Git
repository and BoardStore. It provides:

=over 4

=item * C<dir> — CLI option overriding the directory discovery starts from

=item * C<git_root> — path to the Git repository (walks up from C<dir> or CWD)

=item * C<store> — L<App::karr::BoardStore> instance backed by the Git repo

=item * C<git> — shortcut to C<< $self->store->git >> (lazy)

=item * C<config> — shortcut to C<< $self->store->effective_config >> (lazy)

=back

Commands that need the sync lifecycle should also compose
L<App::karr::Role::SyncLifecycle>.

=head2 require_board

    $self->sync_before;
    $self->require_board;

Refuses to go on when this repository has no initialized board. Every command
that writes to C<refs/karr/*> calls it, because without the check a C<karr
create> typed in the wrong directory silently seeded a partial board in an
unrelated repository -- and that partial board then locked C<karr init> out of
it permanently (#62).

It distinguishes the two ways of not having a board, because they call for
different things from the reader (#133):

=over 4

=item * nothing under C<refs/karr/> — "No karr board found. Run 'karr init' to
create one.", the sentence C<backup>, C<destroy>, C<materialize> and C<repair>
raise off L<App::karr::BoardStore/has_board_refs> for the same state;

=item * refs present, C<refs/karr/config> missing — a half-board: the message
names it as one, says how many task refs are at stake, and says that C<karr
init> completes it without discarding them.

=back

Call it B<after> C<sync_before>, never before: on a fresh clone the board only
exists on the remote until the pull has run, and checking first would report a
board that is merely not fetched yet as missing. The four commands that read or
clean up raw refs (C<backup>, C<destroy>, C<materialize>, C<repair>) ask
L<App::karr::BoardStore/has_board_refs> instead, so they can still deal with a
half-board left behind by an older karr.

The read-only commands do not sync, so they cannot use this method; they ask
L</require_local_board>, which puts C<karr sync> in front of C<karr init> for
exactly the fresh clone this one may assume has already been pulled.

=head2 require_local_board

    $self->require_local_board;   # no sync_before: reads stay offline
    $self->require_local_board( hint => "...one more sentence.\n" );

The read side of L</require_board>, for the commands that render the board
without pulling first (C<board>, C<list>, C<show>, C<log>, C<context>, and
C<config show>/C<config get>). It answers one question those commands never
asked: was anything actually read here? Without it they rendered the code
defaults over an empty task list, so a repository holding no board printed
exactly what a board holding no tasks prints -- and since C<git clone> does not
fetch C<refs/karr/*>, that is the normal state of every fresh clone, where the
user's tickets are all on the remote (#135, and #136 for the config half).

The two states L</require_board> distinguishes need different answers on the
read path:

=over 4

=item * nothing under C<refs/karr/> — refuse. Naming C<refs/karr/> says what
was looked at, and where the repository has a remote the message leads with
C<karr sync>, not C<karr init>: on a fresh clone the board exists and is
merely unfetched, and C<init> is the one command that would answer that by
starting a second, empty one.

=item * refs present, C<refs/karr/config> missing — a half-board: go on, and
say so on STDERR. Refusing would hide tasks that are demonstrably there, which
is the mistake #133 was about; but the board name, statuses and defaults being
rendered are karr's own, not the board's, and nothing else on the page says so.
STDERR keeps C<--json> parsable.

=back

Reads deliberately do not sync (a network round trip in front of every C<karr
show> is not worth it, and a stale read is recoverable where a stale write is
not), so unlike L</require_board> this may be called first thing in C<execute>
-- after option validation, so that a usage error still exits 2.

The optional C<hint> argument appends one caller-supplied sentence to the
refusal, for a command that can offer something beyond C<karr sync> /
C<karr init>. L<App::karr::Cmd::Config> is the one caller: what it used to
print here -- karr's built-in defaults -- is a real answer to a different
question, so its refusal points at C<karr config show --defaults>, where the
same values are true by construction (#136). The half-board note takes no
hint: it already says the values shown are karr's own.

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
