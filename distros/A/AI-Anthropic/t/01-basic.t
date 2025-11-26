#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test loading
use_ok('AI::Anthropic');

# Test object creation without API key (should fail gracefully later)
{
    local $ENV{ANTHROPIC_API_KEY};
    eval {
        my $claude = AI::Anthropic->new();
    };
    like($@, qr/API key required/, 'Dies without API key');
}

# Test object creation with API key
{
    my $claude = AI::Anthropic->new(api_key => 'test-key-123');
    isa_ok($claude, 'AI::Anthropic');
}

# Test models list
{
    my $claude = AI::Anthropic->new(api_key => 'test');
    my @models = $claude->models;
    ok(@models > 0, 'models() returns list');
    ok(grep { /claude/ } @models, 'models contain claude');
}

# Test response object
{
    my $response = AI::Anthropic::Response->new(
        text        => 'Hello!',
        model       => 'claude-sonnet-4-20250514',
        stop_reason => 'end_turn',
        usage       => { input_tokens => 10, output_tokens => 5 },
    );
    
    is($response->text, 'Hello!', 'Response text');
    is($response->model, 'claude-sonnet-4-20250514', 'Response model');
    is($response->input_tokens, 10, 'Input tokens');
    is($response->output_tokens, 5, 'Output tokens');
    is($response->total_tokens, 15, 'Total tokens');
    
    # Test stringification
    is("$response", 'Hello!', 'Response stringifies to text');
}

done_testing();
