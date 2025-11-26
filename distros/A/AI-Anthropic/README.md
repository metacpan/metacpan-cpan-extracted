# AI::Anthropic

Perl interface to Anthropic's Claude API.

## Synopsis

```perl
use AI::Anthropic;

my $claude = AI::Anthropic->new(
    api_key => 'sk-ant-api03-your-key-here',
);

# Simple message
print $claude->message("What is the meaning of life?");

# With system prompt
my $response = $claude->chat(
    system   => 'You are a helpful Perl programmer.',
    messages => [
        { role => 'user', content => 'How do I read a file?' },
    ],
);

print "Response: ", $response->text, "\n";
print "Tokens: ", $response->total_tokens, "\n";
```

## Installation

From CPAN:

```bash
cpanm AI::Anthropic
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Features

- **Messages API** - Full support for Claude chat completions
- **Streaming** - Real-time response streaming with callbacks
- **Vision** - Send images (from files, URLs, or base64)
- **Tool Use** - Function calling support
- **All Models** - Claude 4 Opus, Sonnet, Haiku and older models

## Quick Start

```perl
use AI::Anthropic;

my $claude = AI::Anthropic->new(
    api_key => 'sk-ant-api03-your-key-here',
);

print $claude->message("Hello!");
```

## Streaming

```perl
$claude->chat(
    messages => [ { role => 'user', content => 'Tell me a story' } ],
    stream   => sub {
        my ($chunk) = @_;
        print $chunk;
        STDOUT->flush;
    },
);
```

## Vision (Images)

```perl
# From file
my $response = $claude->chat(
    messages => [
        {
            role    => 'user',
            content => [
                { type => 'text', text => 'What is in this image?' },
                { type => 'image', path => '/path/to/image.jpg' },
            ],
        },
    ],
);

# From URL
my $response = $claude->chat(
    messages => [
        {
            role    => 'user',
            content => [
                { type => 'text', text => 'Describe this image' },
                { type => 'image', url => 'https://example.com/image.png' },
            ],
        },
    ],
);
```

## Tool Use (Function Calling)

```perl
my $response = $claude->chat(
    messages => [
        { role => 'user', content => 'What is the weather in Baku?' },
    ],
    tools => [
        {
            name        => 'get_weather',
            description => 'Get current weather for a location',
            input_schema => {
                type       => 'object',
                properties => {
                    location => {
                        type        => 'string',
                        description => 'City name',
                    },
                },
                required => ['location'],
            },
        },
    ],
);
```

## Response Object

```perl
my $response = $claude->message("Hello");

$response->text;          # Response text
$response->model;         # Model used
$response->stop_reason;   # Why generation stopped
$response->input_tokens;  # Tokens in prompt
$response->output_tokens; # Tokens in response
$response->total_tokens;  # Total tokens
$response->raw_response;  # Full API response hashref

# Stringifies to text
print "$response";
```

## Configuration

```perl
my $claude = AI::Anthropic->new(
    api_key     => 'sk-ant-...',           # or use ANTHROPIC_API_KEY env
    model       => 'claude-opus-4-20250514', # default: claude-sonnet-4-20250514
    max_tokens  => 8192,                   # default: 4096
    timeout     => 300,                    # default: 120 seconds
);
```

## Available Models

```perl
my @models = $claude->models;
# claude-opus-4-20250514
# claude-sonnet-4-20250514
# claude-sonnet-4-5-20250929
# claude-haiku-4-5-20251001
# claude-3-5-sonnet-20241022
# ... and more
```

## Environment Variables

- `ANTHROPIC_API_KEY` - Your Anthropic API key

## Dependencies

- Perl 5.10+
- HTTP::Tiny
- JSON::PP
- MIME::Base64

All dependencies are core modules or widely available on CPAN.

## Why This Module?

- **Pure Perl** - No XS, works everywhere
- **Minimal dependencies** - Uses core modules where possible
- **Perlish API** - Feels natural to Perl programmers
- **Full featured** - Streaming, vision, tools - all supported
- **Well documented** - POD and examples included

## See Also

- [Anthropic API Documentation](https://docs.anthropic.com/)
- [OpenAI::API](https://metacpan.org/pod/OpenAI::API) - Similar module for OpenAI

## Contributing

Pull requests welcome! Please include tests for new features.

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

## Author

Your Name <your@email.com>
