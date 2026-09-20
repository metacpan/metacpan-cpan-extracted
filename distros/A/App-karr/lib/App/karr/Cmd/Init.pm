# ABSTRACT: Initialize a new karr board

package App::karr::Cmd::Init;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr init [--name TEXT] [--statuses LIST] [--claude-skill] '
    . '[--new-board]',
);
use App::karr::Error qw( user_error clean_error );
use App::karr::Config;
use App::karr::Role::BoardDiscovery;
use App::karr::Role::CliArgs;
use App::karr::Role::Output;
use App::karr::Role::SkillFile;

# SkillFile: _skill_files and _write_skill_files, shared with `karr skill`,
# which installs the same directory --claude-skill installs (tickets #145,
# #146, #285).
with 'App::karr::Role::BoardDiscovery', 'App::karr::Role::SkillFile';
with 'App::karr::Role::CliArgs';
with 'App::karr::Role::Output';


option name => (
  is => 'ro',
  format => 's',
  doc => 'Board name',
);

option statuses => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated status list',
);

option new_board => (
  is => 'ro',
  doc => 'Start a board here even though the remote already has one',
);

option claude_skill => (
  is => 'ro',
  doc => 'Install Claude Code skill for karr',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  # git_root honours --dir (both call forms) and dies loudly if the target is
  # not a Git repository, instead of hardcoding the current directory.
  my $root  = $self->git_root;
  my $store = $self->store;
  die "Board already exists in refs/karr/\n" if $store->board_exists;

  # Before the first ref write, and before $born_here below: whether this
  # repository already has a board is a question the remote answers too, not
  # the local refs alone (#182).
  $self->_refuse_if_remote_has_board unless $self->new_board;

  # Asked before the first ref write below, which would make any repository
  # look like it already held something. This is what tells a board born here
  # apart from a half-board this run is completing (#62), and the encoding
  # marker further down hangs on the difference (#132).
  my $born_here = !$store->has_board_refs;

  my $overrides = { version => 1 };
  $overrides->{board} = { name => $self->name } if defined $self->name;

  if ($self->statuses) {
    my @statuses = split /,/, $self->statuses;
    $overrides->{statuses} = \@statuses;
  }

  my $effective = App::karr::Config->effective_config($overrides);
  $store->save_config($effective);
  # Not set_next_id(1): init now also completes a board that a stray write
  # command left half-built (#62), and resetting the counter under tasks that
  # are already there would hand the next `karr create` an id it would then
  # overwrite.
  $store->ensure_next_id;
  # A board born here is written under the current encoding contract, so mark
  # it and spare it the legacy-mojibake repair (ticket #53) -- but only one
  # actually born here. The task refs of a half-board this run is completing
  # were written by some earlier karr, quite possibly 0.402 or older, and
  # stamping asserts the opposite of what they carry: the read-path repair
  # stops running, every old card turns to mojibake, and `karr repair` then
  # reports the board as up to date and declines to fix it (#132). Say nothing
  # instead, which leaves both the repair on read and `karr repair --yes`
  # available.
  $store->stamp_encoding_version if $born_here;
  # And stamp its identity, the thing a pull compares against the remote's to
  # recognise a swapped board (#95). ensure_, not set_: init also completes
  # half-boards (#62), and re-keying one that already carries an id would
  # make every other clone read this board as a foreign one.
  $store->ensure_board_id;

  print "Initialized karr board in refs/karr/\n" unless $self->json;

  # Completing a half-board is a different event from creating one, and the
  # user has to be told which one just happened: the tasks that were already
  # there are still there, and the board is still on the old encoding contract
  # because this run had no business claiming otherwise (#132).
  if ( !$born_here ) {
    my @ids   = $store->git->list_task_refs;   # returns through sort: no scalar context
    my $tasks = scalar @ids;
    unless ($self->json) {
      print $tasks == 1
        ? "Completed a half-board: the 1 task ref already here was kept.\n"
        : "Completed a half-board: the $tasks task refs already here were kept.\n";
      print "Left refs/karr/meta/encoding unstamped, so those refs keep being read the way\n"
        . "they were written; 'karr repair' says whether they need migrating.\n"
        if $store->git->board_is_legacy_encoded;
    }
  }

  # The materialized file view (config.yml + tasks/) is a disposable view of the
  # canonical refs and must never be committed. Ensure the board-root .gitignore
  # covers it, appending idempotently -- kanban-md does the same at init time.
  #
  # Unless the project got there first: `tasks/` and `config.yml` at a
  # repository root are perfectly ordinary names for a project to already use,
  # and git applies no ignore rule to a file it already tracks. The entry would
  # therefore change nothing at all while telling every later reader that karr
  # owns a path the project owns -- and it would say so right where `karr
  # materialize` refuses to write, for that very reason (tickets #48, #89). Say
  # nothing rather than something untrue.
  my @owned = $store->project_owned_view_paths($root);
  my @ignored;
  if (@owned) {
    print "Left .gitignore alone: git already tracks content at "
      . join( ', ', @owned ) . ".\n"
      . "Those paths belong to the project, not to karr's file view, so karr is "
      . "not\nclaiming them here.\n"
      unless $self->json;
  }
  else {
    @ignored = $store->ensure_gitignore( $root->stringify );
    print "Added .gitignore entries for the file view: " . join( ', ', @ignored ) . "\n"
      if @ignored && !$self->json;
  }

  if ($self->claude_skill) {
    $self->_install_claude_skill($root);
  }

  # --json reports the board name and the .gitignore entries this run added,
  # and nothing else on stdout (ticket #268). The remote-probe warning above
  # goes to STDERR, so the JSON stream stays clean.
  if ($self->json) {
    $self->print_json(
      { board => { name => $effective->{board}{name} }, gitignore => \@ignored } );
  }
}

# `git clone` does not carry refs/karr/*, so a fresh clone of a repository
# whose board lives on origin holds nothing under refs/karr/ -- exactly what a
# repository that never had a board looks like. init used to answer that by
# writing a second board with its own refs/karr/meta/board-id, and the next
# sync then hit the board-identity guard (#95) with "the remote is a different
# board": true, unhelpful, and too late, since the user is by then holding two
# boards and has to work out which one is theirs (#182).
#
# So ask the remote first, through the same bounded ls-remote probe the read
# path takes before it refuses (App::karr::Git/remote_has_board, reached from
# App::karr::Role::BoardDiscovery/_autofetch_board). Ask, and only ask: the
# read path fetches at this point because a read has nothing to lose and no
# other way to answer the question it was given, while init writes, and a
# writing command that pulls a whole board in unasked is a bigger surprise
# than the one it prevents. Refusing and naming `karr sync` leaves that fetch
# where the user can see it.
#
# Only a remote that actually advertises refs/karr/* refuses. Every other
# answer -- no remote configured, an unreachable one, no git CLI, no answer
# inside the probe's budget -- lets init through, because init has to work
# offline and a question that could not be put is not evidence of a board.
# KARR_NO_AUTO_FETCH is deliberately not consulted: it switches off an
# implicit fetch on the read path, this fetches nothing, and someone who set
# it so that reads stay local has not thereby asked for a second board.
# --new-board is the opt-out here, and it skips the round trip as well.
#
# Board refs already here do not change the answer, half-board (#62) included.
# A half-board plus a board on the remote is not a half-board to complete:
# completing it stamps refs/karr/meta/board-id, this repository's board -- the
# one on origin -- already carries one, and the next sync is back in #95.
# `karr sync` brings in the config those stray refs are missing and merges the
# id counter forward (#172), which completes the same board without minting a
# rival identity for it.
sub _refuse_if_remote_has_board {
  my ($self) = @_;

  my $git        = $self->store->git;
  my $advertised = $git->remote_has_board;

  if ( !defined $advertised ) {
    # The probe could not ask, and init is about to create a board that may
    # turn out to be the second one. The user waited for this round trip, so
    # say in one line what it could not establish -- on STDERR, in front of
    # init's own output on STDOUT.
    my $why = $git->last_error // 'unknown error';
    $why =~ s/\s*\n.*//s;
    print STDERR "karr: could not ask the remote whether it already has a board: $why\n";
    return;
  }
  return unless $advertised;

  user_error(
      "This repository already has a board on origin: 'git clone' does not fetch\n"
    . "refs/karr/*, so a fresh clone looks like it has none until the board is\n"
    . "brought in. Run 'karr sync' to fetch it.\n"
    . "Initializing here would start a second board beside it, and the next sync\n"
    . "would refuse the two as different boards. Run 'karr init --new-board' if an\n"
    . "independent board in this clone is really what you want."
  );
}

sub _install_claude_skill {
  my ($self, $root) = @_;
  my $skill_dir = $root->child('.claude/skills/kanban-issues-karr-cli');
  # An unwritable .claude is the project's layout, not a karr bug: Path::Tiny
  # would otherwise report this file and line at the user (#77). Kept here
  # rather than left to the mkpath inside _write_skill_files, which would report
  # the same failure as "Could not write .../SKILL.md": at that point nothing has
  # been written and nothing could be, because the directory is what karr could
  # not create. Saying so is this command's own contract (t/120).
  eval { $skill_dir->mkpath; 1 }
    or user_error( "Could not create $skill_dir: ", clean_error($@) );

  # Also App::karr::Role::SkillFile's, since ticket #146: finding the bundled
  # skill was a second copy of `karr skill`'s _skill_content, identical to it
  # except for the one $INC key that told the development fallback which
  # command's source tree to look next to. Since #285 the skill is a directory
  # (SKILL.md plus references/*.md) and _skill_files is the whole of it.
  my %skill_files = $self->_skill_files;
  # Through App::karr::Role::SkillFile, not spew_utf8: this is the same
  # directory `karr skill install --agent claude-code` writes, and in a
  # checkout wired up by manage-skills its SKILL.md is one link of a hardlink
  # chain. spew_utf8 renames a temp file over the target, which breaks this
  # project out of that chain and leaves every other one on the old inode with
  # the old text -- the bug fixed in `karr skill` as ticket #142 and left
  # standing here until #145. The role is also where the read-only fallback
  # and its warning live, so there is one description of how a skill gets
  # written rather than two that drift.
  $self->_write_skill_files( $skill_dir, \%skill_files );
  my $skill_file = $skill_dir->child('SKILL.md');
  # The path it wrote, not the fixed relative string it used to print: this
  # installs into the root of the repository being initialized, which --dir can
  # put in a different tree than the one the caller stands in, and
  # ".claude/skills/..." is true of every tree at once. `karr skill install`
  # printed the same non-answer and was fixed with it (#226, point 3).
  print "Installed Claude Code skill to $skill_file\n" unless $self->json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Init - Initialize a new karr board

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr init --name "My Project"
    karr init --statuses backlog,todo,in-progress,review,done
    karr init --name "Client Work" --claude-skill
    karr init --new-board          # in a clone whose remote already has one

=head1 DESCRIPTION

Creates a new board inside C<refs/karr/*> in the current Git repository. The
command writes the initial config and metadata refs and can optionally install
the bundled Claude Code skill into the repository.

Before it writes anything it asks the remote whether this repository already
has a board there, because C<git clone> does not fetch C<refs/karr/*> and a
fresh clone is therefore indistinguishable from a repository that never had
one. A remote that advertises C<refs/karr/*> means the board exists and is one
C<karr sync> away, so C<init> refuses and says so rather than starting a second
board beside it (#182). Every other answer -- no remote, an unreachable one,
no answer inside the probe's budget -- lets C<init> through: it has to work
offline.

=head1 OPTIONS

=over 4

=item * C<--name>

Sets the board name stored in C<board.name>.

=item * C<--statuses>

Replaces the default status list with the comma-separated statuses you supply.

=item * C<--new-board>

Starts a board here even though the remote already has one, skipping the
question C<init> otherwise asks it. For the rare case where a clone
deliberately keeps its own, independent board -- and, because it takes no round
trip at all, for initializing without touching the network. The two boards do
not sync with each other: the board-identity guard refuses that, which is what
it is for (#95).

=item * C<--claude-skill>

Copies the bundled skill to F<.claude/skills/kanban-issues-karr-cli/> --
F<SKILL.md> plus F<references/*.md>, the same directory
L<App::karr::Cmd::Skill> installs for the C<claude-code> agent, and written
the same way: each file B<in place>, keeping the inode of a F<SKILL.md> that
is already there, so one that is a link of a hardlink chain shared across
projects stays part of that chain.

=item * C<--json>

Emit the initialized board as one JSON object -- C<board.name> and the
C<.gitignore> entries this run added for the file view -- and nothing else on
stdout, so a caller can script the next step off the board name.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Config>,
L<App::karr::Cmd::Create>, L<App::karr::Cmd::Skill>

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
