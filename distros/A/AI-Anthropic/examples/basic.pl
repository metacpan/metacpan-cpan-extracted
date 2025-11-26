#!/usr/bin/perl
# Example: Basic usage of AI::Anthropic
#
# Replace 'your-api-key-here' with your actual Anthropic API key
# Get your key at: https://console.anthropic.com/settings/keys

use strict;
use warnings;
use 5.010;

use FindBin;
use lib "$FindBin::Bin/../lib";

use AI::Anthropic;

# Create client with your API key
my $claude = AI::Anthropic->new(
    api_key => 'sk-ant-api03-your-key-here',  # <-- PUT YOUR KEY HERE
);

say "=" x 50;
say "AI::Anthropic Example";
say "=" x 50;

# Example 1: Simple message
say "\n1. Simple message:";
say "-" x 30;

my $response = $claude->message("What is Perl? Answer in 2 sentences.");
say "Response: $response";
say "Tokens used: " . $response->total_tokens;

# Example 2: Chat with system prompt
say "\n2. Chat with system prompt:";
say "-" x 30;

$response = $claude->chat(
    system   => 'You are a grumpy Perl programmer who loves one-liners.',
    messages => [
        { role => 'user', content => 'How do I reverse a string?' },
    ],
);
say "Response: $response";

# Example 3: Multi-turn conversation
say "\n3. Multi-turn conversation:";
say "-" x 30;

$response = $claude->chat(
    messages => [
        { role => 'user',      content => 'My name is Vugar.' },
        { role => 'assistant', content => 'Nice to meet you, Vugar!' },
        { role => 'user',      content => 'What is my name?' },
    ],
);
say "Response: $response";

# Example 4: Streaming (if you want to see output in real-time)
say "\n4. Streaming:";
say "-" x 30;
say "Streamed response: ";

$claude->chat(
    messages => [
        { role => 'user', content => 'Count from 1 to 5, one number per line.' },
    ],
    stream => sub {
        my ($chunk) = @_;
        print $chunk;
    },
);
say "\n";

say "=" x 50;
say "Done!";
