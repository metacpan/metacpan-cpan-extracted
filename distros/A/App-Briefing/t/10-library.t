#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::More;

use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use App::Briefing;
use BriefingTest qw(
  claude_agent
  claude_skill
  hook_payload
  sandbox
);

my $box = sandbox();
my $briefing = App::Briefing->new(
  cwd        => $box->{cwd},
  home       => $box->{home},
  codex_home => $box->{codex_home},
);

my $noop = $briefing->process_hook({
  hook_event_name => 'SubagentStop',
  cwd             => $box->{cwd},
});
is_deeply(
  $noop,
  {
    output    => undef,
    stderr    => '',
    exit_code => 0,
  },
  'irrelevant hook events are side-effect-free no-ops',
);

claude_agent($box, 'demo', 'present');
claude_skill(
  $box,
  'present',
  "---\nname: present\n---\nPRESENT SKILL BODY\n",
);

my $resolved = $briefing->brief_agent('demo', harness => 'claude');
is($resolved->{agent}, 'demo', 'brief_agent identifies the agent');
is($resolved->{harness}, 'claude', 'brief_agent records its harness');
is_deeply($resolved->{skills}, ['present'], 'brief_agent records declared skills');
is_deeply($resolved->{missing}, [], 'resolved skills have no missing entries');
like($resolved->{text}, qr/PRESENT SKILL BODY/, 'brief_agent returns injected skill text');
like($resolved->{path}, qr/\.claude[\\\/]agents[\\\/]demo\.md\z/, 'brief_agent returns the agent path');
ok(!$resolved->{legacy}, 'a Claude declaration is not legacy TOML');

my $spawn = $briefing->process_hook(hook_payload($box));
is($spawn->{exit_code}, 0, 'successful SubagentStart exits zero');
is($spawn->{stderr}, '', 'successful SubagentStart has no stderr');
like(
  $spawn->{output}{hookSpecificOutput}{additionalContext},
  qr/PRESENT SKILL BODY/,
  'successful SubagentStart injects the resolved skill',
);
ok(
  !exists $spawn->{output}{hookSpecificOutput}{updatedInput},
  'SubagentStart uses additionalContext rather than updatedInput',
);

claude_agent($box, 'demo', 'present', 'missing-skill');
my $incomplete = $briefing->brief_agent('demo', harness => 'claude');
is_deeply(
  $incomplete->{missing},
  ['missing-skill'],
  'brief_agent lists missing declared skills',
);
is(
  $incomplete->{text},
  '',
  'a missing skill removes all partial briefing text from the public result',
);

my $failed_spawn = $briefing->process_hook(hook_payload($box));
like(
  $failed_spawn->{output}{hookSpecificOutput}{additionalContext},
  qr/missing-skill/,
  'a failed SubagentStart names the missing skill',
);
unlike(
  $failed_spawn->{output}{hookSpecificOutput}{additionalContext},
  qr/PRESENT SKILL BODY/,
  'a failed SubagentStart never injects partial skill text',
);

my $guard = $briefing->process_hook({
  hook_event_name => 'PreToolUse',
  tool_name       => 'Agent',
  cwd             => $box->{cwd},
  tool_input      => {
    subagent_type => 'demo',
    prompt        => 'ORIGINAL PROMPT',
  },
});
is($guard->{exit_code}, 0, 'a guard rejection still exits zero');
is(
  $guard->{output}{hookSpecificOutput}{permissionDecision},
  'deny',
  'the guard denies an agent with a missing declared skill',
);
ok(
  !exists $guard->{output}{hookSpecificOutput}{updatedInput},
  'the guard never rewrites Agent tool input',
);
ok(
  !exists $guard->{output}{updatedInput},
  'the guard has no top-level rewritten input either',
);

my $checked = $briefing->check_agents(harness => 'claude');
is(scalar @{$checked}, 1, 'check_agents finds the declared Claude agent');
is_deeply(
  $checked->[0]{missing},
  ['missing-skill'],
  'check_agents reports the same unresolved declaration',
);
is(
  $checked->[0]{text},
  '',
  'check_agents exposes no partial text for a missing declaration',
);

my $preflight = $briefing->process_hook({
  hook_event_name => 'SessionStart',
  source          => 'startup',
  cwd             => $box->{cwd},
  transcript_path => $box->{home}.'/.claude/projects/project/session.jsonl',
});
is($preflight->{exit_code}, 0, 'preflight warnings never fail SessionStart');
like(
  $preflight->{output}{systemMessage},
  qr/missing-skill/,
  'preflight reports declarations that will fail at spawn time',
);
ok(
  !exists $preflight->{output}{hookSpecificOutput},
  'preflight warns the human without adding model context',
);

my $other = sandbox();
claude_agent($other, 'demo', 'other-skill');
claude_skill($other, 'other-skill', "SECOND FIXTURE BODY\n");
my $other_spawn = $briefing->process_hook(hook_payload($other));
like(
  $other_spawn->{output}{hookSpecificOutput}{additionalContext},
  qr/SECOND FIXTURE BODY/,
  'payload cwd applies to that hook call',
);
is(
  $briefing->brief_agent('demo', harness => 'claude')->{text},
  '',
  'a payload cwd does not permanently change the library context',
);

done_testing;
