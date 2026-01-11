#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Content;

# Test TextBlock
my $text = Claude::Agent::Content::Text->new(
    text => 'Hello, world!',
);

isa_ok($text, 'Claude::Agent::Content::Text');
# Note: Content types don't inherit from Claude::Agent::Content
is($text->type, 'text', 'TextBlock type is text');
is($text->text, 'Hello, world!', 'text content correct');

# Test ThinkingBlock
my $thinking = Claude::Agent::Content::Thinking->new(
    thinking  => 'Let me analyze this...',
    signature => 'sig-123',
);

isa_ok($thinking, 'Claude::Agent::Content::Thinking');
is($thinking->type, 'thinking', 'ThinkingBlock type is thinking');
is($thinking->thinking, 'Let me analyze this...', 'thinking content correct');
is($thinking->signature, 'sig-123', 'signature correct');

# Test ToolUseBlock
my $tool_use = Claude::Agent::Content::ToolUse->new(
    id    => 'tool-use-123',
    name  => 'Read',
    input => { file_path => '/tmp/test.txt' },
);

isa_ok($tool_use, 'Claude::Agent::Content::ToolUse');
is($tool_use->type, 'tool_use', 'ToolUseBlock type is tool_use');
is($tool_use->id, 'tool-use-123', 'id correct');
is($tool_use->name, 'Read', 'name correct');
is_deeply($tool_use->input, { file_path => '/tmp/test.txt' }, 'input correct');

# Test is_mcp_tool()
ok(!$tool_use->is_mcp_tool, 'Read is not an MCP tool');

my $mcp_tool = Claude::Agent::Content::ToolUse->new(
    id    => 'tool-use-456',
    name  => 'mcp__math__calculate',
    input => { expression => '2 + 2' },
);

ok($mcp_tool->is_mcp_tool, 'mcp__math__calculate is an MCP tool');
is($mcp_tool->mcp_server, 'math', 'mcp_server extracts correctly');
is($mcp_tool->mcp_tool_name, 'calculate', 'mcp_tool_name extracts correctly');

# Test ToolResultBlock
my $tool_result = Claude::Agent::Content::ToolResult->new(
    tool_use_id => 'tool-use-123',
    content     => 'File contents here',
    is_error    => 0,
);

isa_ok($tool_result, 'Claude::Agent::Content::ToolResult');
is($tool_result->type, 'tool_result', 'ToolResultBlock type is tool_result');
is($tool_result->tool_use_id, 'tool-use-123', 'tool_use_id correct');
is($tool_result->content, 'File contents here', 'content correct');
ok(!$tool_result->is_error, 'is_error correct');

# Test error ToolResult
my $error_result = Claude::Agent::Content::ToolResult->new(
    tool_use_id => 'tool-use-789',
    content     => 'File not found',
    is_error    => 1,
);

ok($error_result->is_error, 'error result is_error is true');

# Test from_json factory method
my $text_json = { type => 'text', text => 'Parsed text' };
my $parsed_text = Claude::Agent::Content->from_json($text_json);
isa_ok($parsed_text, 'Claude::Agent::Content::Text');
is($parsed_text->text, 'Parsed text', 'from_json text block');

my $thinking_json = {
    type      => 'thinking',
    thinking  => 'Parsed thinking',
    signature => 'parsed-sig',
};
my $parsed_thinking = Claude::Agent::Content->from_json($thinking_json);
isa_ok($parsed_thinking, 'Claude::Agent::Content::Thinking');
is($parsed_thinking->thinking, 'Parsed thinking', 'from_json thinking block');

my $tool_use_json = {
    type  => 'tool_use',
    id    => 'parsed-id',
    name  => 'Bash',
    input => { command => 'ls -la' },
};
my $parsed_tool_use = Claude::Agent::Content->from_json($tool_use_json);
isa_ok($parsed_tool_use, 'Claude::Agent::Content::ToolUse');
is($parsed_tool_use->name, 'Bash', 'from_json tool_use block');
is_deeply($parsed_tool_use->input, { command => 'ls -la' }, 'from_json tool_use input');

my $tool_result_json = {
    type        => 'tool_result',
    tool_use_id => 'result-id',
    content     => 'Result content',
    is_error    => 0,
};
my $parsed_result = Claude::Agent::Content->from_json($tool_result_json);
isa_ok($parsed_result, 'Claude::Agent::Content::ToolResult');
is($parsed_result->content, 'Result content', 'from_json tool_result block');

# Test unknown type returns raw hashref
my $unknown_json = { type => 'unknown_type' };
my $parsed_unknown = Claude::Agent::Content->from_json($unknown_json);
is_deeply($parsed_unknown, { type => 'unknown_type' }, 'from_json returns hashref for unknown type');

done_testing();
