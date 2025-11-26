package AI::Anthropic;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';

use Carp qw(croak);
use JSON::PP;
use HTTP::Tiny;
use MIME::Base64 qw(encode_base64);

# Constants
use constant {
    API_BASE     => 'https://api.anthropic.com',
    API_VERSION  => '2023-06-01',
    DEFAULT_MODEL => 'claude-sonnet-4-20250514',
};

=head1 NAME

AI::Anthropic - Perl interface to Anthropic's Claude API

=head1 SYNOPSIS

    use AI::Anthropic;

    my $claude = AI::Anthropic->new(
        api_key => 'sk-ant-api03-your-key-here',
    );

    # Simple message
    my $response = $claude->message("What is the capital of France?");
    print $response;  # prints response text

    # Chat with history
    my $response = $claude->chat(
        messages => [
            { role => 'user', content => 'Hello!' },
            { role => 'assistant', content => 'Hello! How can I help you today?' },
            { role => 'user', content => 'What is 2+2?' },
        ],
    );

    # With system prompt
    my $response = $claude->chat(
        system   => 'You are a helpful Perl programmer.',
        messages => [
            { role => 'user', content => 'How do I read a file?' },
        ],
    );

    # Streaming
    $claude->chat(
        messages => [ { role => 'user', content => 'Tell me a story' } ],
        stream   => sub {
            my ($chunk) = @_;
            print $chunk;
        },
    );

=head1 DESCRIPTION

AI::Anthropic provides a Perl interface to Anthropic's Claude API.
It supports all Claude models including Claude 4 Opus, Claude 4 Sonnet,
and Claude Haiku.

=head1 METHODS


=head1 AUTHOR

Vugar Bakhshaliyev <d7951500@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head2 new

    my $claude = AI::Anthropic->new(
        api_key     => 'your-api-key',      # required (or use ANTHROPIC_API_KEY env)
        model       => 'claude-sonnet-4-20250514',  # optional
        max_tokens  => 4096,                 # optional
        timeout     => 120,                  # optional, seconds
    );

=cut

sub new {
    my ($class, %args) = @_;
    
    my $api_key = $args{api_key} // $ENV{ANTHROPIC_API_KEY}
        or croak "API key required. Set api_key parameter or ANTHROPIC_API_KEY environment variable";
    
    my $self = {
        api_key     => $api_key,
        model       => $args{model}      // DEFAULT_MODEL,
        max_tokens  => $args{max_tokens} // 4096,
        timeout     => $args{timeout}    // 120,
        api_base    => $args{api_base}   // API_BASE,
        _http       => HTTP::Tiny->new(
            timeout => $args{timeout} // 120,
        ),
        _json       => JSON::PP->new->utf8->allow_nonref,
    };
    
    return bless $self, $class;
}

=head2 message

Simple interface for single message:

    my $response = $claude->message("Your question here");
    my $response = $claude->message("Your question", system => "You are helpful");
    
    print $response->text;

=cut

sub message {
    my ($self, $content, %opts) = @_;
    
    croak "Message content required" unless defined $content;
    
    return $self->chat(
        messages => [ { role => 'user', content => $content } ],
        %opts,
    );
}

=head2 chat

Full chat interface:

    my $response = $claude->chat(
        messages    => \@messages,       # required
        system      => $system_prompt,   # optional
        model       => $model,           # optional, overrides default
        max_tokens  => $max_tokens,      # optional
        temperature => 0.7,              # optional, 0.0-1.0
        stream      => \&callback,       # optional, for streaming
        tools       => \@tools,          # optional, for function calling
    );

=cut

sub chat {
    my ($self, %args) = @_;
    
    my $messages = $args{messages}
        or croak "messages parameter required";
    
    # Build request body
    my $body = {
        model      => $args{model}      // $self->{model},
        max_tokens => $args{max_tokens} // $self->{max_tokens},
        messages   => $self->_normalize_messages($messages),
    };
    
    # Optional parameters
    $body->{system}      = $args{system}      if defined $args{system};
    $body->{temperature} = $args{temperature} if defined $args{temperature};
    $body->{tools}       = $args{tools}       if defined $args{tools};
    $body->{tool_choice} = $args{tool_choice} if defined $args{tool_choice};
    
    # Streaming or regular request
    if (my $stream_cb = $args{stream}) {
        return $self->_stream_request($body, $stream_cb);
    } else {
        return $self->_request($body);
    }
}

=head2 models

Returns list of available models:

    my @models = $claude->models;

=cut

sub models {
    return (
        'claude-opus-4-20250514',
        'claude-sonnet-4-20250514',
        'claude-sonnet-4-5-20250929',
        'claude-haiku-4-5-20251001',
        'claude-3-5-sonnet-20241022',
        'claude-3-5-haiku-20241022',
        'claude-3-opus-20240229',
        'claude-3-sonnet-20240229',
        'claude-3-haiku-20240307',
    );
}

# ============================================
# Private methods
# ============================================

sub _normalize_messages {
    my ($self, $messages) = @_;
    
    my @normalized;
    for my $msg (@$messages) {
        my $content = $msg->{content};
        
        # Handle image content
        if (ref $content eq 'ARRAY') {
            my @parts;
            for my $part (@$content) {
                if ($part->{type} eq 'image' && $part->{path}) {
                    # Load image from file
                    push @parts, $self->_image_from_file($part->{path});
                } elsif ($part->{type} eq 'image' && $part->{url}) {
                    # Load image from URL
                    push @parts, $self->_image_from_url($part->{url});
                } elsif ($part->{type} eq 'image' && $part->{base64}) {
                    push @parts, {
                        type   => 'image',
                        source => {
                            type         => 'base64',
                            media_type   => $part->{media_type} // 'image/png',
                            data         => $part->{base64},
                        },
                    };
                } else {
                    push @parts, $part;
                }
            }
            push @normalized, { role => $msg->{role}, content => \@parts };
        } else {
            push @normalized, $msg;
        }
    }
    
    return \@normalized;
}

sub _image_from_file {
    my ($self, $path) = @_;
    
    open my $fh, '<:raw', $path
        or croak "Cannot open image file '$path': $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    
    # Detect media type
    my $media_type = 'image/png';
    if ($path =~ /\.jpe?g$/i) {
        $media_type = 'image/jpeg';
    } elsif ($path =~ /\.gif$/i) {
        $media_type = 'image/gif';
    } elsif ($path =~ /\.webp$/i) {
        $media_type = 'image/webp';
    }
    
    return {
        type   => 'image',
        source => {
            type       => 'base64',
            media_type => $media_type,
            data       => encode_base64($data, ''),
        },
    };
}

sub _image_from_url {
    my ($self, $url) = @_;
    
    return {
        type   => 'image',
        source => {
            type => 'url',
            url  => $url,
        },
    };
}

sub _request {
    my ($self, $body) = @_;
    
    my $response = $self->{_http}->post(
        $self->{api_base} . '/v1/messages',
        {
            headers => $self->_headers,
            content => $self->{_json}->encode($body),
        }
    );
    
    return $self->_handle_response($response);
}

sub _stream_request {
    my ($self, $body, $callback) = @_;
    
    $body->{stream} = \1;  # JSON true
    
    my $full_text = '';
    my $response_data;
    
    # HTTP::Tiny doesn't support streaming well, so we use a data callback
    my $response = $self->{_http}->post(
        $self->{api_base} . '/v1/messages',
        {
            headers      => $self->_headers,
            content      => $self->{_json}->encode($body),
            data_callback => sub {
                my ($chunk, $res) = @_;
                
                # Parse SSE events
                for my $line (split /\n/, $chunk) {
                    next unless $line =~ /^data: (.+)/;
                    my $data = $1;
                    next if $data eq '[DONE]';
                    
                    eval {
                        my $event = $self->{_json}->decode($data);
                        
                        if ($event->{type} eq 'content_block_delta') {
                            my $text = $event->{delta}{text} // '';
                            $full_text .= $text;
                            $callback->($text) if $callback;
                        } elsif ($event->{type} eq 'message_stop') {
                            $response_data = $event;
                        }
                    };
                }
            },
        }
    );
    
    unless ($response->{success}) {
        return $self->_handle_response($response);
    }
    
    # Return a response object with the full text
    return AI::Anthropic::Response->new(
        text         => $full_text,
        raw_response => $response_data,
    );
}

sub _headers {
    my ($self) = @_;
    
    return {
        'Content-Type'      => 'application/json',
        'x-api-key'         => $self->{api_key},
        'anthropic-version' => API_VERSION,
    };
}

sub _handle_response {
    my ($self, $response) = @_;
    
    my $data;
    eval {
        $data = $self->{_json}->decode($response->{content});
    };
    
    unless ($response->{success}) {
        my $error_msg = $data->{error}{message} // $response->{content} // 'Unknown error';
        croak "Anthropic API error: $error_msg (status: $response->{status})";
    }
    
    return AI::Anthropic::Response->new(
        text          => $data->{content}[0]{text} // '',
        role          => $data->{role},
        model         => $data->{model},
        stop_reason   => $data->{stop_reason},
        usage         => $data->{usage},
        raw_response  => $data,
    );
}

# ============================================
# Response class
# ============================================

package AI::Anthropic::Response;

use strict;
use warnings;
use overload '""' => \&text, fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub text         { shift->{text}         }
sub role         { shift->{role}         }
sub model        { shift->{model}        }
sub stop_reason  { shift->{stop_reason}  }
sub usage        { shift->{usage}        }
sub raw_response { shift->{raw_response} }

sub input_tokens  { shift->{usage}{input_tokens}  // 0 }
sub output_tokens { shift->{usage}{output_tokens} // 0 }
sub total_tokens  { 
    my $self = shift;
    return $self->input_tokens + $self->output_tokens;
}

1;

__END__

=head1 EXAMPLES

=head2 Basic usage

    use AI::Anthropic;
    
    my $claude = AI::Anthropic->new;
    print $claude->message("Hello, Claude!");

=head2 With image (vision)

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

=head2 Tool use (function calling)

    my $response = $claude->chat(
        messages => [
            { role => 'user', content => 'What is the weather in London?' },
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

=head2 Streaming

    $claude->chat(
        messages => [ { role => 'user', content => 'Tell me a story' } ],
        stream   => sub {
            my ($chunk) = @_;
            print $chunk;
            STDOUT->flush;
        },
    );

=head1 ENVIRONMENT

=over 4

=item ANTHROPIC_API_KEY

Your Anthropic API key. Can be set instead of passing api_key to new().

=back

=head1 SEE ALSO

L<https://docs.anthropic.com/> - Anthropic API documentation

L<OpenAI::API> - Similar module for OpenAI

=head1 AUTHOR

Your Name <your@email.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
