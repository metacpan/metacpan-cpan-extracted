#!/usr/bin/env perl

# TOML::Tiny::Parser has a large compile cost and only Codex TOML
# agents need it, so it must load on first parse, not with App::Briefing.
# This file never loads TOML::Tiny itself; the "not loaded" checks run before
# the Codex part so that order cannot hide an eager load.

use strict;
use warnings;

use FindBin;
use Path::Tiny qw( path );
use Test::More;

use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use App::Briefing;
use App::Briefing::CLI;
use BriefingTest qw(
  claude_agent
  claude_skill
  codex_agent
  codex_skill
  hook_payload
  sandbox
  write_file
);

sub toml_loaded {
  return scalar grep { m{\ATOML/Tiny(?:/|\.pm\z)} } keys %INC;
}

ok(
  !toml_loaded(),
  'loading App::Briefing and App::Briefing::CLI does not load TOML::Tiny',
) or diag 'loaded: '.join ', ', sort grep { m{\ATOML/} } keys %INC;

my $box = sandbox();
my $briefing = App::Briefing->new(
  cwd        => $box->{cwd},
  home       => $box->{home},
  codex_home => $box->{codex_home},
);

# Codex TOML content is in place before the Claude part, so a Claude path that
# wrongly walks the Codex layers has something to parse and loads TOML::Tiny.
write_file(
  path($box->{codex_home}, 'config.toml'),
  "[agents.cfgrole]\nconfig_file = \"agents/cfgrole.toml\"\n",
);
write_file(
  path($box->{codex_home}, 'agents', 'cfgrole.toml'),
  "name = \"cfgrole\"\n",
);
codex_agent($box, 'cdx', "name = \"cdx\"\n[briefing]\nskills = [\"codex-present\"]\n");
codex_skill($box, 'codex-present', "---\nname: codex-present\n---\nCODEX SKILL BODY\n");

claude_agent($box, 'demo', 'present');
claude_skill($box, 'present', "---\nname: present\n---\nPRESENT SKILL BODY\n");

my $claude = $briefing->brief_agent('demo', harness => 'claude');
like($claude->{text}, qr/PRESENT SKILL BODY/, 'a Markdown agent still resolves');
my $hook = $briefing->process_hook(hook_payload($box));
is($hook->{exit_code}, 0, 'the Claude SubagentStart hook still succeeds');
like(
  $hook->{output}{hookSpecificOutput}{additionalContext},
  qr/PRESENT SKILL BODY/,
  'the Claude hook path briefed the Markdown agent',
);
ok(
  !toml_loaded(),
  'a Claude Markdown agent and its spawn hook do not load TOML::Tiny',
) or diag 'loaded: '.join ', ', sort grep { m{\ATOML/} } keys %INC;

my $codex = $briefing->brief_agent('cdx', harness => 'codex');
is_deeply($codex->{skills}, ['codex-present'], 'a Codex TOML agent declares its skills');
is_deeply($codex->{missing}, [], 'the Codex skill resolves');
like($codex->{text}, qr/CODEX SKILL BODY/, 'a Codex TOML agent still briefs');
ok($codex->{legacy}, 'the [briefing] table was parsed as TOML');
ok(
  $INC{'TOML/Tiny/Parser.pm'},
  'parsing a Codex TOML agent loads TOML::Tiny::Parser on demand',
);

done_testing;
