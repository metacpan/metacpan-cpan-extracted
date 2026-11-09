use strict;
use warnings;

use Test::More;

# Every dbio-* skill whose source lives in core's .claude/skills/ is either
# shipped through a share_skill line in dist.ini, or is named below as owned
# by another distribution. A skill that is neither is a skill nobody gets
# (karr k290: dbio-perl-pod was tracked here and shipped by no dist).

# Owned by, and shipped from, another distribution (see DBIO::Skills,
# "Skill categories"): the [@DBIO] release skill belongs to
# Dist-Zilla-PluginBundle-DBIO.
my %owned_elsewhere = (
  'dbio-perl-release' => 'Dist-Zilla-PluginBundle-DBIO',
);

my @tracked = do {
  my %dir;
  my $out = `git ls-files .claude/skills 2>/dev/null`;
  for my $path (split /\n/, $out) {
    $dir{$1} = 1 if $path =~ m{^\.claude/skills/(dbio-[^/]+)/};
  }
  sort keys %dir;
};

plan skip_all => 'not a git checkout (or no tracked skills)' unless @tracked;

open my $fh, '<', 'dist.ini' or die "dist.ini: $!";
my %shared = map { /^\s*share_skill\s*=\s*(\S+)/ ? ($1 => 1) : () } <$fh>;
close $fh;

for my $skill (@tracked) {
  if (my $owner = $owned_elsewhere{$skill}) {
    ok(!$shared{$skill},
      "$skill is owned by $owner and is not a share_skill of core");
  }
  else {
    ok($shared{$skill}, "$skill has a share_skill line in dist.ini");
  }
}

for my $skill (sort keys %shared) {
  ok(scalar(grep { $_ eq $skill } @tracked),
    "share_skill $skill has a tracked source in .claude/skills");
}

done_testing;
