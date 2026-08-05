# t/62-skill-doc-sync.t - share/claude-skill.md and the repo's own
# .claude/skills/kanban-issues-karr-cli/SKILL.md are the same skill in two
# places (shipped to users vs. what this repo's agents are briefed with).
# Their bodies (everything after the leading YAML frontmatter) must stay
# byte-identical; only the frontmatter (e.g. `name:`) is allowed to differ.
use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny qw( path );

my $repo_root       = path($FindBin::Bin)->parent;
my $share_file       = $repo_root->child(qw( share claude-skill.md ));
my $repo_skill_file  = $repo_root->child(qw( .claude skills kanban-issues-karr-cli SKILL.md ));

# .claude/ is not shipped in a dzil build, so under `dzil test` (or any
# checkout missing one of these files) this is a repo-hygiene check that
# doesn't apply - skip rather than fail.
plan skip_all => "$share_file and/or $repo_skill_file not found - skipping doc-sync check outside a full source checkout"
  unless $share_file->exists && $repo_skill_file->exists;

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

my $share_body = strip_frontmatter($share_file->slurp_utf8);
my $repo_body  = strip_frontmatter($repo_skill_file->slurp_utf8);

if ($share_body eq $repo_body) {
  pass('share/claude-skill.md and .claude/skills/kanban-issues-karr-cli/SKILL.md bodies match after stripping frontmatter');
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
      diag("  share/claude-skill.md:                           $a");
      diag("  .claude/skills/kanban-issues-karr-cli/SKILL.md:  $b");
      last;
    }
  }
  fail('share/claude-skill.md and .claude/skills/kanban-issues-karr-cli/SKILL.md have drifted apart - re-sync the two files (bodies after frontmatter must be byte-identical)');
}

done_testing;
