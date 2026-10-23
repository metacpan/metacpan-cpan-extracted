=head1 NAME

AnyEvent::MCP::Server::Simple - simple function interface for MCP servers

=head1 SYNOPSIS

   use AnyEvent::MCP::Server::Simple;

   mcp_config
      server_name    => "example",
      server_version => 0,
      instructions => <<'EOF';
         Use echo to return the supplied text.
   EOF

   mcp_tool echo =>
      "Return the supplied text.",
      {
         type       => "object",
         properties => { text => { type => "string" } },
         required   => ["text"],
      },
      sub {
         my ($req, $args) = @_;

         $req->reply ({
            content => [{ type => "text", text => $args->{text} }],
         });
      };

   mcp_start;

=head1 DESCRIPTION

For most MCP servers, registering a few tools and starting a transport is
enough. This module does just that: call C<mcp_tool> to register callbacks,
optionally configure the server with C<mcp_config>, then start it with
C<mcp_start>, C<mcp_stdio> or C<mcp_http>. Registration alone does not start
a server or an event loop.

Human-readable descriptions and instructions are stripped of surrounding
whitespace and common indentation when registered, so indented here-documents
can be used naturally.

C<mcp_start>, C<mcp_stdio> and C<mcp_http> are alternative blocking entry
points for a self-contained server. They run AnyEvent until shutdown; you
do not start another event loop. If your application already owns the server
lifetime or needs several transports, use the object interfaces instead.

Simple uses L<AnyEvent::MCP::Server> and a default Toolset internally; it is
not a second server implementation. Applications needing custom dispatch,
such as a multibroker, can use the Server API directly.

Start with L</TUTORIAL> for a complete server and a first client call.
For running the bundled servers without writing Perl, see
L<AnyEvent::MCP::Intro>.

=head1 TUTORIAL

This tutorial builds a small server, calls it, then adds options, permission
checks and asynchronous work. You do not need to implement JSON-RPC,
authentication or a transport. Simple supplies those parts; your program
declares tools and handles their arguments.

For installation, connecting AI clients and configuring the bundled servers,
see L<AnyEvent::MCP::Intro>. The function reference follows this tutorial.

=head2 A complete first server

Save the following as C<echo-mcp>:

   #!/opt/bin/perl

   use common::sense;
   use AnyEvent::MCP::Server::Simple;

   my $options = mcp_getoptions {
      name        => "echo-demo",
      usage       => "Usage: $0 [OPTION]...\n",
      description => "Return text supplied to the echo tool.",
   };

   @ARGV == 0
      or die "Unexpected arguments\n";

   mcp_config
      server_name    => "echo-demo",
      server_version => 1,
      instructions => "Use echo to return the supplied text.";

   mcp_tool echo =>
      "Return the supplied text.",
      {
         type       => "object",
         properties => {
            text => {
               type      => "string",
               maxLength => 4096,
            },
         },
         required => ["text"],
      },
      sub {
         my ($req, $args) = @_;

         my $text = $args->{text};
         defined $text and !ref $text and length $text <= 4096
            or die "text must be a string of at most 4096 characters\n";

         $req->reply ({
            content => [{ type => "text", text => $text }],
         });
      };

   mcp_start %$options;

Use your installed Perl's explicit path in the shebang, or invoke the file
with C<perl> as in the commands below.

C<mcp_getoptions> parses the common server options and returns startup
settings. C<mcp_config> declares protocol metadata and instructions.
C<mcp_tool> registers a description, input schema and callback.
C<mcp_start> constructs the transport and runs AnyEvent until shutdown.
Register everything before starting: code after C<mcp_start> runs only
when the server stops.

The input schema tells the client what to supply. The server does B<not>
validate arguments against JSON Schema, so the callback checks the value it
actually uses. A missing text, array or object fails as a tool error.
The example allows an empty string.

C<$req> is an L<AnyEvent::MCP::Server::Request>; C<$args> is its argument
hash reference. Replying finishes the request. Merely returning from the
callback does not. You supply the MCP result, and the server supplies the
JSON-RPC envelope.

=head2 Start and call the server

Inspect the common options with:

   perl echo-mcp --help

For a client launching a local subprocess, configure:

   perl /absolute/path/to/echo-mcp --stdio

The client must launch the process itself. Stdin and stdout carry MCP,
so starting the program in a terminal and typing text at it is not a test
of the echo tool. Print diagnostics to stderr, not stdout.

You can make a first call without an AI client. Save this as C<try-echo>
in the same directory as C<echo-mcp>:

   use common::sense;
   use AnyEvent;
   use AnyEvent::MCP::Client::JSONL;

   my $client = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "./echo-mcp", "--stdio"],
   );

   my $cv = AE::cv;

   $client->call (echo => { text => "hello" }, sub {
      $cv->send (@_);
   });

   my ($success, $result) = $cv->recv;
   $success
      or die "$result->{message}\n";
   !$result->{isError}
      or die "$result->{content}[0]{text}\n";

   print $result->{content}[0]{text}, "\n";

Run C<perl try-echo>. It prints:

   hello

The JSONL client starts the server, connects and negotiates the protocol on
first use. C<$^X> chooses the same Perl interpreter as the test client.
The condition variable keeps the event loop running until the reply arrives.
Keep C<$client> alive while its operations are outstanding.

There are two success checks. C<$success> means the JSON-RPC operation
completed successfully; a tool can still return C<isError> in that result.
This client expects our echo tool's text result. A general client must handle
other MCP content representations too.

To use HTTP, start the server in one terminal:

   perl echo-mcp --bind :31742

and retrieve its URL in another:

   perl echo-mcp --bind :31742 --print-url

Configure that URL in your MCP client and ask it to call echo with text
C<hello>. Both commands use instance C<echo-demo>, unless you override it
with C<--name>. Repeat the same listener overrides when printing the URL.
C<--print-url> prints the address and exits; it does not start a server.

For the small Perl client above, replace the JSONL import and constructor
with:

   use AnyEvent::MCP::Client::HTTP;

   my $client = AnyEvent::MCP::Client::HTTP->new (
      url => $ARGV[0],
   );

Pass the printed URL as its first command-line argument.
The rest of the call and result handling stays the same.

C<mcp_start> supplies named HTTP settings and a token derived from the
private global secret. Stdio needs no HTTP configuration. C<name> selects
local settings and credentials; C<server_name> identifies the advertised
MCP implementation. The two need not be the same.
See L<AnyEvent::MCP::Intro/CONFIGURING YOUR SETUP>.

=head2 Add an application option

Suppose you want the server user to choose the maximum text length.
Replace the original C<mcp_getoptions> call with:

   my $max_length = 4096;

   my $options = mcp_getoptions (
      {
         name        => "echo-demo",
         usage       => "Usage: $0 [OPTION]...\n",
         description => "Return text supplied to the echo tool.",
         options     => [
            ["--max-length N", "Maximum text length in characters"],
         ],
      },
      "max-length=i" => \$max_length,
   );

   $max_length > 0
      or die "--max-length must be positive\n";

Use C<$max_length> in both the schema's C<maxLength> and the callback's
length check. The server user can then start:

   perl echo-mcp --stdio --max-length 1000

The option specification is passed to L<Getopt::Long>. The C<options>
entries supply human-readable help; they do not register options.
The later tool examples use the original 4096-character limit; use your
chosen limit in them too if you keep this option.
Common options such as C<--stdio>, C<--bind> and C<--help> remain available.

If your server also takes positional arguments, validate the remaining
C<@ARGV> after C<mcp_getoptions>. It handles C<--help> and C<--print-url>
before that validation, so the user can retrieve an HTTP URL without
supplying an application workdir or starting the application.

Settings affecting URL discovery, such as C<name> and C<path>, should be
available to C<mcp_getoptions> through its leading settings hash or an
earlier C<mcp_config> call. A setting supplied only after the parser exits
for C<--print-url> cannot affect that printed URL.

=head2 Choose a result representation

Our echo callback returns one text content item. Use C<reply> when the
representation matters: text, other content types, a larger result or a
particular MCP result shape.

For an ordinary result object, you can replace the reply with:

   $req->result ({ text => $text, length => length $text });

C<result> returns that hash as C<structuredContent> and also serializes it
as JSON in one text content item. Clients consuming only text can still
see the data, but it is deliberately duplicated. Wrap arrays or scalars in
an object, or use C<reply> to choose a different representation.

To report a tool failure explicitly:

   $req->error ("The requested operation cannot be completed");

A synchronous exception from the handler also becomes a tool-error result.
Malformed protocol requests and an unknown tool name are handled by the
server. Your callback does not construct a JSON-RPC response itself.

Reply once. Code that calls C<reply>, C<result> or C<error> and then calls
another reply method is a programming error. Keep a final reply separate
from the work leading to it so the completion point is easy to see.

=head2 Add a permission check before changing state

Authentication alone does not decide which tool operations a user allows.
For an example with a side effect but no external worker, add a tool that
stores one note in the server's memory.

Add this before registering the tools:

   use AnyEvent::MCP::Server::Permissions;

   my $note;

   mcp_config permissions => AnyEvent::MCP::Server::Permissions->new (
      name    => "echo-notes",
      actions => {
         remember => "Replace the server's in-memory note",
      },
   );

Then register this tool before C<mcp_start>:

   mcp_tool remember =>
      "Replace the server's in-memory note with the supplied text.",
      {
         type       => "object",
         properties => {
            text => { type => "string", maxLength => 4096 },
         },
         required => ["text"],
      },
      sub {
         my ($req, $args) = @_;

         my $text = $args->{text};
         defined $text and !ref $text and length $text <= 4096
            or die "text must be a string of at most 4096 characters\n";

         $req->require_permission ({
            tool           => $req->{tool},
            action         => "remember",
            sandbox_grants => [],
            reason         => "replace the server's in-memory note",
         });

         $note = $text;

         $req->result ({ remembered => length $note });
      };

Restart the server and call remember through your client. The default
permission helper asks on the server machine. Allow once permits this
invocation. Allow always saves a rule for action C<remember>; subsequent
matching calls do not ask again. The note itself lasts only for this
server process and is shared by its clients.

The permission engine's name C<echo-notes> selects its default policy file:

   ~/.config/anyevent-mcp/rules/echo-notes.ini

The actual directory follows C<XDG_CONFIG_HOME> when set.
This is the shared engine's default convention, different from mcp-fs's
C<rules/fs-NAME.ini>. Manage it using C<anyevent-mcp manage-rules-file>
with the actual pathname, or supply C<file> to the engine explicitly.

For example, a manually written allow rule is:

   [rule]
   decision=allow
   action=remember
   sandbox-grants=

The empty grant list is intentional. This tool updates an in-memory value;
it does not launch a sandboxed worker. C<action> is the operation class
to authorize, while C<sandbox_grants> describes worker authority.

The permission engine checks policy; it does not restrict filesystem or
network access by itself. If you add file or command tools, define the
necessary grants and enforce the returned set through your worker or
sandbox. Do not copy C<sandbox_grants =E<gt> []> into a file-writing
handler and assume it confines access.

Here the permission name is deliberately fixed and independent of the
HTTP instance name. If you want each C<--name> to have separate policy,
pass C<$options{name}> as the permission engine's name instead.

=head2 Why checks must precede side effects

When permission is missing, C<require_permission> throws a special
exception. Server catches it, asks, and may invoke the handler again.
The assignment to C<$note> therefore comes B<after> the check.

With a local prompt, the server retries internally. Modern MCP form asking
returns C<input_required>; the client repeats the call with its answer.
Earlier one-time grants survive permission retries within this invocation,
but do not authorize the next call. Saved rules are rechecked.

Do not catch that exception as an ordinary failure around the permission
check. It must reach Server's synchronous dispatch boundary.
For several checks, complete all of them before modifying state or starting
asynchronous work. An C<on_request> hook also runs on retry, so it must not
perform a once-only side effect before the handler's checks.

To choose client-side form asking for this example:

   PERL_ANYEVENT_MCP_PERMISSION_ASK=auto perl echo-mcp --stdio

C<auto> uses modern form elicitation when the client advertises support,
otherwise the local helper. C<mcp> requires that support; C<helper> keeps
the prompt local. The tiny try-echo client advertises no form support,
so auto uses the helper there. To handle forms in a Perl client, see
L<AnyEvent::MCP::Client/on_request> and
L<AnyEvent::MCP::Permissions::Ask/elicitation>.

For grant definitions, subject scopes and multi-path operations, see
L<AnyEvent::MCP::Server::Permissions> and
L<AnyEvent::MCP::Server::Toolset/Permission checks and retries>.

=head2 Let an asynchronous operation finish later

A tool callback runs in the AnyEvent event loop. Blocking it with C<sleep>
or a synchronous long-running command also blocks other requests.

Add C<use AnyEvent;> and register the following before C<mcp_start>:

   mcp_tool delayed_echo =>
      "Return the supplied text after a delay of up to 60 seconds.",
      {
         type       => "object",
         properties => {
            text => { type => "string", maxLength => 4096 },
            seconds => {
               type    => "integer",
               minimum => 0,
               maximum => 60,
            },
         },
         required => ["text", "seconds"],
      },
      sub {
         my ($req, $args) = @_;

         my $text = $args->{text};
         defined $text and !ref $text and length $text <= 4096
            or die "text must be a string of at most 4096 characters\n";

         my $seconds = $args->{seconds};
         defined $seconds and !ref $seconds
            and $seconds =~ /\A[0-9]+\z/ and $seconds <= 60
            or die "seconds must be an integer from 0 to 60\n";

         $req->progress (0, 1, "Waiting");

         my $timer = AnyEvent->timer (after => $seconds, cb => sub {
            $req->{finished}
               and return;

            $req->progress (1, 1, "Done");
            $req->reply ({
               content => [{ type => "text", text => $text }],
            });
         });

         $req->{on_cancel} = sub {
            undef $timer;
         };
      };

The tool is advertised as C<delayed-echo>, because registration converts
underscores to hyphens. Ask the client to call it with text C<hello> and
seconds C<2>. The callback returns immediately; the timer supplies the reply
later. Other requests can run while it waits.

Keep watcher objects alive while they are needed. Here the cancellation
callback retains C<$timer>, and the timer's callback retains C<$req> and
C<$text>. Cancellation releases the timer. Replying finishes the request
and removes its cancellation callback, releasing the watcher as well.
No separate job registry is needed for this example.

Check C<finished> in late completion callbacks before replying.
Cancellation sets both C<finished> and C<cancelled> and sends no reply.
For subprocesses or network work, the cancellation callback should stop
that operation and release its resources instead of merely abandoning
the eventual reply.

Server catches exceptions during synchronous dispatch, not exceptions
from a later timer or I/O callback. If an asynchronous operation can fail,
handle that failure in its completion callback and report it with
C<error> or C<reply>, provided the request is still active.

C<progress> only sends when the caller supplied a progress token.
Delivery is best effort; the HTTP server in this distribution does not
deliver progress notifications. A client without progress display can
still receive the final result.

=head2 When to use the object interfaces

Simple owns one default Toolset and the blocking server lifetime.
That is useful for a small standalone program. If you already run an
event loop, want multiple transports or tool registries, or need custom
protocol dispatch, construct the objects directly.

L<AnyEvent::MCP::Server::Toolset> registers reusable tools.
L<AnyEvent::MCP::Server> handles the protocol.
L<AnyEvent::MCP::Server::HTTP> and L<AnyEvent::MCP::Server::JSONL> manage
connections. L<AnyEvent::MCP::Server::Request> describes request fields,
replies, progress and cancellation. The same tool callback model applies
at both levels.

=head1 FUNCTIONS

=over

=item mcp_config %config

Adds server configuration. Repeated calls extend or replace previously declared
values. C<instructions> is treated as human-readable text and normalized.

Server and transport options are passed to the underlying objects.
Common options include:

=over

=item name => $instance

Local instance name used to select configuration and credentials. Independent
of the name reported to MCP clients.

=item server_name => $name

Advertised MCP server implementation name. Defaults to C<AnyEvent::MCP>.

=item server_version => $version

Advertised application version, not the MCP protocol revision. Accepts
an ordinary Perl version number; Simple stringifies it for MCP.
Defaults to the AnyEvent::MCP library version.

=item server_info => { name => $name, version => $version }

Raw MCP server identity, passed through unchanged to the underlying
server. Cannot be combined with C<server_name> or C<server_version>.

=item instructions => $text

Human-readable guidance for the client, normalized when configured.

=item short_instructions => $text

Optional condensed guidance for finding this server's tools. Used as the
advertised MCP instructions when C<auto_instructions> is enabled.

=item auto_instructions => $boolean

Enabled by default. Exposes full instructions through the generated
C<meta-instructions> tool while advertising the short instructions if set.
When short or custom instructions are provided, append a brief hint pointing
to the full tool description; otherwise advertise full instructions as before.
Disable to advertise full instructions and omit the generated tool.

=item custom_instructions => $text

Instance-specific purpose prepended to advertised instructions. Can also be
set through C<--custom-instructions> or C<custom_instructions> in the program
or instance section of the global INI configuration.

=item on_request => $callback->($server, $req)

Synchronous hook before each dispatch attempt. For example, refresh
database state here. This does not replace dispatch or receive a
completion callback, and permission retries can invoke it again.

=item on_start => $callback->($server)

Called after the transport is ready, before entering the event loop.
Use it for startup information or installing watchers. Stdout carries
protocol messages in stdio mode; print diagnostics to stderr.
The callback must not block.

=item idle_exit => $seconds

Optional positive idle time for spawned stdio servers. With a multibroker
advertising C<anyevent-mcp/multibroker> version 1, Simple requests shutdown
once no MCP requests have been active for that long. The broker can ignore
the request. HTTP servers, ordinary clients and servers without this
option are unaffected.

=back

See L<AnyEvent::MCP::Server> for further protocol options and events.

=item mcp_tool $name, $description, $input_schema, $callback->($req, $args)

Registers a tool named C<$name> with C<$description> and the JSON Schema
hash reference C<$input_schema>. C<$description> is normalized like
C<instructions>.

C<$callback> receives an L<AnyEvent::MCP::Server::Request> object C<$req>
and its C<< $req->{args} >> hash reference as C<$args>, for convenience.

Tools complete the request with C<< $req->reply ($result) >>, or use
C<< $req->result ($data) >> and C<< $req->error ($message) >> for convenience.
Request context is available directly in
the hash, for example C<< $req->{tool} >> and C<< $req->{server} >>.

=item $server_options = mcp_getoptions ({ %settings }, @getopt_options)

Parse standard server options C<--name>, C<--bind>, repeatable
C<--token>, C<--stdio>, C<--custom-instructions>, repeatable
C<--auto-allow> and C<--auto-deny>, C<--quiet>, C<--print-url>, C<--tool-help> and C<--help> alongside any
application-specific L<Getopt::Long> option specifications:

   my $verbose;
   my $options = mcp_getoptions (
      {
         usage => "Usage: $0 [OPTION]... WORKDIR\n",
         description => "Provide example tools through MCP.",
         option_heading => "Example options:",
         options => [
            ["--verbose", "Show additional diagnostics"],
         ],
         examples => "  $0 --stdio ./project",
         path => "/",
      },
      "verbose!" => \$verbose,
   );
   @ARGV == 1 or die "workdir required\n";
   mcp_start %$options;

The optional leading hash accepts these help settings:

=over

=item usage => $text

Usage synopsis, including its trailing newline. A default synopsis is
generated when omitted.

=item description => $text

Introductory help paragraph.

=item options => [[$label, $description]...]

Application option labels and descriptions. A plain string among the
pairs starts a new section; a string at the beginning replaces the
default section heading.

=item option_heading => $text

Initial section heading, defaulting to C<Application options:>.

=item examples => $text

Preformatted examples.

=back

This section is the canonical reference for common server options.
Executable manpages document only their additional or differing behavior.

The common MCP options are documented automatically and their descriptions
are shared by all callers. Application option descriptions are explicit;
a C<Getopt::Long> specification does not contain enough information to
write one.

Other settings in that hash, such as C<path>, C<auth> or C<url_scheme>,
are passed through to C<mcp_start>. Without C<usage>, a default synopsis
is generated. Standard C<--help> prints the expanded help and exits;
a parsing error dies with the shorter usage synopsis.
Standalone servers using this parser emit tool calls and tool-error replies
to the configured L<AnyEvent::Log> output by default, including asynchronous
failures. C<--quiet> suppresses this operational log, not warnings and other
ordinary diagnostics. The process-wide default formatter uses a short
day/time timestamp, program, instance and PID; custom formatting callbacks
and output destinations configured through C<PERL_ANYEVENT_LOG> are retained.
Verbose protocol diagnostics retain their normal AnyEvent log levels.
C<--tool-help> prints the registered tools with their argument types,
required fields, defaults and descriptions, then exits before listening.
Call it only after registering tools; it reflects the actual registry,
including conditional registration. See C<mcp_tool_help> for custom servers.
C<--print-url> resolves the same name, bind, tokens and path as
startup, prints the first accepted token in the URL and exits B<without>
starting a listener. It requires a persistently stored master secret for
derived credentials and cannot predict a port requested as zero.

All other option specifications and remaining C<@ARGV> follow the caller's
normal Getopt::Long configuration, including C<require_order> if selected.
C<--stdio> is understood by C<mcp_start> and skips HTTP configuration.
C<--auto-allow TOOL[,ACTION[,CAPABILITY]]> and C<--auto-deny> with the same
argument each add one process-local rule, in command-line order. Omitted
fields and C<*> match any value. Named capabilities limit allowed authority
or trigger a denial; see L<AnyEvent::MCP::Server::Permissions/auto_rules>.
These rules are checked before saved rules. The startup functions apply them to the configured
L<AnyEvent::MCP::Server::Permissions> object, creating an in-memory one if
necessary. Only tools that request permission are affected; tools without
permission checks are not blocked. In a multibroker they apply to
broker-visible tool names, not to independent permission checks performed
by downstream servers.
C<--connect URL> connects to a multibroker at
C<http://host:port/token/alias> instead of serving stdio or starting an HTTP
listener by default. It overrides implicit stdio from the environment;
explicit C<--stdio> and C<--connect> cannot be combined.
The helper deliberately does not enforce application-specific positional
arguments; C<--print-url> should not have to supply a workdir just to
print an address. It is a parser, not a second command language.

=item mcp_tool_help ($enabled, @toolsets)

If C<$enabled> is true, print the definitions registered in the supplied
L<AnyEvent::MCP::Server::Toolset> objects and exit. Otherwise do nothing.
Call after registering tools but before starting listeners for executables
which manage their own toolsets. Only registered tools appear.

=item mcp_log $message

Emit operator-facing activity to the configured AnyEvent::Log destination,
bypassing its diagnostic verbosity filter. C<--quiet> suppresses this log.

=item mcp_log_request ($server, $req)

C<on_request> callback to report tool invocations once across permission
retries, and log tool-error replies, including asynchronous ones. It logs
selected arguments rather than entire request or reply payloads. This includes
a JSON-quoted preview of Vim C<ex> commands (up to 200 characters), which
can contain sensitive text. The Simple starters install it by default;
custom servers can use it too.

=item mcp_start %config

Starts and runs the usual server. When C<stdio> is true or
C<PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL> is C<stdio>, uses C<mcp_stdio>.
Otherwise starts HTTP without printing its URL. HTTP-capable executables
provide C<--print-url> to retrieve the URL explicitly.

The HTTP defaults are IPv4 loopback, a stable name-derived port in
16384..32767, and C</> as the endpoint path.
Without explicit C<tokens>, one server-specific token is derived from
the private global secret. The selected token authenticates either its URL
path or an
C<Authorization: Bearer TOKEN> header at the clean URL returned by
C<< $server->url (0) >>. The corresponding executable's C<--print-url>
option prints the first accepted token in its URL.

C<name> selects the C<[instance NAME]> configuration section and credential.
It defaults to C<default>.
Named settings C<bind>, C<path>, C<url_host>, C<url_scheme> and C<tokens>
are loaded from the global configuration. Explicit C<tokens> (an ordered,
nonempty array reference of URL-safe strings) replaces the configured list
and the derived default. Every token works in the URL and bearer header.
An explicit C<bind> overrides the configured bind address. Other arguments
override these settings.

The global secret is generated automatically when needed; see
L<AnyEvent::MCP/GLOBAL CONFIGURATION>. No configuration is loaded for stdio.
HTTP startup neither prints to stdout nor changes its buffering.
C<mcp_start> does not parse C<@ARGV>; applications parse their own options.
The bundled executables use C<mcp_getoptions>, which handles shared
options and URL discovery before starting the event loop.

=item mcp_connect %config

Run a reverse-connecting JSONL server using C<connect =E<gt>
"http://host:port/token/alias">. It sends the authenticated extension hello
then serves ordinary MCP over the socket. Retry every second for up to sixty
attempts after a disconnect; calls are cancelled rather than replayed.
This connection has no spawned-child lifecycle authority.

=item mcp_stdio %config

Creates and runs a server over stdin/stdout. Arguments override the collected
configuration. Stdout buffering is disabled. On stdin EOF, pending replies
finish and stdout drains before
this function returns. Stream errors close the connection and cancel pending
requests.

=item mcp_http %config

Creates and runs an HTTP server. For example:

   mcp_http
      host => "127.0.0.1",
      port => 31740,
      path => "/mcp/",
      tokens => ["your-long-random-secret"];

Arguments override the collected configuration. Unlike C<mcp_start>, this
function does not derive or supply authentication. B<Always> pass C<tokens>,
or explicitly pass C<auth =E<gt> "none"> when a trusted embedding layer
enforces access. Omitting both is an error, not an unauthenticated default.
It does not print a URL; use
C<on_start> for application-specific startup output. Neither function
implements OAuth or Basic authentication. See
L<AnyEvent::MCP::Server::HTTP/AUTHENTICATION> for details.

All three starters return when the server is closed or on C<SIGINT> or
C<SIGTERM>. Signal shutdown closes connections and cancels outstanding
requests. The signal watchers belong to the blocking call.

=back

=cut

package AnyEvent::MCP::Server::Simple;

use common::sense;
use AnyEvent ();
use AnyEvent::MCP ();
use AnyEvent::MCP::Server::Toolset ();
use Exporter ();

our @ISA = qw(Exporter);
our @EXPORT = qw(mcp_config mcp_tool mcp_getoptions mcp_tool_help mcp_log mcp_log_request mcp_start mcp_stdio mcp_http mcp_connect);

my %config = (auto_instructions => 1, on_request => \&mcp_log_request);
my $toolset = AnyEvent::MCP::Server::Toolset->new;
my $quiet;

sub _run;

# operational messages go to the configured AnyEvent::Log destination,
# independently of the diagnostic verbosity filter.
sub mcp_log {
   return if $quiet;
   require AnyEvent::Log;
   $AnyEvent::Log::LOG->log (info => @_);
}

sub mcp_log_request {
   my ($server, $req) = @_;

   return unless $req->{method} eq "tools/call";
   return if $req->{mcp_logged}++;

   my $args = $req->{args};
   my @details;
   for (qw(target workdir path cwd)) {
      push @details, "$_=" . (substr $args->{$_}, 0, 160)
         if defined $args->{$_} && !ref $args->{$_};
   }
   push @details, (substr join (" ", @{$args->{ranges}}), 0, 180)
      if ref $args->{ranges} eq "ARRAY";
   if (ref $args->{argv} eq "ARRAY" && @{$args->{argv}}) {
      require JSON::XS;
      my @argv = @{$args->{argv}};
      push @details, "argv=" . join (" ", map {
         JSON::XS::encode_json (substr $_, 0, 80) . (length $_ > 80 ? "..." : "")
      } @argv[0 .. ($#argv < 3 ? $#argv : 3)])
         . (@argv > 4 ? " ..." : "");
   }
   if ($req->{tool} eq "grep" && defined $args->{pattern} && !ref $args->{pattern}) {
      require JSON::XS;
      push @details, "pattern=" . JSON::XS::encode_json (substr $args->{pattern}, 0, 160)
         . (length $args->{pattern} > 160 ? "..." : "");
   }
   push @details, "name=" . (substr $args->{name}, 0, 160)
      if $req->{tool} eq "call-tool" && defined $args->{name} && !ref $args->{name};
   if ($req->{tool} eq "ex" && defined $args->{command} && !ref $args->{command}) {
      require JSON::XS;
      push @details, "command=" . JSON::XS::encode_json (substr $args->{command}, 0, 200)
         . (length $args->{command} > 200 ? "..." : "");
   }
   if ($req->{tool} eq "path-op") {
      push @details, map {
         ($_ eq "unlink" || $_ eq "rmdir")
            ? ($args->{$_} ? $_ : ())
            : (defined $args->{$_} && !ref $args->{$_}
               ? "$_=" . (substr $args->{$_}, 0, 80) : ())
      } qw(unlink rmdir mkpath mkdir symlink truncate chmod rename);
   }

   (my $message = join " ", $req->{tool}, @details) =~ s/[\r\n]/ /g;
   mcp_log $message;

   my $reply = $req->{on_reply};
   $req->{on_reply} = sub {
      my ($req, $result) = @_;

      if ($result->{isError}) {
         my $message = ref $result->{content} eq "ARRAY"
            && ref $result->{content}[0] eq "HASH"
            ? $result->{content}[0]{text} // "unknown error" : "unknown error";
         $message =~ s/\n.*//s;
         mcp_log "$req->{tool} failed: " . (substr $message, 0, 240);
      }
      $reply->(@_);
   };
}

sub _mcp_log_init {
   my ($name, $silent) = @_;

   $quiet = $silent;
   require AnyEvent::Log;
   my $identity = AnyEvent::MCP::Config::program_name () . "/$name" . "[$$]";

   no warnings 'redefine';
   *AnyEvent::Log::default_format = sub ($$$$) {
      my ($when, $ctx, $level, $message) = @_;
      my $stamp = substr (AnyEvent::Log::format_time ($when), 8, 14);
      my $source = $ctx == $AnyEvent::Log::LOG ? "" : "$AnyEvent::Log::LEVEL2STR[$level] $ctx->[0]: ";
      join "", map "$stamp $identity $source$_\n", split /\n/, $message;
   };
}

sub mcp_config {
   my %kv = @_;

   $kv{instructions} = AnyEvent::MCP::_clean_text $kv{instructions}
      if exists $kv{instructions};

   %config = (%config, %kv);
}

sub mcp_tool {
   $toolset->tool (@_)
}

# format a JSON Schema type for command-line tool help.
sub _tool_type {
   my ($schema) = @_;
   return "any" unless ref $schema eq "HASH";
   for my $key (qw(anyOf oneOf)) {
      return join "|", map _tool_type ($_), @{$schema->{$key}}
         if ref $schema->{$key} eq "ARRAY";
   }
   my $type = $schema->{type} // "any";
   $type = join "|", @$type if ref $type eq "ARRAY";
   $type = "array[" . _tool_type ($schema->{items}) . "]" if $type eq "array";
   $type
}

sub mcp_tool_help {
   my ($enabled, @toolsets) = @_;
   return unless $enabled;

   my $json = AnyEvent::MCP::json_class ()->new->canonical;
   my @tools = map @{$_->list}, @toolsets;
   for my $tool (@tools) {
      print "$tool->{name}\n";
      (my $description = $tool->{description} // "") =~ s/\n/\n  /g;
      print "  $description\n" if length $description;

      my $schema = $tool->{inputSchema} || {};
      my $properties = $schema->{properties} || {};
      my %required = map { $_ => 1 } @{$schema->{required} || []};
      for my $name (sort keys %$properties) {
         my $property = $properties->{$name};
         my $type = _tool_type ($property);
         my $status = $required{$name} ? "required" : "optional";
         my @extras;
         push @extras, "default: " . $json->encode ($property->{default})
            if exists $property->{default};
         push @extras, "values: " . join (", ", @{$property->{enum}})
            if ref $property->{enum} eq "ARRAY";
         print "  $name  $type  $status", (@extras ? " (" . join ("; ", @extras) . ")" : ""), "\n";
         if (length ($property->{description} // "")) {
            (my $detail = $property->{description}) =~ s/\n/\n    /g;
            print "    $detail\n";
         }
      }
      print "\n";
   }
   print "No tools registered.\n" unless @tools;
   exit;
}

sub _mcp_help_row {
   my ($option, $description) = @_;

   my $start = "  $option";
   my $margin = " " x 34;
   my $out = length $start < 34 ? "" : "$start\n";
   my $line = length $start < 34 ? $start . (substr $margin, length $start) : $margin;

   for my $word (split /\s+/, $description) {
      if (length $line > 34 && (length $line) + 1 + length $word > 79) {
         $out .= "$line\n";
         $line = $margin;
      }

      $line .= " " if length $line > 34;
      $line .= $word;
   }

   "$out$line\n"
}

sub _mcp_help {
   my ($usage, $description, $options, $option_heading, $examples) = @_;

   $usage =~ s/\n*\z/\n/;
   my $help = $usage;
   $help .= "\n$description\n" if defined $description && length $description;

   $help .= "\nCommon options:\n";
   my @common = (
      ["--name NAME", "Select named configuration (instance defaults to 'default')"],
      ["--bind ADDRESS[:PORT]", "Override the HTTP listen address or port"],
      ["--token TOKEN", "Set an accepted token (repeatable; replaces defaults)"],
      ["--stdio", "Serve MCP on stdin/stdout; other listeners may remain"],
      ["--connect URL", "Connect to a multibroker at http://host:port/token/alias"],
      ["--custom-instructions TEXT", "Describe when this server instance should be used"],
      ["--auto-allow TOOL[,ACTION[,CAPABILITY]]", "Add an ordered automatic allow rule (repeatable)"],
      ["--auto-deny TOOL[,ACTION[,CAPABILITY]]", "Add an ordered automatic deny rule (repeatable)"],
      ["--quiet", "Suppress routine tool activity and tool-failure logging"],
      ["--print-url", "Print authenticated HTTP URL and exit without listening"],
      ["--tool-help", "Print registered tool descriptions and arguments, then exit"],
      ["-h, --help", "Display this help and exit"],
   );
   $help .= _mcp_help_row (@$_) for @common;

   if ($options && @$options) {
      $help .= "\n" . ($option_heading // "Application options:") . "\n"
         if ref $options->[0];
      for my $option (@$options) {
         if (ref $option) {
            $help .= _mcp_help_row (@$option);
         } else {
            $help .= "\n" unless $help =~ /\n\n\z/;
            $help .= "$option\n";
         }
      }
   }
   $help .= "\nExamples:\n$examples\n"
      if defined $examples && length $examples;

   $help
}

sub mcp_getoptions {
   require Getopt::Long;
   require AnyEvent::MCP::Config;

   my %settings = %{ref $_[0] eq "HASH" ? shift : {}};
   my $usage = delete $settings{usage}
      // "Usage: $0 [OPTION]... [ARG]...\n";
   my @help = delete @settings{qw(description options option_heading examples)};
   my %url = (%config, %settings);
   delete @url{qw(name bind stdio)};
   my @auto_rules;

   Getopt::Long::GetOptions (
      AnyEvent::MCP::Config::http_getopt (\my $name, \my $bind, \my $print_url, \my @tokens),
      "stdio" => \my $stdio,
      "connect=s" => \my $connect,
      "custom-instructions=s" => \my $custom_instructions,
      "auto-allow=s" => sub { push @auto_rules, ["allow", $_[1]] },
      "auto-deny=s"  => sub { push @auto_rules, ["deny", $_[1]] },
      "tool-help" => \my $tool_help,
      "quiet" => \my $silent,
      "help|h" => \my $help,
      @_,
   ) or die $usage;

   if ($help) {
      print _mcp_help $usage, @help;
      exit;
   }

   $name = AnyEvent::MCP::Config::server_name ($name // $settings{name} // $config{name});
   _mcp_log_init ($name, $silent);
   my %server = (
      %settings,
      name => $name,
      (defined $bind ? (bind => $bind) : ()),
      (@tokens ? (tokens => \@tokens) : ()),
      ($stdio ? (stdio => 1) : ()),
      (defined $connect ? (connect => $connect) : ()),
      (defined $custom_instructions ? (custom_instructions => $custom_instructions) : ()),
      (@auto_rules ? (auto_rules => \@auto_rules) : ()),
      ($tool_help ? (tool_help => 1) : ()),
   );

   if ($print_url) {
      my %options = (%url, (@tokens ? (tokens => \@tokens) : ()));
      my $global = AnyEvent::MCP::Config->global;
      $options{path} //= $global->{section}{"instance $name"}{path}
         // $global->{section}{"program " . AnyEvent::MCP::Config::program_name ()}{path} // "/";
      if (($options{auth} || "") eq "none") {
         !exists $options{tokens} or die "Cannot combine auth => none with tokens\n";
      }
      my $selected_bind = defined $bind ? $bind : ($settings{bind} // $config{bind});
      print $global->http_url ($name, $selected_bind, %options), "\n";
      exit;
   }

   \%server
}

sub _permission_options {
   my %kv = @_;

   if (my $rules = delete $kv{auto_rules}) {
      require AnyEvent::MCP::Server::Permissions;
      my $permissions = $kv{permissions} ||= AnyEvent::MCP::Server::Permissions->new;
      $permissions->auto_rules ($rules);
   }

   %kv
}

sub _server_options {
   my %kv = @_;

   if (exists $kv{server_name} || exists $kv{server_version}) {
      !exists $kv{server_info}
         or die "Cannot combine server_info with server_name/server_version\n";

      my $name = delete $kv{server_name};
      my $version = delete $kv{server_version};
      $kv{server_info} = {
         name => defined $name ? $name : "AnyEvent::MCP",
         version => defined $version ? "$version" : "$AnyEvent::MCP::VERSION",
      };
   }

   %kv
}

sub mcp_start {
   require AnyEvent::MCP::Config;

   my %kv = (%config, @_);
   mcp_tool_help (delete $kv{tool_help}, @{$kv{toolsets} || [$toolset]});
   my $name = AnyEvent::MCP::Config::server_name ($kv{name});
   my $config_file = AnyEvent::MCP::Config::_file ();
   my $global = -e $config_file ? AnyEvent::MCP::Config->global : undef;
   my %ini = $global ? (
      %{$global->{section}{"program " . AnyEvent::MCP::Config::program_name ()} || {}},
      %{$global->{section}{"instance $name"} || {}},
   ) : ();
   if ($global) {
      my @rules = $global->auto_rules ($name);
      $kv{auto_rules} = [@{$kv{auto_rules} || []}, @rules] if @rules;
   }
   $kv{custom_instructions} = $ini{custom_instructions}
      if !exists $kv{custom_instructions} && exists $ini{custom_instructions};
   %kv = _permission_options (%kv);
   my $stdio = delete $kv{stdio};
   my $listen = delete $kv{listen};
   my $connect = delete $kv{connect};
   !($stdio && defined $connect) or die "Cannot combine --stdio and --connect\n";
   $stdio ||= !defined $connect && $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} eq "stdio";

   $kv{name} = $name;

   if (!$listen) {
      return mcp_connect (%kv, connect => $connect) if defined $connect;
      return mcp_stdio (%kv) if $stdio;
   }

   my %http = ($global ||= AnyEvent::MCP::Config->global)->http_settings ($name, delete $kv{bind});
   delete $http{tokens} if ($kv{auth} || "") eq "none";
   my %options = (path => "/", %http, %kv);

   if ($stdio || defined $connect) {
      require AnyEvent::MCP::Server::HTTP;
      my $listener = AnyEvent::MCP::Server::HTTP->new (toolsets => [$toolset], _server_options (%options));
      $listener->listen;
      my $result = defined $connect
         ? mcp_connect (%kv, connect => $connect)
         : mcp_stdio (%kv);
      $listener->close;
      return $result
   }

   mcp_http (%options)
}

sub mcp_connect {
   require AnyEvent::MCP::Server::Connect;

   my %kv = _server_options (%config, @_);
   mcp_tool_help (delete $kv{tool_help}, @{$kv{toolsets} || [$toolset]});
   my $server = AnyEvent::MCP::Server::Connect->new (toolsets => [$toolset], _permission_options (%kv));
   $server->start;
   _run ($server, 1)
}

sub mcp_stdio {
   require AnyEvent::MCP::Server::JSONL;

   my %kv = _permission_options (_server_options (%config, @_));
   mcp_tool_help (delete $kv{tool_help}, @{$kv{toolsets} || [$toolset]});
   my $idle_exit = delete $kv{idle_exit};
   binmode STDIN;
   binmode STDOUT;
   my $selected = select STDOUT;
   $| = 1;
   select $selected;

   my $server = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset], %kv);
   $server->accept (\*STDIN, \*STDOUT);

   if ($idle_exit) {
      $idle_exit =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $idle_exit > 0
         or die "invalid idle_exit seconds\n";
      if ($ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} eq "stdio") {
         my ($timer, $check);
         $check = sub {
            return if $server->{idle_exit_requested};
            if (grep $_->{mcp_active}, values %{$server->{connections} || {}}) {
               $timer = AnyEvent->timer (after => $idle_exit, cb => $check);
            } else {
               $server->request_idle_exit;
            }
         };
         my $schedule = sub {
            $timer = AnyEvent->timer (after => $idle_exit, cb => $check);
         };
         my $on_request = $server->{on_request};
         $server->{on_request} = sub {
            my ($server, $req) = @_;

            if ($req->{method} ne "anyevent-mcp/shutdown") {
               $server->{idle_exit_requested} = 0;
               $schedule->();
               my $reply = $req->{on_reply};
               $req->{on_reply} = sub {
                  $reply->(@_);
                  $schedule->() unless $server->{_idle_shutting_down};
               };
            }
            $on_request->(@_) if $on_request;
         };
         my $on_close = $server->{on_close};
         $server->{on_close} = sub {
            undef $timer;
            $on_close->(@_) if $on_close;
         };
         $schedule->();
      }
   }
   _run $server
}

sub mcp_http {
   require AnyEvent::MCP::Server::HTTP;

   my %kv = _permission_options (_server_options (%config, @_));
   mcp_tool_help (delete $kv{tool_help}, @{$kv{toolsets} || [$toolset]});
   my $server = AnyEvent::MCP::Server::HTTP->new (toolsets => [$toolset], %kv);
   $server->listen;
   _run $server
}

sub _run {
   my ($server, $keep_alive) = @_;

   my $cv = AnyEvent->condvar;
   my $stopped;
   my $stop = sub { $cv->send unless $stopped++ };
   my $on_close = $server->{on_close};
   $server->{on_close} = sub {
      $on_close->(@_) if $on_close;
      $stop->();
   };

   if (!$keep_alive && $server->isa ("AnyEvent::MCP::Server::JSONL")) {
      my $on_connection_close = $server->{on_connection_close};
      $server->{on_connection_close} = sub {
         $on_connection_close->(@_) if $on_connection_close;
         $stop->();
      };
   }

   my @signals = map {
      AnyEvent->signal (signal => $_, cb => sub { $server->close })
   } qw(INT TERM);

   my $ok = eval {
      $server->event (start =>);
      $cv->recv;
      1
   };
   my $error = $@;
   $server->close;
   die $error unless $ok;
   return
}

1
