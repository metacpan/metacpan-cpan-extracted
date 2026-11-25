use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

for my $module (qw(App::Briefing App::Briefing::CLI App::Briefing::Filesystem App::Briefing::Team)) {
  require_ok($module);
  ok(defined $module->VERSION, "$module has a version");
}

my $err = '';
my $rc = do {
  open my $fh, '>', \$err or die $!;
  local *STDERR = $fh;
  App::Briefing::CLI->run([]);
};
is($rc, 1, 'run returns 1');
like($err, qr/^briefing is retired: Claude Code now preloads agent skills natively\./, 'notice start');
like($err, qr/top-level `skills:` list/, 'names the replacement');
like($err, qr{/plugin uninstall briefing}, 'names the uninstall');
like($err, qr{https://code\.claude\.com/docs/en/sub-agents#preload-skills-into-subagents}, 'carries the URL');

done_testing;
