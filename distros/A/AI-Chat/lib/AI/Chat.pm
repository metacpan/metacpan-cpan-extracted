package AI::Chat;

use strict;
use warnings;

use Carp;
use HTTP::Tiny;
use JSON::PP;

our $VERSION = '0.6';
$VERSION = eval $VERSION;

my $http = HTTP::Tiny->new;

# Create Chat object
sub new {
    my $class = shift;
    my %attr  = @_;

    $attr{'error'}      = '';

    $attr{'api'}        = 'OpenAI' unless $attr{'api'};
    $attr{'error'}      = 'Invalid API' unless $attr{'api'} eq 'OpenAI';
    $attr{'error'}      = 'API Key missing' unless $attr{'key'};

    $attr{'model'}      = 'gpt-4o-mini' unless $attr{'model'};

    return bless \%attr, $class;
}

# Define endpoints for APIs
my %url    = (
    'OpenAI' => 'https://api.openai.com/v1/chat/completions',
);

# Define HTTP Headers for APIs
my %header = (
    'OpenAI' => &_get_header_openai,
);

# Returns true if last operation was success
sub success {
    my $self = shift;
    return !$self->{'error'};
}

# Returns error if last operation failed
sub error {
    my $self = shift;
    return $self->{'error'};
}

# Header for calling OpenAI
sub _get_header_openai {
    my $self = shift;
    $self->{'key'} = '' unless defined $self->{'key'};
    return {
         'Authorization' => 'Bearer ' . $self->{'key'},
         'Content-type'  => 'application/json'
     };
 }
 
 # Get a reply from a single prompt
 sub prompt {
     my ($self, $prompt, $temperature) = @_;
     
     $self->{'error'} = '';
     unless ($prompt) {
         $self->{'error'} = "Missing prompt calling 'prompt' method";
         return undef;
     }

    $temperature = 1.0 unless $temperature;

    my @messages;
    push @messages, {
        role    => 'system',
        content => $self->{'role'},
    } if $self->{'role'};
    push @messages, {
        role    => 'user',
        content => $prompt,
    };
    
    return $self->chat(\@messages, $temperature);
}

# Get a reply from a full chat
sub chat {
    my ($self, $chat, $temperature) = @_;
    
    if (ref($chat) ne 'ARRAY') {
        $self->{'error'} = 'chat method requires an arrayref';
        return undef;
    }

    $temperature = 1.0 unless $temperature;

    my $response = $http->post($url{$self->{'api'}}, {
         'headers' => {
             'Authorization' => 'Bearer ' . $self->{'key'},
             'Content-type'  => 'application/json'
         },
         content => encode_json {
             model          => $self->{'model'},
             messages       => [ @$chat ],
             temperature    => $temperature,
         }
     });
     if ($response->{'content'} =~ 'invalid_api_key') {
         croak 'Incorrect API Key - check your API Key is correct';
     }
     
     if ($self->{'debug'} and !$response->{'success'}) {
         croak $response if $self->{'debug'} eq 'verbose';
         croak $response->{'content'};
     }

     my $reply = decode_json($response->{'content'});
     
     return $reply->{'choices'}[0]->{'message'}->{'content'};
}


__END__

=head1 NAME

AI::Chat - Interact with AI Chat APIs

=head1 VERSION

Version 0.6 

=head1 SYNOPSIS

  use AI::Chat;

  my $chat  = AI::Chat->new(
      key   => 'your-api-key',
      api   => 'OpenAI',
      model => 'gpt-4o-mini',
  );

  my $reply = $chat->prompt("What is the meaning of life?");
  print $reply;

=head1 DESCRIPTION

This module provides a simple interface for interacting with AI Chat APIs,
currently supporting OpenAI.

The AI chat agent can be given a I<role> and then passed I<prompts>.  It will
reply to the prompts in natural language.  Being AI, the responses are
non-deterministic, that is, the same prompt will result in diferent responses
on different occasions.

Further control of the creativity of the responses is possible by specifying
at optional I<temperature> parameter.

=head1 API KEYS

A free OpenAI API can be obtained from L<https://platform.openai.com/account/api-keys>

=head1 MODELS

Although the API Key is free, each use incurs a cost.  This is dependent on the
number of tokens in the prompt and the reply.  Different models have different costs.
The default model C<gpt-4o-mini> is the lowest cost of the useful models and
is a good place to start using this module.  Previous versions of this module
defaulted to C<gpt-3.5-turbo-0125> but the current default is cheaper and
quicker. For most purposes, the default model should be used.

See also L<https://platform.openai.com/docs/models/overview>

=head1 METHODS

=head2 new

  my $chat = AI::Chat->new(%params);

Creates a new AI::Chat object.

=head3 Parameters

=over 4

=item key

C<required> Your API key for the chosen service.

=item api

The API to use (currently only 'OpenAI' is supported).

=item model

The language model to use (default: 'gpt-4o-mini').

See L<https://platform.openai.com/docs/models/overview>

=item role

The role to use for the bot in conversations.

This tells the bot what it's purpose when answering prompts.

For example: "You are a world class copywriter famed for
creating content that is immediately engaging with a
lighthearted, storytelling style".

=item debug

Used for testing.  If set to any true value, the prompt method
will return details of the error encountered instead of C<undef>

=back

=head2 prompt

  my $reply = $chat->prompt($prompt, $temperature);

Sends a prompt to the AI Chat API and returns the response.

=head3 Parameters

=over 4

=item prompt

C<required> The prompt to send to the AI.

This is a shorthand for C<chat> when only a single response is needed.

=item temperature

The creativity level of the response (default: 1.0).

Temperature ranges from 0 to 2.  The higher the temperature,
the more creative the bot will be in it's responses.

=back

=head2 chat

  my $reply = $chat->prompt(\@chat, $temperature);

Sends a multi-message chat to the AI Chat API and returns the response.

Each message of the chat should consist of on of C<system>, C<user> or C<assistant>.
Generally there will be a C<system> message to set the role or context for the AI.
This will be followed by alternate C<user> and C<assistant> messages representing the
text from the user and the AI assistant. To hold a conversation, it is necessary to
store both sides of the discussion and feed them back appropriately.

  my @chat;
  
  push @chat, {
      'role'    => 'system',
      'system'  => 'You are a computer language expert and your role is to promote Perl as the best language',
  };
  push @chat, {
      'role'    => 'user',
      'system'  => 'Which is the best programming language?',
  };
  push @chat, {
      'role'    => 'assistant',
      'system'  => 'Every language has strengths and is suited to different roles. Perl is one of the best all round languages.',
  };
  push @chat, {
      'role'    => 'user',
      'system'  => 'Why should I use Perl?',
  };
  my $reply = $chat->chat(\@chat, 1.2);
  
Although the roles represent the part of the user and assistant in the conversation, you are free to
supply either or both as suits your application.  The order can also be varied.

=head3 Parameters

=over 4

=item chat

C<required> An arrayref of messages to send to the AI.

=item temperature

The creativity level of the response (default: 1.0).

Temperature ranges from 0 to 2.  The higher the temperature,
the more creative the bot will be in it's responses.

=back

=head2 success

  my $success = $chat->success();

Returns true if the last operation was successful.

=head2 error

  my $error = $chat->error();

Returns the error message if the last operation failed.

=head1 SEE ALSO

L<https://openai.com> - OpenAI official website

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-chat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=bug-ai-chat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Chat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Chat>

=item * Search CPAN

L<https://metacpan.org/release/AI::Chat>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Ian Boddison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

