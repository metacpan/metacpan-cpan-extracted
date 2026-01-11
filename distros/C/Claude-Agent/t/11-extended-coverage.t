#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Extended coverage tests for Claude::Agent
# Tests edge cases and recently modified code paths

use Claude::Agent::Message;
use Claude::Agent::Content;
use Claude::Agent::Permission;

# =============================================================================
# Tests for _camel_to_snake consecutive uppercase handling
# (Fixed in Message.pm to handle 'UUID' -> 'uuid', 'getHTTPURL' -> 'get_http_url')
# =============================================================================

subtest '_camel_to_snake conversion' => sub {
    # Access the internal function via from_json which uses _normalize_data

    # Standard camelCase
    my $data = Claude::Agent::Message->from_json({
        type      => 'user',
        uuid      => 'test',
        sessionId => 'session-123',  # should become session_id
        message   => { role => 'user', content => 'test' },
    });
    is($data->session_id, 'session-123', 'sessionId -> session_id');

    # Test consecutive uppercase via result message (has many camelCase keys)
    my $result = Claude::Agent::Message->from_json({
        type         => 'result',
        uuid         => 'res-uuid',
        sessionId    => 'session-456',
        subtype      => 'success',
        result       => 'done',
        durationMs   => 1000,        # duration_ms
        totalCostUsd => 0.05,        # total_cost_usd (has 'Usd')
        numTurns     => 5,           # num_turns
        isError      => 0,           # is_error
    });
    is($result->duration_ms, 1000, 'durationMs -> duration_ms');
    is($result->total_cost_usd, 0.05, 'totalCostUsd -> total_cost_usd');
    is($result->num_turns, 5, 'numTurns -> num_turns');
    ok(!$result->is_error, 'isError -> is_error');
};

# =============================================================================
# Tests for ToolResult.text() edge cases
# =============================================================================

subtest 'ToolResult.text() edge cases' => sub {
    # Test with string content
    my $result = Claude::Agent::Content::ToolResult->new(
        tool_use_id => 'tool-1',
        content     => 'Simple string result',
    );
    is($result->text, 'Simple string result', 'text() with string content');

    # Test with array content containing text blocks
    $result = Claude::Agent::Content::ToolResult->new(
        tool_use_id => 'tool-2',
        content     => [
            { type => 'text', text => 'Line 1' },
            { type => 'text', text => 'Line 2' },
        ],
    );
    is($result->text, "Line 1\nLine 2", 'text() with array of text blocks');

    # Test with mixed content types (should only extract text)
    $result = Claude::Agent::Content::ToolResult->new(
        tool_use_id => 'tool-3',
        content     => [
            { type => 'text', text => 'Visible text' },
            { type => 'image', data => 'base64...' },  # should be ignored
            { type => 'text', text => 'More text' },
        ],
    );
    is($result->text, "Visible text\nMore text", 'text() ignores non-text blocks');

    # Test with block missing 'text' key (should not crash)
    $result = Claude::Agent::Content::ToolResult->new(
        tool_use_id => 'tool-4',
        content     => [
            { type => 'text', text => 'Has text' },
            { type => 'text' },  # Missing 'text' key - should be skipped
            { type => 'text', text => undef },  # undef text - should be skipped
        ],
    );
    is($result->text, 'Has text', 'text() skips blocks with missing/undef text');

    # Test with empty array
    $result = Claude::Agent::Content::ToolResult->new(
        tool_use_id => 'tool-5',
        content     => [],
    );
    is($result->text, '', 'text() with empty array returns empty string');
};

# =============================================================================
# Tests for Permission::Result::Allow with optional fields
# (Tests to_hash includes fields when set with values)
# =============================================================================

subtest 'Allow.to_hash with optional fields' => sub {
    # Allow with updated_input set to a value
    my $allow = Claude::Agent::Permission->allow(
        updated_input => { file_path => '/tmp/test' },
    );
    my $hash = $allow->to_hash;
    is($hash->{behavior}, 'allow', 'to_hash has behavior');
    is_deeply($hash->{updatedInput}, { file_path => '/tmp/test' }, 'to_hash includes updatedInput when set');

    # Allow with updated_permissions set
    $allow = Claude::Agent::Permission->allow(
        updated_permissions => { 'Read:/tmp/*' => 'allow' },
    );
    $hash = $allow->to_hash;
    is($hash->{behavior}, 'allow', 'to_hash has behavior with permissions');
    is_deeply($hash->{updatedPermissions}, { 'Read:/tmp/*' => 'allow' }, 'to_hash includes updatedPermissions when set');

    # Allow with both optional fields
    $allow = Claude::Agent::Permission->allow(
        updated_input       => { data => 'test' },
        updated_permissions => { 'Write:/tmp/*' => 'allow' },
    );
    $hash = $allow->to_hash;
    is($hash->{behavior}, 'allow', 'to_hash has behavior when both set');
    is_deeply($hash->{updatedInput}, { data => 'test' }, 'to_hash includes updatedInput');
    is_deeply($hash->{updatedPermissions}, { 'Write:/tmp/*' => 'allow' }, 'to_hash includes updatedPermissions');

    # Direct instantiation with no optional fields - tests has_* predicates
    $allow = Claude::Agent::Permission::Result::Allow->new();
    $hash = $allow->to_hash;
    is($hash->{behavior}, 'allow', 'direct instantiation has behavior');
    ok(!exists $hash->{updatedInput}, 'direct instantiation excludes updatedInput');
    ok(!exists $hash->{updatedPermissions}, 'direct instantiation excludes updatedPermissions');
};

# =============================================================================
# Tests for Message::Assistant with edge cases
# =============================================================================

subtest 'Assistant message edge cases' => sub {
    # Test with non-array content (should handle gracefully)
    my $msg = Claude::Agent::Message::Assistant->new(
        type       => 'assistant',
        uuid       => 'uuid-1',
        session_id => 'session-1',
        message    => {
            role    => 'assistant',
            content => 'A plain string instead of array',  # Not an array!
        },
    );
    my $blocks = $msg->content_blocks;
    is(ref($blocks), 'ARRAY', 'content_blocks returns array even with non-array content');
    is(scalar @$blocks, 0, 'content_blocks is empty when content is not array');
    is($msg->text, '', 'text() returns empty string for non-array content');
    is_deeply($msg->tool_uses, [], 'tool_uses returns empty array for non-array content');

    # Test with undef content
    $msg = Claude::Agent::Message::Assistant->new(
        type       => 'assistant',
        uuid       => 'uuid-2',
        session_id => 'session-2',
        message    => {
            role    => 'assistant',
            content => undef,
        },
    );
    $blocks = $msg->content_blocks;
    is(ref($blocks), 'ARRAY', 'content_blocks returns array with undef content');
    is(scalar @$blocks, 0, 'content_blocks is empty with undef content');

    # Test with hash content (another invalid case)
    $msg = Claude::Agent::Message::Assistant->new(
        type       => 'assistant',
        uuid       => 'uuid-3',
        session_id => 'session-3',
        message    => {
            role    => 'assistant',
            content => { type => 'text', text => 'wrapped' },  # Hash not array
        },
    );
    $blocks = $msg->content_blocks;
    is(ref($blocks), 'ARRAY', 'content_blocks returns array with hash content');
    is(scalar @$blocks, 0, 'content_blocks is empty with hash content');

    # Test caching behavior - returns shallow copy but content is equivalent
    $msg = Claude::Agent::Message::Assistant->new(
        type       => 'assistant',
        uuid       => 'uuid-4',
        session_id => 'session-4',
        message    => {
            role    => 'assistant',
            content => [{ type => 'text', text => 'cached' }],
        },
    );
    my $blocks1 = $msg->content_blocks;
    my $blocks2 = $msg->content_blocks;
    is(scalar @$blocks1, scalar @$blocks2, 'content_blocks returns same count on multiple calls');
    # Objects inside are shared (shallow copy)
    ok($blocks1->[0] == $blocks2->[0], 'content_blocks shares Content objects between calls');
};

# =============================================================================
# Tests for ToolUse MCP helpers
# =============================================================================

subtest 'ToolUse MCP detection and parsing' => sub {
    # Non-MCP tools
    my $tool = Claude::Agent::Content::ToolUse->new(
        id    => 'id-1',
        name  => 'Read',
        input => {},
    );
    ok(!$tool->is_mcp_tool, 'Read is not MCP tool');
    is($tool->mcp_server, undef, 'mcp_server undef for non-MCP');
    is($tool->mcp_tool_name, undef, 'mcp_tool_name undef for non-MCP');

    # Standard MCP tool
    $tool = Claude::Agent::Content::ToolUse->new(
        id    => 'id-2',
        name  => 'mcp__filesystem__read_file',
        input => { path => '/tmp/test' },
    );
    ok($tool->is_mcp_tool, 'mcp__filesystem__read_file is MCP tool');
    is($tool->mcp_server, 'filesystem', 'mcp_server extracted');
    is($tool->mcp_tool_name, 'read_file', 'mcp_tool_name extracted');

    # MCP tool with dashes in names
    $tool = Claude::Agent::Content::ToolUse->new(
        id    => 'id-3',
        name  => 'mcp__my-server__my-tool',
        input => {},
    );
    ok($tool->is_mcp_tool, 'mcp__my-server__my-tool is MCP tool');
    is($tool->mcp_server, 'my-server', 'mcp_server with dashes');
    is($tool->mcp_tool_name, 'my-tool', 'mcp_tool_name with dashes');

    # Edge case: tool name starts with mcp but not MCP format
    $tool = Claude::Agent::Content::ToolUse->new(
        id    => 'id-4',
        name  => 'mcp_not_a_real_mcp_tool',  # Single underscores
        input => {},
    );
    ok(!$tool->is_mcp_tool, 'mcp_not_a_real_mcp_tool is not MCP (single underscores)');

    # Edge case: partial mcp prefix
    $tool = Claude::Agent::Content::ToolUse->new(
        id    => 'id-5',
        name  => 'mcprefix__server__tool',
        input => {},
    );
    ok(!$tool->is_mcp_tool, 'mcprefix__ is not MCP prefix');
};

# =============================================================================
# Tests for Deny permission result
# =============================================================================

subtest 'Deny permission edge cases' => sub {
    # Deny with minimal args
    my $deny = Claude::Agent::Permission->deny(
        message => 'Access denied',
    );
    is($deny->behavior, 'deny', 'deny behavior');
    is($deny->message, 'Access denied', 'deny message');
    ok(!$deny->interrupt, 'deny without interrupt defaults to false');

    # Deny with explicit false interrupt
    $deny = Claude::Agent::Permission->deny(
        message   => 'Denied but continue',
        interrupt => 0,
    );
    ok(!$deny->interrupt, 'deny with interrupt => 0');

    # Deny with true interrupt
    $deny = Claude::Agent::Permission->deny(
        message   => 'Blocked!',
        interrupt => 1,
    );
    ok($deny->interrupt, 'deny with interrupt => 1');

    # Test to_hash JSON boolean encoding
    my $hash = $deny->to_hash;
    ok(ref($hash->{interrupt}), 'interrupt is a reference (JSON boolean)');
    ok(${$hash->{interrupt}}, 'interrupt JSON true value');

    $deny = Claude::Agent::Permission->deny(
        message   => 'No interrupt',
        interrupt => 0,
    );
    $hash = $deny->to_hash;
    ok(ref($hash->{interrupt}), 'interrupt false is still a reference');
    ok(!${$hash->{interrupt}}, 'interrupt JSON false value');
};

# =============================================================================
# Tests for MCP ToolDefinition execution
# =============================================================================

subtest 'ToolDefinition error handling' => sub {
    use Claude::Agent::MCP;

    # Tool that throws exception
    my $err_tool = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'error_tool',
        description  => 'Always throws',
        input_schema => {},
        handler      => sub { die "Intentional test error\n" },
    );

    my $result = $err_tool->execute({});
    ok($result->{is_error}, 'error tool sets is_error');
    like($result->{content}[0]{text}, qr/Error executing tool/, 'error message present');
    like($result->{content}[0]{text}, qr/error_tool/, 'error message includes tool name');

    # Tool returning explicit is_error
    my $explicit_err = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'explicit_error',
        description  => 'Returns explicit error',
        input_schema => {},
        handler      => sub {
            return {
                content  => [{ type => 'text', text => 'Custom error message' }],
                is_error => 1,
            };
        },
    );

    $result = $explicit_err->execute({});
    ok($result->{is_error}, 'explicit is_error preserved');
    is($result->{content}[0]{text}, 'Custom error message', 'custom error message preserved');

    # Tool returning success
    my $success_tool = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'success_tool',
        description  => 'Always succeeds',
        input_schema => {},
        handler      => sub {
            return {
                content => [{ type => 'text', text => 'Success!' }],
            };
        },
    );

    $result = $success_tool->execute({});
    ok(!$result->{is_error}, 'success tool no is_error');
    is($result->{content}[0]{text}, 'Success!', 'success content returned');
};

# =============================================================================
# Tests for MCP Server tool lookup
# =============================================================================

subtest 'MCP Server get_tool' => sub {
    use Claude::Agent::MCP;

    my $tool1 = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'tool_one',
        description  => 'First tool',
        input_schema => {},
        handler      => sub { return { content => [] } },
    );

    my $tool2 = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'tool_two',
        description  => 'Second tool',
        input_schema => {},
        handler      => sub { return { content => [] } },
    );

    my $server = Claude::Agent::MCP::Server->new(
        name  => 'test-server',
        tools => [$tool1, $tool2],
    );

    # Find existing tools
    my $found = $server->get_tool('tool_one');
    is($found->name, 'tool_one', 'get_tool finds tool_one');

    $found = $server->get_tool('tool_two');
    is($found->name, 'tool_two', 'get_tool finds tool_two');

    # Non-existent tool
    $found = $server->get_tool('nonexistent');
    is($found, undef, 'get_tool returns undef for missing tool');

    $found = $server->get_tool('');
    is($found, undef, 'get_tool returns undef for empty string');

    $found = $server->get_tool(undef);
    is($found, undef, 'get_tool returns undef for undef');
};

# =============================================================================
# Tests for Content from_json edge cases
# =============================================================================

subtest 'Content from_json edge cases' => sub {
    # Unknown type returns hashref
    my $unknown = Claude::Agent::Content->from_json({
        type => 'future_unknown_type',
        data => 'some data',
    });
    is(ref($unknown), 'HASH', 'unknown type returns hashref');
    is($unknown->{type}, 'future_unknown_type', 'unknown type preserved');

    # Empty type
    my $empty = Claude::Agent::Content->from_json({
        type => '',
    });
    is(ref($empty), 'HASH', 'empty type returns hashref');

    # Missing type key entirely
    my $no_type = Claude::Agent::Content->from_json({
        text => 'no type here',
    });
    is(ref($no_type), 'HASH', 'missing type returns hashref');
};

# =============================================================================
# Tests for Message from_json edge cases
# =============================================================================

subtest 'Message from_json edge cases' => sub {
    # Unknown message type returns Base (type is required by Base)
    my $unknown = Claude::Agent::Message->from_json({
        type => 'future_message_type',
        uuid => 'uuid-unknown',
    });
    isa_ok($unknown, 'Claude::Agent::Message::Base', 'unknown type creates Base');
    is($unknown->type, 'future_message_type', 'unknown type preserved');

    # Empty type returns Base
    my $empty = Claude::Agent::Message->from_json({
        type => '',
        uuid => 'uuid-empty',
    });
    isa_ok($empty, 'Claude::Agent::Message::Base', 'empty type creates Base');
};

done_testing();
