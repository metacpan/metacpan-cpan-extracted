#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Subagent;

# Test basic subagent creation
my $reviewer = Claude::Agent::Subagent->new(
    description => 'Expert code review specialist. Use for quality, security, and maintainability reviews.',
    prompt      => 'You are a code review specialist with expertise in security, performance, and best practices.',
);

isa_ok($reviewer, 'Claude::Agent::Subagent');
is(
    $reviewer->description,
    'Expert code review specialist. Use for quality, security, and maintainability reviews.',
    'description correct'
);
is(
    $reviewer->prompt,
    'You are a code review specialist with expertise in security, performance, and best practices.',
    'prompt correct'
);
ok(!$reviewer->has_tools, 'no tools by default');
ok(!$reviewer->has_model, 'no model by default');

# Test subagent with tools
my $test_runner = Claude::Agent::Subagent->new(
    description => 'Runs and analyzes test suites. Use for test execution and coverage analysis.',
    prompt      => 'You are a test execution specialist.',
    tools       => ['Bash', 'Read', 'Grep'],
);

ok($test_runner->has_tools, 'has tools');
is_deeply($test_runner->tools, ['Bash', 'Read', 'Grep'], 'tools correct');

# Test subagent with model
my $security_agent = Claude::Agent::Subagent->new(
    description => 'Security code reviewer for vulnerability analysis',
    prompt      => <<'PROMPT',
You are a security specialist. When reviewing code:
- Identify security vulnerabilities (OWASP Top 10)
- Check for injection risks
- Verify input validation
- Look for authentication/authorization issues
Be thorough but concise in your feedback.
PROMPT
    tools => ['Read', 'Grep', 'Glob'],
    model => 'opus',
);

ok($security_agent->has_model, 'has model');
is($security_agent->model, 'opus', 'model correct');
like($security_agent->prompt, qr/OWASP Top 10/, 'multiline prompt preserved');

# Test to_hash without tools/model
my $hash = $reviewer->to_hash;
is(
    $hash->{description},
    'Expert code review specialist. Use for quality, security, and maintainability reviews.',
    'to_hash description'
);
is(
    $hash->{prompt},
    'You are a code review specialist with expertise in security, performance, and best practices.',
    'to_hash prompt'
);
ok(!exists $hash->{tools}, 'to_hash no tools key when not set');
ok(!exists $hash->{model}, 'to_hash no model key when not set');

# Test to_hash with tools
$hash = $test_runner->to_hash;
is_deeply($hash->{tools}, ['Bash', 'Read', 'Grep'], 'to_hash tools');

# Test to_hash with model
$hash = $security_agent->to_hash;
is($hash->{model}, 'opus', 'to_hash model');
is_deeply($hash->{tools}, ['Read', 'Grep', 'Glob'], 'to_hash tools with model');

# Test model values
for my $model (qw(sonnet opus haiku)) {
    my $agent = Claude::Agent::Subagent->new(
        description => 'Test agent',
        prompt      => 'Test prompt',
        model       => $model,
    );
    is($agent->model, $model, "model '$model' works");
}

# Test integration with Options
use Claude::Agent::Options;

my $options = Claude::Agent::Options->new(
    allowed_tools => ['Read', 'Glob', 'Grep', 'Task'],
    agents        => {
        'code-reviewer' => $reviewer,
        'test-runner'   => $test_runner,
        'security'      => $security_agent,
    },
);

ok($options->has_agents, 'options has agents');
is(scalar keys %{$options->agents}, 3, 'options has 3 agents');
isa_ok($options->agents->{'code-reviewer'}, 'Claude::Agent::Subagent');
isa_ok($options->agents->{'test-runner'}, 'Claude::Agent::Subagent');
isa_ok($options->agents->{'security'}, 'Claude::Agent::Subagent');

# Test to_hash integration
my $opts_hash = $options->to_hash;
ok(exists $opts_hash->{agents}, 'options to_hash has agents');
is(
    $opts_hash->{agents}{'code-reviewer'}{description},
    'Expert code review specialist. Use for quality, security, and maintainability reviews.',
    'options to_hash agent description'
);
is_deeply(
    $opts_hash->{agents}{'test-runner'}{tools},
    ['Bash', 'Read', 'Grep'],
    'options to_hash agent tools'
);
is($opts_hash->{agents}{'security'}{model}, 'opus', 'options to_hash agent model');

# Test documentation generator example from POD
my $doc_agent = Claude::Agent::Subagent->new(
    description => 'Documentation specialist for generating API docs',
    prompt      => 'Generate clear, comprehensive API documentation.',
    tools       => ['Read', 'Glob'],
);

is($doc_agent->description, 'Documentation specialist for generating API docs', 'doc agent description');
is_deeply($doc_agent->tools, ['Read', 'Glob'], 'doc agent tools');

done_testing();
