# t/136-skill-command-coverage.t - every command implemented under
# lib/App/karr/Cmd/*.pm must be mentioned by name in the skill doc that ships
# to users, share/claude-skill.md (installed into other people's projects by
# `karr skill install` via File::ShareDir).
#
# t/62-skill-doc-sync.t already keeps share/claude-skill.md and the repo's
# own .claude/skills/kanban-issues-karr-cli/SKILL.md byte-identical (barring
# frontmatter), so asserting coverage against either copy covers both without
# duplicating that check here. This one checks share/claude-skill.md
# specifically: it is the copy that actually reaches users, and unlike
# .claude/ (repo-only, absent from a `dzil build` tree) it is present in both
# a plain source checkout and a built dist, so the check runs sharp in more
# places instead of skipping.
use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny qw( path );

my $repo_root  = path($FindBin::Bin)->parent;
my $skill_file = $repo_root->child(qw( share claude-skill.md ));
my $cmd_dir    = $repo_root->child(qw( lib App karr Cmd ));

# Neither file/dir ships outside a full source checkout in a way this test
# can rely on (e.g. an installed-only tree without lib/ or share/ sitting
# next to t/), so skip cleanly there rather than fail. Both are present in
# this repo checkout and in a `dzil build` tree, so this runs sharp in both.
plan skip_all => "$skill_file and/or $cmd_dir not found - skipping command-coverage check outside a full source checkout"
  unless $skill_file->exists && $cmd_dir->is_dir;

# MooX::Cmd derives a command's dispatch name from its class basename by
# lowercasing it whole (App::karr::Cmd::AgentName => "agentname"); App::karr
# separately registers the dashed spelling users actually type (agent-name,
# set-refs, get-refs) as extra aliases in a %COMMAND_ALIASES table private to
# lib/App/karr.pm. Hardcoding a second copy of that table here would only
# catch drift in the three names it already lists, and silently miss the
# next two-word command someone adds. Deriving the dashed form generally --
# split the class basename on capitalised-letter boundaries, lowercase, join
# with '-' -- covers any future name the same way it covers the current
# ones: AgentName => agent-name, SetRefs => set-refs, Show => show, ...
sub class_to_command_name {
  my ($basename) = @_;
  my @words = $basename =~ /([A-Z][a-z0-9]*)/g;
  return lc join '-', @words;
}

my @cmd_files = sort map { $_->basename(qr/\.pm\z/) } $cmd_dir->children(qr/\.pm\z/);

cmp_ok(scalar @cmd_files, '>', 0, "found command modules under $cmd_dir");

my $skill_text = $skill_file->slurp_utf8;

for my $basename (@cmd_files) {
  my $command = class_to_command_name($basename);
  my $found = $skill_text =~ /\b\Q$command\E\b/;
  ok($found, "share/claude-skill.md mentions '$command' (App::karr::Cmd::$basename)")
    or diag("lib/App/karr/Cmd/$basename.pm implements '$command' but that name does not appear in $skill_file - document it there (and in .claude/skills/kanban-issues-karr-cli/SKILL.md, kept in sync by t/62-skill-doc-sync.t)");
}

done_testing;
