#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Encode qw( encode_utf8 );
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
my $skill_name = "grüße-技能";
my $skill_body = "UNICODE FIXTURE BODY\n";
claude_agent($box, 'demo', $skill_name);
claude_skill($box, $skill_name, $skill_body);

my $briefing = App::Briefing->new(
  cwd        => $box->{cwd},
  home       => $box->{home},
  codex_home => $box->{codex_home},
);
my $result = $briefing->brief_agent('demo', harness => 'claude');
is_deeply($result->{skills}, [$skill_name], 'Unicode skill names resolve through the public library');
is_deeply($result->{missing}, [], 'Unicode skill paths do not become missing skills');
like($result->{text}, qr/UNICODE FIXTURE BODY/, 'Unicode skill paths load their body');
is(
  $result->{size},
  length encode_utf8($result->{text}),
  'briefing size counts UTF-8 bytes rather than Perl characters',
);

my $hook = $briefing->process_hook(hook_payload($box));
is($hook->{exit_code}, 0, 'Unicode fixture hook processing exits zero');
like(
  $hook->{output}{hookSpecificOutput}{additionalContext},
  qr/UNICODE FIXTURE BODY/,
  'Unicode fixture injection reaches the hook result',
);

done_testing;
