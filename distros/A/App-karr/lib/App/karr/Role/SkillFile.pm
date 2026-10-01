# ABSTRACT: The one way karr finds and writes the bundled skill directories

package App::karr::Role::SkillFile;
our $VERSION = '0.602';
use Moo::Role;
# All loaded without importing, for the reason spelled out in
# App::karr::Role::Output: a Moo::Role composes every sub in its package into
# its consumers, so `use App::karr::Error qw( user_error )` here would quietly
# make user_error and clean_error methods on `karr skill` and `karr init`, and
# `use Path::Tiny;` would do the same with path() (ticket #38, t/121).
use App::karr::Error ();
use Path::Tiny ();
use File::ShareDir ();

# Nothing is required of the consumer. _skill_content and _skill_files take
# only a skill name, _write_skill and _write_skill_files are handed both the target and
# the content, and none of them reaches for anything on $self -- which is the
# point of the role: `karr skill` is board-less while `karr init` composes
# App::karr::Role::BoardDiscovery, and the only way one helper can serve both
# is by depending on neither (the rule is ticket #141's, read from the other
# side).


# Where this file was loaded from, and how far above it the dist root sits.
# Both are derived from the package name so they cannot drift apart if the role
# is ever renamed or moved: lib/App/karr/Role/SkillFile.pm is four name parts
# below lib/, and lib/ is one more below the tree that also holds share/.
my @NAME_PARTS   = split /::/, __PACKAGE__;
my $OWN_INC_KEY  = join( '/', @NAME_PARTS ) . '.pm';
my $DIST_ROOT_UP = @NAME_PARTS + 1;

# The skills that ship, in the order every command handles and reports them.
# Each is a directory under share/ and, by the same name, the directory a
# target gets (.claude/skills/kanban-issues-karr-ticket, ...). This is the one
# list of them: `karr skill` and `karr init` both iterate it, so adding or
# splitting a skill is a change here and under share/, nowhere else.
sub _skill_names { qw( kanban-issues-karr-coordination kanban-issues-karr-ticket ) }

# Names earlier releases installed and this one no longer ships. A target
# directory by one of these names is a leftover: install and update remove it,
# check reports it stale. kanban-issues-karr-cli is the single skill the pair
# above was split out of; left in place it would brief an agent twice, once
# with the old text.
sub _retired_skill_names { qw( kanban-issues-karr-cli ) }

# One bundled skill directory. Two places to look, in order: File::ShareDir,
# which is where share/ lands when the dist is installed, and -- when it is
# not, i.e. a checkout being run with -Ilib -- share/ in that checkout. A
# share dir that answers but holds no NAME/SKILL.md (an App::karr from before
# #285, which shipped one claude-skill.md, or one from before the split, which
# shipped only kanban-issues-karr-cli/, is exactly that) falls through to the
# checkout rather than counting as found. Looked up per skill, so every name
# answers from wherever it is actually found.
#
# The second half has to know where that checkout is, and the only thing that
# knows is a file of the dist Perl has already loaded. Cmd::Skill and Cmd::Init
# each asked %INC for their own ($INC{'App/karr/Cmd/Skill.pm'} against
# $INC{'App/karr/Cmd/Init.pm'}), and that one line was the whole difference
# between their two copies of this sub (ticket #146). Naming either command's
# file from here would be the wrong fix twice over: it answers for one caller
# and sends the other silently on to the die below, and since MooX::Cmd decides
# which command classes get loaded, whether the miss happens would depend on how
# karr was invoked rather than showing up the first time. This file is the
# honest anchor instead. It belongs to the same dist as the share/ being looked
# for, it cannot fail to be loaded while one of its own methods is running, and
# it sits at the same depth below lib/ as the two command classes, so the climb
# is the one both copies made.
sub _skill_source_dir {
  my ($self, $name) = @_;

  # Installed dist: File::ShareDir knows where share/ went.
  my $installed = eval {
    my $dir = Path::Tiny::path( File::ShareDir::dist_dir('App-karr') )
                        ->child($name);
    $dir->child('SKILL.md')->exists ? $dir : undef;
  };
  return $installed if $installed;

  # Not installed: the share/ of the tree this file came out of.
  my $own_path = $INC{$OWN_INC_KEY};
  if ($own_path) {
    my $share = Path::Tiny::path($own_path)->parent($DIST_ROOT_UP)
                                           ->child( 'share', $name );
    return $share if $share->child('SKILL.md')->exists;
  }

  die "Could not find $name/SKILL.md. Is App::karr properly installed?\n";
}

# One bundled skill's SKILL.md, as characters (slurp_utf8 is Path::Tiny's own
# character-level read, which is what the file edge is allowed to use; decoding
# on top of it would be the double decode App::karr::Encoding forbids). This is
# what `karr skill show` prints: the entry point, not the references behind it.
sub _skill_content {
  my ($self, $name) = @_;
  return $self->_skill_source_dir($name)->child('SKILL.md')->slurp_utf8;
}

# Every file one skill ships, as (relative path => characters) pairs in sorted
# path order: SKILL.md, then references/*.md. Walked from the directory rather
# than listed, so a reference file added under share/ ships without anyone
# touching this role; only *.md counts, so an editor backup next to them never
# lands in someone's .claude. The relative path is what the writers below
# rejoin to a target directory, so the layout under share/ IS the layout a
# target gets. Read with slurp_utf8 for the reason given on _skill_content.
sub _skill_files {
  my ($self, $name) = @_;
  my $dir = $self->_skill_source_dir($name);
  my @found;
  $dir->visit(
    sub { my ($p) = @_; push @found, $p if $p->is_file && $p->basename =~ /\.md\z/ },
    { recurse => 1 },
  );
  return map  { ( $_ => $dir->child($_)->slurp_utf8 ) }
         sort map { $_->relative($dir)->stringify } @found;
}

# The retired skill directories present under $base -- the directory that
# holds the skill directories (.claude/skills, ~/.codex/skills, ...) -- as
# Path::Tiny objects. This is what check reports as stale. A dangling symlink
# by that name counts too: it is a leftover all the same.
sub _retired_skill_dirs {
  my ($self, $base) = @_;
  return grep { -e "$_" || -l "$_" }
         map  { $base->child($_) } $self->_retired_skill_names;
}

# Removes every retired skill directory under $base and returns the ones it
# removed, for the caller to report. File::Path unlinks a symlink rather than
# following it, and a file that is one link of a hardlink chain loses only
# this project's link, so another project still sharing the old skill keeps
# its copy. A failure is the target's layout, not a karr bug: one clean line
# naming the directory, like the write (#77). remove_tree reports some
# failures only as warnings, so what counts is whether the path is gone.
sub _remove_retired_skills {
  my ($self, $base) = @_;
  my @removed;
  for my $dir ( $self->_retired_skill_dirs($base) ) {
    my $error;
    eval {
      local $SIG{__WARN__} = sub { $error //= $_[0] };
      $dir->remove_tree( { safe => 0 } );
      1;
    } or $error = $@;
    App::karr::Error::user_error( "Could not remove $dir: ",
                                  App::karr::Error::clean_error( $error // 'still there' ) )
      if -e "$dir" || -l "$dir";
    push @removed, $dir;
  }
  return @removed;
}

# Written in place, on purpose. Path::Tiny's spew_utf8 writes a temp file and
# renames it over the target, so the path it wrote comes back on a *new* inode.
# For a SKILL.md that is the wrong move: skill files are kept as hardlink
# chains (manage-skills), one inode behind the same relative path in dozens of
# projects, so the rename silently breaks the updated path out of its chain --
# that one path gets the new text, every other project keeps the old inode with
# the old text, and the link count drops with nothing said (ticket #142, found
# in kubernetes-ocp, where the workaround was `karr skill show` into a shell
# redirect; ticket #145 for the same call left standing in `karr init
# --claude-skill`, which is why this lives in a role instead of in one command).
#
# append_utf8 with truncate is the in-place counterpart: Path::Tiny sysopens
# the existing inode for writing, locks it, truncates, and writes through it,
# so every link sees the new content. It is Path::Tiny's own UTF-8, i.e. still
# character-level, which is what the file edge is allowed to use -- encoding on
# top of it would be the double encode App::karr::Encoding forbids. A target
# that does not exist yet is created by the same call (">" with O_CREAT), so
# install, update and init share this one path.
sub _write_skill {
  my ($self, $file, $content) = @_;

  eval { $file->parent->mkpath; 1 }
    or App::karr::Error::user_error( "Could not write $file: ",
                                     App::karr::Error::clean_error($@) );

  return if eval { $file->append_utf8( { truncate => 1 }, $content ); 1 };
  my $in_place_error = $@;

  # Opening the file for writing is the one thing the rename never needed: it
  # only needs a writable *directory*, so it used to update a read-only
  # SKILL.md happily. Keep that working rather than turning a mode bit into a
  # failure -- but this is now the only way a chain can break, so when the
  # target really was hardlinked, say so instead of breaking it silently.
  my $links = ( stat "$file" )[3];
  eval { $file->spew_utf8($content); 1 }
    or App::karr::Error::user_error( "Could not write $file: ",
                                     App::karr::Error::clean_error($in_place_error) );

  if ( $links && $links > 1 ) {
    my $others = $links - 1;
    my $note = $others == 1
      ? 'one other hardlink to it still holds the previous content.'
      : "$others other hardlinks to it still hold the previous content.";
    warn "Warning: $file could not be written in place ("
      . App::karr::Error::clean_error($in_place_error)
      . ") and was replaced instead;\n$note\n";
  }

  return;
}

# A set of files into one target skill directory. $files is keyed the way
# _skill_files hands them out -- path relative to the skill directory -- and
# holds either the whole set (install, init) or the part of it a caller found
# missing or stale (update). Each one goes through _write_skill, so references/
# gets created on the way and an existing file keeps its inode. All three
# writers come through here: one description of how a skill directory gets
# written rather than three that drift (#285).
sub _write_skill_files {
  my ($self, $dir, $files) = @_;
  $self->_write_skill( $dir->child($_), $files->{$_} ) for sort keys %$files;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::SkillFile - The one way karr finds and writes the bundled skill directories

=head1 VERSION

version 0.602

=head1 DESCRIPTION

Three commands need the bundled skills: C<karr skill install> and
C<karr skill update> write them, C<karr skill show> prints their F<SKILL.md>,
and C<karr init --claude-skill> writes the same directories under
F<.claude/skills/> that C<karr skill install --agent claude-code> does. This
role is the single place that knows I<which> skills ship, I<where> they come
from and I<how> they have to be written, so none of those rules can be fixed
in one command and left wrong in the other, which is exactly what happened
between tickets #142 and #145.

Two skills ship, in this order: C<kanban-issues-karr-coordination> (reading a
board, picking, creating and routing cards, configuring and syncing karr) and
C<kanban-issues-karr-ticket> (working the one card an agent was handed). They
replace C<kanban-issues-karr-cli>, the single skill earlier releases shipped.
That name is I<retired>, and this role is also what finds and removes a
leftover directory of it in a target, so an agent is not briefed by the old
skill and the new pair at once.

Each skill is a directory, not one file: F<SKILL.md>, the short part an agent
loads on every trigger, plus -- where it has them -- F<references/*.md>, the
parts it reads on demand once F<SKILL.md> has pointed it there (#285). A skill
ships as F<share/NAME/>, and every C<*.md> under that directory is what gets
installed -- nothing is listed by name, so a new reference file ships without
a code change.

The lookup: that directory via L<File::ShareDir> when the dist is installed,
and out of the source tree this file was loaded from when it is not.

The write: every target file is written B<in place>, keeping its inode, so a
F<SKILL.md> that is one link of a hardlink chain shared across projects stays
part of that chain.

=head1 SEE ALSO

L<App::karr::Cmd::Skill>, L<App::karr::Cmd::Init>

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
