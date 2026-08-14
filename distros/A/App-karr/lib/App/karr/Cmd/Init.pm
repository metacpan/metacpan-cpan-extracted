# ABSTRACT: Initialize a new karr board

package App::karr::Cmd::Init;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr init [--name TEXT] [--statuses LIST] [--claude-skill]',
);
use App::karr::Error qw( user_error clean_error );
use App::karr::Config;
use App::karr::Role::BoardDiscovery;
use App::karr::Role::SkillFile;

# SkillFile: _skill_content and _write_skill, shared with `karr skill`, which
# installs the same file --claude-skill installs (tickets #145, #146).
with 'App::karr::Role::BoardDiscovery', 'App::karr::Role::SkillFile';


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

  print "Initialized karr board in refs/karr/\n";

  # Completing a half-board is a different event from creating one, and the
  # user has to be told which one just happened: the tasks that were already
  # there are still there, and the board is still on the old encoding contract
  # because this run had no business claiming otherwise (#132).
  if ( !$born_here ) {
    my @ids   = $store->git->list_task_refs;   # returns through sort: no scalar context
    my $tasks = scalar @ids;
    print $tasks == 1
      ? "Completed a half-board: the 1 task ref already here was kept.\n"
      : "Completed a half-board: the $tasks task refs already here were kept.\n";
    print "Left refs/karr/meta/encoding unstamped, so those refs keep being read the way\n"
      . "they were written; 'karr repair' says whether they need migrating.\n"
      if $store->git->board_is_legacy_encoded;
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
  if (@owned) {
    print "Left .gitignore alone: git already tracks content at "
      . join( ', ', @owned ) . ".\n"
      . "Those paths belong to the project, not to karr's file view, so karr is "
      . "not\nclaiming them here.\n";
  }
  else {
    my @ignored = $store->ensure_gitignore( $root->stringify );
    print "Added .gitignore entries for the file view: " . join( ', ', @ignored ) . "\n"
      if @ignored;
  }

  if ($self->claude_skill) {
    $self->_install_claude_skill($root);
  }
}

sub _install_claude_skill {
  my ($self, $root) = @_;
  my $skill_dir = $root->child('.claude/skills/karr');
  # An unwritable .claude is the project's layout, not a karr bug: Path::Tiny
  # would otherwise report this file and line at the user (#77). Kept here
  # rather than left to the mkpath inside _write_skill, which would report the
  # same failure as "Could not write .../SKILL.md": at that point nothing has
  # been written and nothing could be, because the directory is what karr could
  # not create. Saying so is this command's own contract (t/120).
  eval { $skill_dir->mkpath; 1 }
    or user_error( "Could not create $skill_dir: ", clean_error($@) );

  # Also App::karr::Role::SkillFile's, since ticket #146: finding the bundled
  # file was a second copy of `karr skill`'s _skill_content, identical to it
  # except for the one $INC key that told the development fallback which
  # command's source tree to look next to.
  my $skill_content = $self->_skill_content;
  # Through App::karr::Role::SkillFile, not spew_utf8: this is the same file
  # `karr skill install --agent claude-code` writes, and in a checkout wired up
  # by manage-skills it is one link of a hardlink chain. spew_utf8 renames a
  # temp file over the target, which breaks this project out of that chain and
  # leaves every other one on the old inode with the old text -- the bug fixed
  # in `karr skill` as ticket #142 and left standing here until #145. The role
  # is also where the read-only fallback and its warning live, so there is one
  # description of how a skill file gets written rather than two that drift.
  $self->_write_skill( $skill_dir->child('SKILL.md'), $skill_content );
  print "Installed Claude Code skill to .claude/skills/karr/SKILL.md\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Init - Initialize a new karr board

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr init --name "My Project"
    karr init --statuses backlog,todo,in-progress,review,done
    karr init --name "Client Work" --claude-skill

=head1 DESCRIPTION

Creates a new board inside C<refs/karr/*> in the current Git repository. The
command writes the initial config and metadata refs and can optionally install
the bundled Claude Code skill into the repository.

=head1 OPTIONS

=over 4

=item * C<--name>

Sets the board name stored in C<board.name>.

=item * C<--statuses>

Replaces the default status list with the comma-separated statuses you supply.

=item * C<--claude-skill>

Copies the bundled skill file to F<.claude/skills/karr/SKILL.md> -- the same
file L<App::karr::Cmd::Skill> installs for the C<claude-code> agent, and written
the same way: B<in place>, keeping the inode of a F<SKILL.md> that is already
there, so one that is a link of a hardlink chain shared across projects stays
part of that chain.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
