# ABSTRACT: Install, check, and update bundled agent skills

package App::karr::Cmd::Skill;
our $VERSION = '0.602';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr skill [install|check|update|show [NAME]] [--agent NAME] [--global] [--force]',
);
use App::karr::Role::Output;
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;
use App::karr::Role::SkillFile;
use App::karr::Error qw( user_error clean_error );
use Path::Tiny;

# ExitCodes: unknown option / bad option value exits 2, not 1 (ADR 0002). Skill
# is board-less, so it does not inherit ExitCodes via BoardDiscovery -- and for
# the same reason it declares no --dir and refuses the root form of it in
# _reject_root_dir below (#226).
# SkillFile: which skills ship (_skill_names, _retired_skill_names),
# _skill_files, _skill_content, the two writers and the removal of a retired
# skill directory, shared with `karr init --claude-skill`, which writes the
# same directories this command writes for the claude-code agent (tickets
# #145, #146, #285).
with 'App::karr::Role::Output', 'App::karr::Role::CliArgs',
     'App::karr::Role::ExitCodes', 'App::karr::Role::SkillFile';


option agent => (
  is => 'ro',
  format => 's',
  doc => 'Target agent (claude-code, codex, cursor)',
);

option global => (
  is => 'ro',
  doc => 'Install/check globally (~/) instead of project-level',
);

option force => (
  is => 'ro',
  doc => 'Force reinstall even if current',
);

my %AGENTS = (
  'claude-code' => { project => '.claude/skills', global => '.claude/skills' },
  'codex'       => { project => '.agents/skills', global => '.codex/skills' },
  'cursor'      => { project => '.cursor/skills', global => '.cursor/skills' },
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->_reject_root_dir($chain_ref);
  my @pos    = $self->positional_args($args_ref);
  my $action = $pos[0] // 'install';
  # Only the action is a positional -- and for show, the skill name after it.
  $self->check_positional_args( $args_ref, $action eq 'show' ? 2 : 1 );

  if ($action eq 'install') {
    $self->_install;
  } elsif ($action eq 'check') {
    $self->_check;
  } elsif ($action eq 'update') {
    $self->_update;
  } elsif ($action eq 'show') {
    $self->_show( $pos[1] );
  } else {
    # Leading "Usage:" is what bin/karr's handler keys on to exit 2 rather than
    # 1 (ADR 0002: an invalid value is a usage error). Becomes a one-line swap
    # to Role::ExitCodes' usage_error once that lands (ticket #76).
    user_error( "Usage: karr skill [install|check|update|show]\n",
                "Unknown action: $action (use install, check, update, or show)" );
  }
}

# One SKILL.md when a name is given, all of them in _skill_names order when
# not. All of them is the default because that is what "the bundled skill"
# meant before the split: `karr skill show` still shows everything an agent
# would be briefed with. A name picks one file out, which is what a shell
# redirect into a single SKILL.md needs. The JSON shape is the same array
# either way, so a consumer does not have to know which form was asked for.
sub _show {
  my ($self, $name) = @_;
  my @names = $self->_skill_names;

  if (defined $name) {
    # An invalid positional value is a usage error (ADR 0002), exit 2.
    user_error( "Usage: karr skill show [NAME]\n",
                "Unknown skill: $name (known: ", join( ', ', @names ), ")" )
      unless grep { $_ eq $name } @names;
    @names = ($name);
  }

  my @shown = map { { skill => $_, content => $self->_skill_content($_) } } @names;

  if ($self->json) {
    # Characters in, characters out, exactly like the plain branch below:
    # print_json goes through App::karr::Encoding::json_encode, which is the
    # character-level codec, and STDOUT's :encoding(UTF-8) layer does the one
    # and only encode. _skill_content is already decoded (slurp_utf8), so it
    # goes in untouched.
    return $self->print_json( \@shown );
  }

  # Ticket #33 encoded here, because back then the rest of the CLI handed raw
  # octets to print and a layer on STDOUT would have double-encoded them.
  # Ticket #53 removed that premise: STDOUT now carries :encoding(UTF-8) and
  # every command prints characters, so _skill_content goes out as-is.
  # Encoding it again here would be the very double encode #33 was avoiding.
  print join "\n", map { $_->{content} } @shown;
  return;
}

sub _install {
  my ($self) = @_;
  my @agents  = $self->_target_agents;
  my %shipped = map { ( $_ => { $self->_skill_files($_) } ) } $self->_skill_names;
  my @results;

  for my $agent (@agents) {
    my $base = $self->_skills_base($agent);

    for my $skill ($self->_skill_names) {
      my $dir  = $base->child($skill);
      my $file = $dir->child('SKILL.md');

      # "Installed" is keyed on SKILL.md alone: it is the file an agent loads,
      # so a target that has it is a target someone installed into. A missing
      # reference beside it is what `update` is for, not a reason to overwrite.
      if ($file->exists && !$self->force) {
        $self->_report( \@results, $agent, $skill, 'exists', "$file",
                        'already installed (use --force to reinstall)' );
        next;
      }

      $self->_write_skill_files( $dir, $shipped{$skill} );
      $self->_report( \@results, $agent, $skill, 'installed', "$file", "installed to $file" );
    }

    # After the new skills are in place, not before: a failed write leaves the
    # old skill where it was rather than an agent with no skill at all.
    $self->_report_removed( \@results, $agent, $self->_remove_retired_skills($base) );
  }

  $self->print_json(\@results) if $self->json;
}

sub _check {
  my ($self) = @_;
  my @agents  = $self->_target_agents;
  my %shipped = map { ( $_ => { $self->_skill_files($_) } ) } $self->_skill_names;
  my @results;
  my $failing = 0;

  for my $agent (@agents) {
    my $base      = $self->_skills_base($agent);
    my $installed = $self->_agent_installed($base);

    for my $skill ($self->_skill_names) {
      my $dir  = $base->child($skill);
      my $file = $dir->child('SKILL.md');

      if (!$file->exists && !$installed) {
        $self->_report( \@results, $agent, $skill, 'not installed', undef, 'not installed' );
      } elsif ( $file->exists && !%{ $self->_stale_files( $dir, $shipped{$skill} ) } ) {
        $self->_report( \@results, $agent, $skill, 'current', undef, 'current' );
      } else {
        # Differs, or missing while the rest of the set is there: either way
        # `update` has something to write.
        $self->_report( \@results, $agent, $skill, 'outdated', undef, 'outdated' );
        $failing++;
      }
    }

    for my $dir ( $self->_retired_skill_dirs($base) ) {
      $self->_report( \@results, $agent, $dir->basename, 'stale', "$dir",
                      "stale: retired skill, 'karr skill update' removes $dir" );
      $failing++;
    }
  }

  $self->print_json(\@results) if $self->json;

  # A check that found work for `update` is a runtime failure, exit 1 (ADR
  # 0002) -- outdated and stale alike. Nothing installed is not.
  exit(1) if $failing;
}

sub _update {
  my ($self) = @_;
  my @agents  = $self->_target_agents;
  my %shipped = map { ( $_ => { $self->_skill_files($_) } ) } $self->_skill_names;
  my @results;

  for my $agent (@agents) {
    my $base = $self->_skills_base($agent);

    unless ( $self->_agent_installed($base) ) {
      $self->_report( \@results, $agent, $_, 'not installed', undef,
                      "not installed (run 'karr skill install' first)" )
        for $self->_skill_names;
      next;
    }

    for my $skill ($self->_skill_names) {
      my $dir  = $base->child($skill);
      my $file = $dir->child('SKILL.md');

      # Only what is missing or differs gets written: a file that already
      # matches is not rewritten (nothing to gain, and one fewer chance for the
      # read-only fallback in _write_skill to have to say anything), and a file
      # in the target that is not shipped is nobody's to remove from here. A
      # skill missing entirely is all stale, so it is written whole -- which is
      # how an install of the retired single skill becomes the pair.
      my $stale = $self->_stale_files( $dir, $shipped{$skill} );
      if (%$stale) {
        $self->_write_skill_files( $dir, $stale );
        $self->_report( \@results, $agent, $skill, 'updated', "$file", 'updated' );
      } else {
        $self->_report( \@results, $agent, $skill, 'current', undef, 'already current' );
      }
    }

    $self->_report_removed( \@results, $agent, $self->_remove_retired_skills($base) );
  }

  $self->print_json(\@results) if $self->json;
}

# Whether an agent's target counts as having the karr skills at all: either
# skill of the set, or the retired single skill it replaces. Decides whether
# update touches the agent and whether check calls a missing member outdated
# rather than not installed.
sub _agent_installed {
  my ($self, $base) = @_;
  return 1 if grep { $base->child( $_, 'SKILL.md' )->exists } $self->_skill_names;
  return $self->_retired_skill_dirs($base) ? 1 : 0;
}

# One result: a JSON entry, or a plain line naming agent and skill. $path is
# left out of the entry when there is none, as the statuses without one always
# were.
sub _report {
  my ($self, $results, $agent, $skill, $status, $path, $text) = @_;
  push @$results, { agent => $agent, skill => $skill, status => $status,
                    defined $path ? ( path => $path ) : () };
  printf "%-12s %-32s %s\n", $agent, $skill, $text unless $self->json;
  return;
}

sub _report_removed {
  my ($self, $results, $agent, @removed) = @_;
  $self->_report( $results, $agent, $_->basename, 'removed', "$_",
                  "removed $_ (retired, replaced by "
                    . join( ' and ', $self->_skill_names ) . ')' )
    for @removed;
  return;
}

# The shipped files whose copy under $dir is missing or differs, as the same
# (relative path => content) pairs _skill_files hands out -- i.e. exactly what
# _write_skill_files has to write to bring the target current. Empty means
# current. Compared as characters on both sides (slurp_utf8 against
# slurp_utf8), so a byte-level difference in encoding shows up as a
# difference rather than being hidden by a decode on one side only.
sub _stale_files {
  my ($self, $dir, $shipped) = @_;
  my %stale;
  for my $rel (sort keys %$shipped) {
    my $file = $dir->child($rel);
    next if $file->exists && $self->_read_skill($file) eq $shipped->{$rel};
    $stale{$rel} = $shipped->{$rel};
  }
  return \%stale;
}

# Path::Tiny raises Path::Tiny::Error objects that stringify with the call site
# appended ("mkpath failed for ...: Permission denied at .../Cmd/Skill.pm line
# NNN."), so an unwritable skill directory used to report a karr source
# location at the user. App::karr::Error reduces it to the one line that is
# actually about them (ticket #77).
sub _read_skill {
  my ($self, $file) = @_;
  my $content = eval { $file->slurp_utf8 };
  defined $content
    or user_error( "Could not read $file: ", clean_error($@) );
  return $content;
}

# _write_skill and _write_skill_files -- the in-place write, and why it has to
# be one -- live in App::karr::Role::SkillFile, composed above: `karr init
# --claude-skill` writes the very same directories under .claude/skills/, and
# kept its own spew_utf8 copy of this rule until ticket #145 because the rule
# lived here (#142). _skill_content, which finds the bundled skill in the
# first place, followed it there in #146 -- it was duplicated in Cmd::Init down
# to the last line but one -- and _skill_files, the whole directory rather than
# its SKILL.md, joined it in #285. The list of skills and the removal of the
# retired one live there for the same reason.

# `karr skill install --dir PATH` was always rejected by MooX::Options -- this
# command declares no such option -- but `karr --dir PATH skill install` was
# not: --dir is declared on App::karr::Role::BoardDiscovery, the root command
# composes it via App::karr::Role::BoardAccess, and MooX::Cmd leaves the parsed
# value on the root instance in the command chain, where nothing here ever
# looked. So the option went in without a word and the install ran on the
# current directory instead -- putting a file into a tree the caller had not
# named, under a message that read like the named one (#226). `dashboard` had
# the same leak (#225) and only ever read; this one writes.
#
# Refused rather than adopted as a synonym, because --dir is not what this
# command's target is. --dir seeds a walk UPWARD to one repository's root
# (App::karr::Role::BoardDiscovery/_build_git_root, which is why it may name
# any directory inside that repository), while the project-local target here is
# the current directory itself, repository or not: `karr skill` is board-less
# and installing into a plain directory is a supported use, pinned by t/226.
# Honouring --dir would have meant either refusing those installs or giving one
# option two meanings that answer about different directories. `cd` is how you
# install into another tree, and `karr init --claude-skill` is the command that
# writes these same directories through git_root.
#
# The root is read from $chain_ref the way App::karr::Cmd::Dashboard reads it
# for its own refusal and App::karr::Cmd::GetRefs reads it to honour the
# option; a directly constructed instance (no MooX::Cmd dispatch, hence an
# empty chain) has no root option to reject.
sub _reject_root_dir {
  my ($self, $chain_ref) = @_;
  return unless $chain_ref && @$chain_ref;
  my $root = $chain_ref->[0];
  return unless $root && $root->can('has_dir') && $root->has_dir;
  # Wrapped to stay inside 80 columns with usage_error's own "Usage error: "
  # prefix on the first line: what to type comes first, the reason after it.
  $self->usage_error(
      "skill does not take --dir; its target is the current directory:\n"
    . "cd PATH && karr skill install\n"
    . "(--dir seeds a search upward for one repository's root, while skill is\n"
    . "board-less and works where it is run -- or under \$HOME with --global.)"
  );
}

sub _target_agents {
  my ($self) = @_;
  if ($self->agent) {
    my @names = split /,/, $self->agent;
    for my $name (@names) {
      # --agent is a value MooX::Options cannot validate, so the usage error is
      # raised here; see the note on the unknown-action branch in execute.
      user_error( "Usage: karr skill --agent NAME[,NAME,...]\n",
                  "Unknown agent: $name (known: ", join( ', ', sort keys %AGENTS ), ")" )
        unless $AGENTS{$name};
    }
    return @names;
  }
  # Auto-detect: return agents whose skills directories exist, or all if none
  # found
  my @detected;
  for my $name (sort keys %AGENTS) {
    push @detected, $name if $self->_skills_base($name)->exists;
  }
  return @detected ? @detected : sort keys %AGENTS;
}

# The directory an agent keeps its skills in -- .claude/skills and the like --
# under which every skill of the set, and any retired one, is a directory of
# its own name.
sub _skills_base {
  my ($self, $agent) = @_;
  my $spec = $AGENTS{$agent} or die "Unknown agent: $agent\n";
  # Absolute, because the paths under it are printed back at the caller and
  # handed to --json consumers: `installed to .claude/skills/...` named no tree
  # in particular and was as true of the directory the file went into as of the
  # one the caller meant (#226, point 3). ->absolute prepends the current
  # directory without resolving symlinks, so what comes back is the path the
  # caller would have typed rather than a realpath they may not recognize. The
  # global branch is absolute already: $HOME is.
  return $self->global
    ? path($ENV{HOME})->child($spec->{global})
    : path('.')->absolute->child($spec->{project});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Skill - Install, check, and update bundled agent skills

=head1 VERSION

version 0.602

=head1 SYNOPSIS

    karr skill install
    karr skill install --agent codex,cursor
    karr skill check --global
    karr skill update --force
    karr skill show
    karr skill show kanban-issues-karr-ticket

=head1 DESCRIPTION

Installs and maintains the bundled C<karr> skills for supported agent
clients. Two skills ship:

=over 4

=item * C<kanban-issues-karr-coordination>

Reading a board, picking, claiming and creating cards, handing them to
subagents, filing on another repository's board, configuring and syncing
karr.

=item * C<kanban-issues-karr-ticket>

Working the one card an agent was handed: reading it, noting progress,
blocking it, handing it to review.

=back

Each skill is a directory -- F<SKILL.md>, which an agent loads on every
trigger, plus F<references/*.md> where it has them, which it reads on demand
-- and every action below handles the two skills as one set. The command can
target project-local directories or global skill locations in the current
user's home directory, which makes it useful both for direct Perl installs
and Docker-wrapped vendor usage.

Earlier releases shipped a single skill, C<kanban-issues-karr-cli>, that the
two above replace. A directory of that name next to them is a leftover:
C<install> and C<update> remove it and report it C<removed>, C<check> reports
it C<stale> (see L</ACTIONS>).

Writes go into each target file B<in place>, keeping its inode, so a
F<SKILL.md> that is one link of a hardlink chain shared across projects stays
part of that chain instead of being silently broken out of it.

C<--global> selects the home-directory location instead of the project-local
one; the two coincide for C<claude-code> and C<cursor> but differ for
C<codex> (see L</SUPPORTED AGENTS>).

=head1 TARGET DIRECTORY

The project-local target is the B<current working directory>: the skill
directories are written straight underneath it, at
F<.claude/skills/kanban-issues-karr-coordination/> and
F<.claude/skills/kanban-issues-karr-ticket/> for C<claude-code> and at the
equivalent paths for the other agents. Nothing is discovered on the way
there and no repository is involved -- this command has no board, and
installing into a directory that is not a Git repository at all is a
supported use. C<--global> is the same idea one level up: the target is the
current user's home directory instead. When C<--agent> is omitted, even the
auto-detection reads the current directory, so both which agents are touched
and where their files land follow from where the command was run.

The root option C<--dir> is therefore B<refused>, in both placements, and
both exit C<2>: C<karr skill install --dir PATH> is an unknown option (this
command declares none), and C<karr --dir PATH skill install> is a usage error
that names the current directory as the target. C<--dir> is the starting
point of a search B<upward> for one repository's root -- which is why it may
name any directory inside that repository -- and that is not what this
command's target is; handed the same path, the two would answer about
different directories. To install into another tree, C<cd> there. Before
ticket #226 the root placement was accepted and then discarded without a
word, so the file was written into the tree the caller happened to be
standing in while the message read as if the named one had been used.

C<karr init --claude-skill> writes the very same directories and does honour
C<--dir>: it installs into the root of the repository it is initializing, and
it needs a repository in the first place.

=head1 SUPPORTED AGENTS

The built-in agent targets are C<claude-code>, C<codex>, and C<cursor>. When
C<--agent> is omitted, the command auto-detects available client directories and
falls back to all known agents if nothing is detected.

=head1 ACTIONS

Every action reports one line per agent and skill, and with C<--json> one
object per agent and skill, each carrying C<agent>, C<skill> and C<status>
(plus C<path> where a directory or file was written or removed), in one JSON
array. A retired skill directory is reported under its own name in the
C<skill> key.

=over 4

=item * C<install>

Writes the current bundled skills -- each one's F<SKILL.md> and every
F<references/*.md> -- to the selected target locations. A skill whose target
already has a F<SKILL.md> is left alone and reported C<exists> unless
C<--force> is given, which overwrites every file unconditionally. Every
written skill is reported C<installed> with the absolute path of its
F<SKILL.md>, in the plain output as well as under the C<path> key of
C<--json>, so the message says which tree the skill went into. A retired
C<kanban-issues-karr-cli> directory beside them is removed and reported
C<removed>, with the path of the directory.

=item * C<check>

Compares every installed file with the bundled version. Per skill: a target
with no F<SKILL.md> is C<not installed>, whatever else is under it; a shipped
file that is missing from the target, or differs from it, makes the skill
C<outdated>; otherwise it is C<current>. Once an agent has either skill (or
the retired one) installed, the other one missing counts as C<outdated> too:
the two are one set. A retired C<kanban-issues-karr-cli> directory is
reported C<stale>. The command exits C<1> when anything is C<outdated> or
C<stale> -- the check ran and found work for C<update> -- and C<0> otherwise;
C<not installed> alone is not a failure.

=item * C<update>

Brings the installed set current, in place: every shipped file that is
missing or differs is rewritten, the ones that match are left untouched, and
so is anything in the target that is not shipped (a reference file a later
release dropped, say). An agent counts as installed when it has either skill
or the retired one; for such an agent, a skill that is missing is written
whole. C<current> means every file already matched, C<updated> that
something was written. A retired C<kanban-issues-karr-cli> directory is
removed and reported C<removed> -- so C<update> alone migrates a target from
the single skill of earlier releases to the pair. An agent with none of them
is C<not installed> and left alone.

=item * C<show [NAME]>

Prints a bundled F<SKILL.md> to standard output: the one of skill NAME when
given (C<kanban-issues-karr-coordination> or C<kanban-issues-karr-ticket>),
otherwise every bundled skill's in the order above, separated by one blank
line. Each file is printed as it ships, frontmatter included, so the C<name:>
line at the top of each says which skill follows. With C<--json> the output
is a JSON array of objects with C<skill> and C<content> -- one per skill
printed, so a single NAME gives an array of one. An unknown NAME is a usage
error (exit C<2>).

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Init>,
L<App::karr::Role::SkillFile>, L<App::karr::Cmd::Context>,
L<App::karr::Cmd::Config>

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
