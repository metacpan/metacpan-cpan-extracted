package App::MCP::CLI::Command::interactive;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use App::MCP::CLI -command;

use HTTP::Tiny;
use JSON::MaybeXS;
use App::MCP::CLI::Client qw(content_text);
use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

=encoding utf8

=head1 NAME

App::MCP::CLI::Command::interactive - Agent REPL that routes natural-language queries to MCP tools via a local LLM

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    # Start an interactive session against a named server in your config file
    mcpcli interactive --server myserver

    # Alias: the 'chat' sub-command is identical
    mcpcli chat --server myserver

    # Use a local Perl script as the server with a custom model
    mcpcli interactive --server ./server.pl --model llama3

    # Point at an SSE server by URL
    mcpcli interactive --server http://localhost:8080/sse

    # Override every option explicitly
    mcpcli interactive \
        --server   myserver       \
        --provider ollama         \
        --model    qwen2.5:1.5b   \
        --config   /etc/mcp/config.json

=head1 DESCRIPTION

C<App::MCP::CLI::Command::interactive> implements the C<interactive> (alias
C<chat>) sub-command of the C<mcpcli> application.  It starts a Read-Eval-Print
Loop (REPL) that:

=over 4

=item 1.

Connects to the MCP server specified by C<--server> (either as a stdio
subprocess or via HTTP/SSE).

=item 2.

Retrieves the full tool catalogue from the server with C<tools/list>.

=item 3.

Enters a prompt loop where each user message is forwarded to a local LLM
(currently only B<Ollama> is supported) together with the tool catalogue
and a structured JSON dispatch schema.

=item 4.

If the LLM decides to invoke a tool (C<action: "call_tool">), the command
optionally asks the user for confirmation before executing the C<tools/call>
request and summarising the raw result via a second LLM call.

=item 5.

If no tool is needed (C<action: "reply">), the LLM's plain-text answer is
printed directly.

=back

Type C<exit> or C<quit> (case-insensitive) at the prompt to end the session.

=head1 TRANSPORT MODES

=head2 stdio (default)

The server is launched as a child process via C<IPC::Open2>.  Messages are
exchanged as newline-delimited JSON on its stdin/stdout.  This is the simplest
mode and works with any compliant MCP server script.

=head2 HTTP/SSE

When the resolved server endpoint begins with C<http://> or C<https://>, or
when the config entry contains a C<url> key, the client connects in SSE mode.
It opens the event stream with a C<GET> request, reads the C<endpoint> event
to learn the C<POST> URL, then sends all JSON-RPC messages as C<POST> requests
to that URL. Responses are accepted either in the C<POST> reply body or as
C<message> events on the stream. See L<App::MCP::CLI::Client>.

=head1 CONFIGURATION FILE

The command accepts a JSON configuration file (C<--config>) with the following
optional top-level keys:

=over 4

=item C<mcpServers> (object)

A map of server alias names to server descriptor objects.  Each descriptor may
contain:

=over 4

=item C<command> (string) - executable to launch (stdio mode).

=item C<args> (array of strings) - additional arguments for the executable.

=item C<env> (object) - environment variables for the launched server only.

=item C<url> (string) - SSE endpoint URL (SSE mode).

=item C<transport> (string) - informational (C<"stdio"> or C<"sse">); a server
is SSE when it has a C<url>. C<"sse"> without a C<url> is an error.

=back

=item C<confirmTools> (boolean, default true)

When true, the agent pauses before executing any tool call and asks the user
for explicit confirmation.  Set to C<false> to allow autonomous execution.

=back

The configuration file is searched in the following order when C<--config> is
not given:

=over 4

=item 1. C<./server_config.json> in the current directory.

=item 2. C<./mcp-config.json> in the current directory.

=item 3. C<$HOME/.config/mcp-cli/config.json>.

=back

Example configuration:

    {
      "confirmTools": true,
      "mcpServers": {
        "myserver": {
          "command": "node",
          "args": ["/opt/mcp/server.js"],
          "env": { "DEBUG": "1" }
        },
        "remote": {
          "url": "http://mcp.example.com/sse"
        }
      }
    }

=head1 OPTIONS

=over 4

=item C<--server|-s> I<name_or_path>

The MCP server to connect to (optional when the config file defines exactly
one server).  Can be:

=over 4

=item * A key in the C<mcpServers> section of the config file.

=item * A C<.pl> file path (launched with the current Perl interpreter).

=item * An C<http://> or C<https://> URL (SSE mode).

=item * A bare shell command string (split on whitespace).

=back

=item C<--provider|-p> I<name>  (default: C<ollama>)

The LLM provider to use for query routing and result summarisation.  Only
C<ollama> is currently supported.

=item C<--model|-m> I<name>  (default: C<qwen2.5:1.5b>)

The Ollama model tag to query.  Any model available on the Ollama instance
(L<http://localhost:11434> unless C<OLLAMA_HOST> is set) can be specified.

=item C<--config|-c> I<path>

Path to a JSON configuration file.  See L</CONFIGURATION FILE> above.

=item C<--timeout|-t> I<seconds>

How long to wait for each MCP server reply (default 30; C<0> waits forever).

=back

=head1 INTERNAL METHODS

=cut

sub description { 'Start an interactive agent shell with an MCP server' }
sub abstract    { 'Start an interactive agent shell with an MCP server' }

=head2 command_names

Returns C<qw(interactive chat)> so that the sub-command can be invoked by
either name.

=cut

sub command_names {
    return qw(interactive chat);
}

=head2 opt_spec

Defines the command-line option specification passed to L<Getopt::Long::Descriptive>
via L<App::Cmd>.

=cut

sub opt_spec {
    return (
        [ 'server|s=s',
          'MCP server command, script path, or server name from config'
        ],
        [ 'provider|p=s',
          'LLM provider name (e.g., ollama)',
          { default => 'ollama' }
        ],
        [ 'model|m=s',
          'LLM model to query (e.g., qwen2.5:1.5b)',
          { default => 'qwen2.5:1.5b' }
        ],
        [ 'config|c=s',
          'Path to MCP configuration JSON file'
        ],
        [ 'timeout|t=i',
          'seconds to wait for the MCP server (0 = forever)',
          { default => 30 }
        ],
    );
}

=head2 execute( $opt, $args )

Main entry point.  Resolves the server, connects to it, retrieves tools,
and runs the agent REPL until the user types C<exit>/C<quit> or sends EOF.

The model's decision is validated before anything is executed: it must be a
JSON object, and a requested tool must exist on the server (otherwise the
request is ignored with a message). Tool failures (transport errors, JSON-RPC
errors, or results flagged C<isError>) are reported and the session continues.

=cut

sub execute {
    my ($self, $opt, $args) = @_;

    my $json = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);

    my ($client, $tools);
    my $ok = eval {
        my $config_data = load_config($opt->config);

        $self->{confirm_tools} = 1;
        if ($config_data && exists $config_data->{confirmTools}) {
            $self->{confirm_tools} = $config_data->{confirmTools} ? 1 : 0;
        }

        my ($cmd, $url, $env) =
            resolve_server_cmd($config_data, $opt->server // $args->[0]);

        if (defined $url) {
            print "[-] Connecting to MCP Server via HTTP/SSE: $url\n";
        }
        else {
            print "[-] Launching Local Pipe MCP Server: @$cmd\n";
        }

        $client = App::MCP::CLI::Client->new(
            cmd => $cmd, url => $url, env => $env,
            timeout => $opt->timeout, client_name => 'mcp-interactive-client',
        );
        $client->connect;
        print "[-] SSE Channel Established. Target Post Route: $client->{post_url}\n"
            if $client->is_sse;

        $tools = $client->list_tools;
        1;
    };
    if (!$ok) {
        my $err = $@ || "unknown error\n";
        $err .= "\n" unless $err =~ /\n\z/;
        print STDERR "Error: $err";
        exit 1;
    }

    print "[+] Connected to MCP Server. Found " . scalar(@$tools) . " tool(s).\n";
    print "[-] Connected to LLM provider '" . $opt->provider . "' using model '" . $opt->model . "'.\n";
    print "[-] Starting agent loop. Type 'exit' or 'quit' to end session.\n\n";

    $self->{provider} = $opt->provider;
    $self->{model}    = $opt->model;

    my $warn = sub {
        my ($label, $msg) = @_;
        $msg = "unknown error" unless defined $msg && length $msg;
        $msg =~ s/\s+\z//;
        print "\e[1;31m$label\e[0m $msg\n\n";
    };

    while (1) {
        print "\e[1;36mYou>\e[0m ";

        my $user_query = <STDIN>;
        last if !defined $user_query;
        chomp($user_query);
        last if $user_query =~ /^(exit|quit)$/i;
        next if $user_query eq '';

        print "Thinking...\n";

        my $decision = $self->_ask_llm($user_query, $tools);
        my $action   = ref $decision eq 'HASH' && !ref $decision->{action}
                     ? ($decision->{action} // '') : '';

        if ($action eq 'call_tool') {
            my $tool_name = ref $decision->{tool} ? '' : ($decision->{tool} // '');
            my $tool_args = ref $decision->{arguments} eq 'HASH' ? $decision->{arguments} : {};

            my ($tool) = grep { ($_->{name} // '') eq $tool_name } @$tools;
            if (!$tool) {
                $warn->('Response:', "The model asked for a tool that does not exist ('$tool_name'); ignoring it.");
                next;
            }

            print " -> \e[1;33m[Agent decided to call tool '$tool_name' with args: " .
                  $json->encode($tool_args) .
                  "]\e[0m\n";

            my $proceed = 1;
            if ($self->{confirm_tools}) {
                print " -> \e[1;35m[Security] Allow execution of '$tool_name'? (y/N):\e[0m ";
                my $ans = <STDIN>;
                chomp($ans) if defined $ans;
                if (lc($ans // '') ne 'y') {
                    print "[-] Execution aborted by user request.\n\n";
                    $proceed = 0;
                }
            }

            if ($proceed) {
                my $tool_res = eval { $client->call_tool($tool_name, $tool_args) };
                if (!$tool_res) {
                    $warn->('Error:', $@);
                    next;
                }
                if (my $e = $tool_res->{error}) {
                    $warn->('Error:', $e->{message});
                    next;
                }

                my $result     = $tool_res->{result} || {};
                my $raw_result = content_text($result);
                if ($result->{isError}) {
                    $warn->('Tool error:', $raw_result);
                    next;
                }

                my $final_reply = $self->_summarize_with_llm($user_query, $raw_result);
                print "\e[1;32mResponse:\e[0m $final_reply\n\n";
            }
        }
        elsif ($action eq 'reply') {
            my $answer = $decision->{answer};
            $answer = $json->encode($answer) if ref $answer;
            print "\e[1;32mResponse:\e[0m " . ($answer // '') . "\n\n";
        }
        else {
            print "\e[1;31mResponse:\e[0m Failed to parse structural response from LLM.\n\n";
        }
    }

    $client->close;

    print "[-] Session Closed.\n";
}

=head2 _ollama_url

Returns the Ollama C</api/generate> URL. The base address defaults to
C<http://localhost:11434> and can be changed with the C<OLLAMA_HOST>
environment variable (with or without the C<http://> prefix).

=cut

sub _ollama_url {
    my $base = $ENV{OLLAMA_HOST} || 'http://localhost:11434';
    $base = "http://$base" unless $base =~ m{^https?://}i;
    $base =~ s{/+\z}{};
    return "$base/api/generate";
}

=head2 _ask_llm( $query, $tools )

Sends C<$query> together with the serialised C<$tools> array to the Ollama
C</api/generate> endpoint.  The system prompt instructs the model to respond
with a bare JSON object in one of two forms:

    { "action": "call_tool", "tool": "<name>", "arguments": { ... } }
    { "action": "reply",     "answer": "<text>" }

Returns the decoded hashref. If the model's output is not a JSON object, or
the request fails, a synthetic C<reply> hashref describing the problem (or
containing the raw text) is returned instead.

=cut

sub _ask_llm {
    my ($self, $query, $tools) = @_;

    if (lc($self->{provider}) ne 'ollama') {
        return {
            action => 'reply',
            answer => "Error: Provider '" . $self->{provider} . "' is not supported. Please configure '--provider ollama'."
        };
    }

    my $ua   = HTTP::Tiny->new(timeout => 30);
    my $json = JSON::MaybeXS->new(utf8 => 1);

    my $system_prompt = "You are an AI assistant with access to these local tools:\n"
                      . $json->encode($tools) . "\n"
                      . "If the user request requires a tool, respond ONLY with a JSON object like: {\"action\":\"call_tool\",\"tool\":\"tool_name\",\"arguments\":{...}}\n"
                      . "If no tool is needed, respond with: {\"action\":\"reply\",\"answer\":\"your text answer here\"}\n"
                      . "Respond with valid raw JSON only, no markdown blocks.";

    my $res = $ua->post(
        _ollama_url(),
        {
            headers => { 'content-type' => 'application/json' },
            content => $json->encode({
                model  => $self->{model},
                prompt => "$system_prompt\n\nUser Question: $query",
                stream => JSON::MaybeXS::false()
            })
        }
    );

    if ($res->{success}) {
        # Raw text body resides inside the 'content' key
        my $body = eval { $json->decode($res->{content}) };
        my $raw_response = ref $body eq 'HASH' ? $body->{response} : undef;

        return { action => 'reply', answer => 'The LLM returned an empty or unreadable response.' }
            unless defined $raw_response && !ref $raw_response;

        $raw_response =~ s/\`{3}(?:json)?//g;
        $raw_response =~ s/\`{3}//g;
        $raw_response =~ s/^\s+|\s+$//g;

        my $parsed = eval { $json->decode($raw_response) };
        if ($@ || ref $parsed ne 'HASH') {
            return { action => 'reply', answer => $raw_response };
        }

        return $parsed;
    }

    return {
        action => 'reply',
        answer => "HTTP Error ($res->{status}): $res->{reason}"
    };
}

=head2 _summarize_with_llm( $query, $result )

Sends the original C<$query> and the raw tool C<$result> text to Ollama and
asks for a concise natural-language summary.  Returns the summary string, or
the raw C<$result> on failure.

=cut

sub _summarize_with_llm {
    my ($self, $query, $result) = @_;

    if (lc($self->{provider}) ne 'ollama') {
        return $result;
    }

    my $ua   = HTTP::Tiny->new(timeout => 30);
    my $json = JSON::MaybeXS->new(utf8 => 1);

    my $prompt = "The user asked: '$query'. The tool returned this raw result data:\n$result\n"
               . "Provide a brief, natural language response answering the user's question based on this data.";

    my $res = $ua->post(
        _ollama_url(),
        {
            headers => { 'content-type' => 'application/json' },
            content => $json->encode({
                model  => $self->{model},
                prompt => $prompt,
                stream => JSON::MaybeXS::false()
            })
        }
    );

    if ($res->{success}) {
        my $body = eval { $json->decode($res->{content}) };
        return (ref $body eq 'HASH' && defined $body->{response}) ? $body->{response} : $result;
    }

    return "HTTP Error ($res->{status}): $res->{reason}";
}

=head1 DEPENDENCIES

In addition to the core L<App::MCP::CLI> dependencies, this command requires:

=over 4

=item * L<HTTP::Tiny> - for Ollama API calls and SSE transport.

=back

A running L<Ollama|https://ollama.com> instance on C<http://localhost:11434>
is required for the LLM routing functionality.

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI>

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::call>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-MCP-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-MCP-CLI/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MCP::CLI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/App-MCP-CLI/issues>

=item * Search MetaCPAN

L<http://metacpan.org/dist/App-MCP-CLI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of App::MCP::CLI::Command::interactive
