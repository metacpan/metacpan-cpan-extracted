# t/62-skill-doc-sync.t - share/kanban-issues-karr-cli/ and the repo's own
# .claude/skills/kanban-issues-karr-cli/ are the same skill in two places
# (shipped to users vs. what this repo's agents are briefed with). Since
# ticket #285 the skill is a directory -- SKILL.md plus references/*.md -- so
# the two trees must hold the same set of *.md files, and each pair's bodies
# (everything after the leading YAML frontmatter) must stay byte-identical;
# only the frontmatter (e.g. `name:`) is allowed to differ. A file present on
# one side only is a drift as much as a differing body is.
use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny qw( path );

my $repo_root      = path($FindBin::Bin)->parent;
my $share_dir      = $repo_root->child(qw( share kanban-issues-karr-cli ));
my $repo_skill_dir = $repo_root->child(qw( .claude skills kanban-issues-karr-cli ));

# .claude/ is not shipped in a dzil build, so under `dzil test` (or any
# checkout missing one of these directories) this is a repo-hygiene check that
# doesn't apply - skip rather than fail.
plan skip_all => "$share_dir and/or $repo_skill_dir not found - skipping doc-sync check outside a full source checkout"
  unless $share_dir->is_dir && $repo_skill_dir->is_dir;

# Strip a leading YAML frontmatter block delimited by the first two '---'
# lines. The frontmatter (name/description) legitimately differs between
# the two copies; only the body after it is required to match.
sub strip_frontmatter {
  my ($content) = @_;
  my @lines = split /\n/, $content, -1;
  if (@lines && $lines[0] eq '---') {
    for my $i (1 .. $#lines) {
      if ($lines[$i] eq '---') {
        return join("\n", @lines[$i + 1 .. $#lines]);
      }
    }
  }
  return $content;
}

# Every *.md under a skill directory, by path relative to it -- the same walk
# App::karr::Role::SkillFile::_skill_files does, so what is compared here is
# what `karr skill install` ships.
sub md_files_under {
  my ($dir) = @_;
  my @rel;
  $dir->visit(
    sub { my ($p) = @_; push @rel, $p->relative($dir)->stringify if $p->is_file && $p =~ /\.md\z/ },
    { recurse => 1 },
  );
  return sort @rel;
}

my @share_files = md_files_under($share_dir);
my @repo_files  = md_files_under($repo_skill_dir);

cmp_ok scalar(@share_files), '>=', 2,
  "share/kanban-issues-karr-cli/ holds SKILL.md and at least one reference (found @{[ scalar @share_files ]})";
ok( ( grep { $_ eq 'SKILL.md' } @share_files ), 'share/kanban-issues-karr-cli/SKILL.md exists' );
ok( ( grep { $_ eq 'SKILL.md' } @repo_files ),  '.claude/skills/kanban-issues-karr-cli/SKILL.md exists' );

is_deeply \@repo_files, \@share_files,
  'both directories hold the same set of *.md files'
  or do {
    my %share = map { $_ => 1 } @share_files;
    my %repo  = map { $_ => 1 } @repo_files;
    diag("only under share/:   $_") for grep { !$repo{$_} }  @share_files;
    diag("only under .claude/: $_") for grep { !$share{$_} } @repo_files;
  };

for my $rel (@share_files) {
  my $share_file = $share_dir->child($rel);
  my $repo_file  = $repo_skill_dir->child($rel);
  next unless $repo_file->exists;   # already reported above

  my $share_body = strip_frontmatter($share_file->slurp_utf8);
  my $repo_body  = strip_frontmatter($repo_file->slurp_utf8);

  if ($share_body eq $repo_body) {
    pass("$rel: bodies match after stripping frontmatter");
  }
  else {
    my @share_lines = split /\n/, $share_body, -1;
    my @repo_lines  = split /\n/, $repo_body, -1;
    my $max = @share_lines > @repo_lines ? scalar(@share_lines) : scalar(@repo_lines);
    for my $i (0 .. $max - 1) {
      my $a = $i < @share_lines ? $share_lines[$i] : '<no line - file ends here>';
      my $b = $i < @repo_lines  ? $repo_lines[$i]  : '<no line - file ends here>';
      if ($a ne $b) {
        diag("first differing body line is line " . ($i + 1) . " (counted after the frontmatter):");
        diag("  share/kanban-issues-karr-cli/$rel:           $a");
        diag("  .claude/skills/kanban-issues-karr-cli/$rel:  $b");
        last;
      }
    }
    fail("$rel: share/ and .claude/ copies have drifted apart - re-sync the two files (bodies after frontmatter must be byte-identical)");
  }
}

done_testing;
