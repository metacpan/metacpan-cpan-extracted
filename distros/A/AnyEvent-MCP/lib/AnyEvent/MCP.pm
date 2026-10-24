=head1 NAME

AnyEvent::MCP - Model Context Protocol client/server support

=head1 SYNOPSIS

   use AnyEvent::MCP::Server::Simple;

   my $options = mcp_getoptions ...;
   mcp_tool ...;
   mcp_start %$options;

or use the object interface directly:

   use AnyEvent::MCP::Server ();

   my $server = AnyEvent::MCP::Server->new (...);

=head1 DESCRIPTION

AnyEvent::MCP provides event-driven Model Context Protocol client and server
support. There are three starting points:

=over

=item Use the included servers without writing Perl

L<AnyEvent::MCP::Intro> walks through installation, a first filesystem
request, client connections, configuration, permissions and combining
servers. Start there if you want the tools to work on your projects.

=item Write a small MCP server

L<AnyEvent::MCP::Server::Simple/TUTORIAL> builds a complete server,
calls it, and adds options, replies, permission checks and asynchronous
work. Simple handles transport startup and the event loop.

=item Embed MCP in an application

The modules below expose tool registries, protocol dispatch, requests and
transports separately, for applications that need to control their own
connections or lifetime.

=back

The usual way to implement a small MCP server is
L<AnyEvent::MCP::Server::Simple>, which provides a function-based interface and
creates the underlying server objects when a transport such as stdio or HTTP is
started.

The lower-level object interfaces are intended for applications that need to
manage MCP connections, servers or reusable tool registries directly.

=head2 MODULES

=over

=item L<AnyEvent::MCP::Server::Simple>

Function-based interface for implementing ordinary MCP servers.

=item L<AnyEvent::MCP::Server>

Object-oriented MCP server interface.

=item L<AnyEvent::MCP::Client>

Object-oriented MCP client interface.

=item L<AnyEvent::MCP::Server::Toolset>

Reusable registry of MCP tool declarations.

=item L<AnyEvent::MCP::Server::Request>

One incoming server request: arguments, replies, cancellation and progress.

=item L<AnyEvent::MCP::Client::Request>

Input requested from the MCP client, including human elicitation.

=item L<AnyEvent::MCP::Server::HTTP> and L<AnyEvent::MCP::Server::JSONL>

HTTP listener and stdio/byte-stream server transports. Both use the
protocol handling in L<AnyEvent::MCP::Server>.

=item L<AnyEvent::MCP::Client::HTTP> and L<AnyEvent::MCP::Client::JSONL>

HTTP and subprocess/byte-stream client transports; both use
L<AnyEvent::MCP::Client> for protocol negotiation and tool calls.

=item L<AnyEvent::MCP::Server::Connect>

Reverse MCP connection from a server into a multibroker.

=item L<AnyEvent::MCP::Server::Permissions>

Action authorization and sandbox-grant handling for MCP servers.

=item L<AnyEvent::MCP::Permissions::Ask>

External permission dialog handling and form conversion for clients.

=item L<AnyEvent::MCP::Config>

Private global configuration, named server settings and derived credentials.

=item L<AnyEvent::MCP::Helper>

Asynchronous JSON exchange with an external form or permission helper.

=item L<AnyEvent::MCP::Workdirs> and L<AnyEvent::MCP::File>

Persistent workdir identifiers and their locked state-file utilities.

=item L<AnyEvent::MCP::Extension>

Private authenticated raw-TCP protocols sharing an HTTP listener.

=back

C<mcp-multibroker> combines downstream HTTP and stdio servers under tool-name
prefixes. It uses the same client, server and permission helper facilities,
including modern input forwarding and local permission prompts for legacy
callers. Run C<mcp-multibroker --help> for command-line syntax; its manual
describes authentication and configuration.

The interfaces are still being designed. L<AnyEvent::MCP::Intro> explains
the installed programs; module-specific POD describes their Perl APIs.

=head1 TUTORIAL

For using the servers, see L<AnyEvent::MCP::Intro>. It includes a working
first connection, a complete configuration example, saved permissions,
multibroker setup and troubleshooting.

For writing a server, see L<AnyEvent::MCP::Server::Simple/TUTORIAL>.
The tutorial starts with a complete echo server and a client that prints
its reply, then develops argument validation, command-line options,
result representations, permission retries and cancellable asynchronous
work. The Simple function reference follows it.

For custom dispatch and reusable tool registries, see
L<AnyEvent::MCP::Server::Toolset/REQUEST AND TOOL WORKFLOW> and
L<AnyEvent::MCP::Server>. The client modules describe calling servers
from your own application.


=head1 GLOBAL CONFIGURATION

The shared per-user configuration is C<$XDG_CONFIG_HOME/anyevent-mcp/global.ini>,
or C<$HOME/.config/anyevent-mcp/global.ini> when XDG_CONFIG_HOME is unset.
L<AnyEvent::MCP::Config> loads and holds it; loading this module does not access
configuration files.

The file is UTF-8 and uses sections with single-line C<key = value> pairs.
Values are unquoted strings. Blank lines and whole-line comments beginning
with C<#> or C<;> are ignored; inline comment characters remain part of the
value. Later occurrences of a key replace earlier ones in the same section.

   [global]
   secret = ...128 hexadecimal digits...

   [instance example]
   bind = 127.0.0.1:31740
   tokens = first-token,second-token

   [program mcp-fs]
   mount.opt = ro:/opt

Section names are unrestricted. Application-specific sections, including
exports, utility paths and user settings, are documented by their applications.

C<[global]> holds C<secret>, a 64-byte master key encoded as 128 hexadecimal
digits. The file must be owned by the current user, with no group or other
permissions. A missing secret is generated automatically on first configuration
access and saved when possible. Existing secrets are never replaced implicitly.
An invalid secret is an error.

Applications can derive their own purpose-specific secrets with
L<AnyEvent::MCP::Config/derive_secret>, using the cached global configuration
or an explicitly loaded configuration object.

If saving fails, Config warns and retains the secret in memory. Credentials
then remain stable only for that process; other processes cannot derive the
same credentials. If randomness is unavailable, supply a securely generated
secret in the file.

C<[program PROGRAM]> supplies settings for the invoked program basename;
C<[instance NAME]> overrides them for a named instance.
HTTP-capable executables use C<--name NAME> to select these settings, with
C<default> as the default instance name. Names consist of an ASCII
letter or underscore followed by ASCII letters, digits, underscores or
hyphens. Their C<--bind ADDRESS[:PORT]> overrides the configured C<bind>.
The default bind address is IPv4 loopback with a port derived from the program,
instance name and master secret in the range 16384..32767; C<:0> requests an ephemeral
port. C<--print-url> prints the URL using the first accepted token without
listening. Named server settings also include C<path>, C<url_host>,
C<url_scheme> and C<tokens>. C<tokens> is a comma-separated list of
URL-safe strings. Repeated C<--token TOKEN> options override this list.
Automatic permission defaults use C<auto-rule.SUFFIX = allow|deny
TOOL[,ACTION[,CAPABILITY]]> in program/instance sections, sorted by suffix.
Instance entries override matching keys or suppress them with empty values.
Command-line automatic rules are evaluated before configured defaults.
All accepted tokens work in the URL path or Authorization bearer header.
Without configured tokens, one token is derived from the program and instance
name. All derivation contexts have a fixed C<anyevent-mcp> namespace prefix.

C<mcp_start> resolves named settings and requires the selected token for
HTTP requests. Explicit tokens replace the derived default.
The low-level HTTP transport does not resolve configuration itself.
Simple's stdio startup does not access global HTTP configuration.
Applications can still load it for their own settings; C<mcp-fs>, for
example, reads trusted mount and executable settings even in stdio mode.
Browser origins are permitted by default, but must still pass MCP authentication.

C<[client NAME]> supplies HTTP client defaults: C<url>, C<bearer> and
C<timeout>. Clients consult it only when explicitly given a C<name>.
An unnamed HTTP client and the low-level HTTP server do not read global
configuration. C<mcp_start> resolves a default name and does read it.
Explicit constructor arguments take precedence over named defaults.

=head1 ENVIRONMENT

Project-specific environment variables use the C<PERL_ANYEVENT_MCP_> prefix.
C<PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL=stdio> selects stdio in Simple.
C<PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS> names a multibroker routing prefix;
it does not change the service-instance name.
C<PERL_ANYEVENT_MCP_PERMISSION_HELPER> selects the external asking executable.
C<PERL_ANYEVENT_MCP_PERMISSION_ASK> selects the permission engine's
asking default: C<helper>, C<tty>, C<yad>, C<auto> or C<mcp>. See
L<AnyEvent::MCP::Intro/Choose where to ask> for the behavior and client
requirements.
Standard C<HOME> and C<XDG_CONFIG_HOME> keep their standard names.

=head1 FUNCTIONS

=over

=item $class = AnyEvent::MCP::json_class

Returns C<JSON::XS> if available, otherwise C<JSON::PP>. The caller
configures a new coder instance as needed.

=item $bytes = AnyEvent::MCP::utf8enc $text

Return a UTF-8 byte string for C<$text>, leaving the argument unchanged.

=item $text = AnyEvent::MCP::utf8dec $bytes

Decode a UTF-8 byte string into characters, dying on invalid UTF-8.
The argument is left unchanged. For intentional in-place conversions,
use Perl's C<utf8::encode> or C<utf8::decode> directly.

=item AnyEvent::MCP::parse_ini $text, $callback, $filename

Parse INI text and call C<$callback-E<gt>($name, $kv)> for each section
in file order, including the initial unnamed section (name C<"">).
Repeated sections remain separate; duplicate keys within a section use
their last value. The callback decides how to collect sections.
C<$filename> is optional and used only for line-numbered errors.

=item $bytes = AnyEvent::MCP::random_bytes $length

Returns exactly C<$length> random bytes. Tries C</dev/urandom>, then an external
C<openssl rand> command. No additional random-number module is required.
Dies if neither source supplies the requested bytes successfully.
C<$length> must be a nonnegative integer; zero returns an empty string.

=back

=head2 PATCH UTILITIES

Since applying patches to files is a common task for MCP servers, the
following utility functions can be used to ease that job. Together, they
define a common patch format (unified diff or a simplified version of it,
with fewer requirements to make it easier for the LLM to generate), helpers
to apply the patch and a helper to verify if the patch was applied
with sufficient precision.

Use C<apply_udiff> to normalize, apply and validate a patch in one operation.
It writes a separate output file; the caller checks freshness and metadata
and commits the result.

For an application-specific applier, the workflow is:

=over

=item 1. AnyEvent::MCP::normalize_udiff

Returns a unified diff for GNU patch and the permitted hunk offsets.

=item 2. Apply the normalized diff

Run GNU patch with fuzz zero and capture its verbose output.

=item 3. AnyEvent::MCP::check_patch_output

Checks the process status and output against the permitted offsets.
C<parse_patch_output> is available separately when only parsing is needed.

=back

=head3 Input format

The patch format accepted by normalize_udiff is an extension to the
(essentially undocumented) unified diff format.

In a hunk header, only the old start C<-N> matters. It is the old-file line
of the first hunk body line, including context, not necessarily the first
changed line. Counts and the new-file position are ignored and recomputed.
Both ordinary headers and the abbreviated form are accepted:

   @@ -42,99 +123,99 @@
   @@ -42 @@

Optional text after the closing C<@@> is preserved. File headers and other
text before the first hunk are preserved; a diff must describe one file.

Hunk body lines use the usual prefixes: a space for unchanged context,
C<-> for removed lines and C<+> for added lines. The
C<\ No newline at end of file> marker is preserved and counts neither side.
Trailing empty lines outside the final hunk are discarded.

Pure insertion is permitted only at the beginning, using old start C<0>.
For example, C<@@ -0 @@> with one added line becomes C<@@ -0,0 +1,1 @@>.
An empty old-side range names the line before the insertion: C<-0,0>
means before line 1, whereas C<-1,0> would mean after line 1 and is rejected
here. Nonempty ranges use one-based line numbers.

An insertion elsewhere needs old-side context. Empty hunks are rejected.
New positions include the cumulative line-count changes of preceding hunks.

=head3 Applying the result

The C<normalize_udiff> function does not apply the patch, check file
contents or guard against concurrent edits. The caller must supply those
checks, if required.

Context must match exactly: apply with fuzz zero. For each hunk,
C<$max_offset> permits relocation by at most the number of distinct old-side
lines minus one, or zero for a pure insertion. Repeated old-side lines do
not increase this allowance. The applier must enforce these limits; an
unrestricted search for matching context can select the wrong occurrence.

For live Vim buffers, also require the expected changedtick to match.
File-based users need an equivalent check before replacing the file.

To work around GNU patch's handling of asymmetric context, the
first context line of each hunk is rewritten as an identity
removal/addition. The line contents and old/new line counts are
unchanged. This is normalization for the patch applier, not a relaxation
of context matching.

=over

=item ($diff, $max_offset) = AnyEvent::MCP::normalize_udiff $diff

Normalizes a relaxed, single-file unified diff into ordinary unified diff
syntax. Returns the normalized C<$diff> and an array reference C<$max_offset>
containing the permitted whole-hunk relocation for each hunk, in order.
Dies on malformed hunks or when no hunks are found.

Here is a suitable description for the diff format, e.g. in a tool
definition:

   Apply a unified diff to one regular file. Hunk counts are recomputed,
   fuzz is disabled, whole-hunk relocation is limited per hunk by distinct
   old-side lines. Pure insertion is allowed only at the beginning;
   elsewhere include old-side context.

=item $cv = AnyEvent::MCP::apply_udiff $input, $output, $diff

Asynchronously applies the relaxed C<$diff> to the input file C<$input>,
writing a separate output file C<$output>. C<$diff> must contain bytes;
callers working with characters must encode them for the file themselves.

Normalizes the diff, runs GNU patch using C<AnyEvent::Util::run_cmd>, and
validates its verbose output with C<check_patch_output>. The command uses
batch/forward mode, binary mode and fuzz zero. No shell is involved.

C<$output> must not exist. It is reserved with mode 0600; patch runs in its
directory so incidental temporary files stay there. Input and output paths
are made absolute before starting the command. These must be trusted paths
in a directory controlled by the caller.

Returns a condition variable. Its C<recv> returns the validated hunk array
reference, or throws on command/application failure. Setup failures throw
synchronously. Failed or partial output is removed. C<$input> is unchanged.

The caller owns committing the successful output and removing it when no
longer needed. Freshness checks, metadata preservation, atomic replacement
and application-specific permissions also belong to the caller.

For your reference, the exact options used are:

   --verbose --batch --forward --binary --fuzz=0
   --no-backup-if-mismatch
   --reject-file=- --output=... -- <inputfile>

=item $parsed = AnyEvent::MCP::parse_patch_output $output

Parses C<LC_ALL=C> GNU patch C<--verbose> output without judging whether
the application is acceptable. C<$parsed> has two fields:

=over

=item hunks => [$hunk...]

Hunk records in output order. Each record contains C<hunk> (the one-based
number), C<success>, C<line> (the reported application line), C<fuzz> and
the signed C<offset>. Omitted fuzz and offset are zero. Failed and ignored
hunks have false C<success>.

=item unparsed => [$line...]

Lines not recognized as hunk results or GNU patch's verbose framing.
The parser preserves them for callers to interpret or reject.

=back

Use verbose output: ordinary patch output omits exact-position successes,
so it cannot account for every hunk.

=item $hunks = AnyEvent::MCP::check_patch_output $status, $output, [$max_offset...]

Parses C<$output> and validates a complete application. C<$status> is the
raw process wait status, as returned by C<waitpid> or
C<AnyEvent::Util::run_cmd>, not just the exit code.

Requires status zero, no unrecognized output, exactly the expected hunks
in numbered order, successful application, fuzz zero and each signed offset
within its corresponding absolute limit. C<[$max_offset...]> is the array
reference returned by C<normalize_udiff>. At least one hunk is required.

Returns the parsed hunk array reference on success; otherwise dies with a
diagnostic. This is also suitable for callers running patch inside their
own sandbox.

=back

=cut

package AnyEvent::MCP;

use common::sense;

our $VERSION = 0.65;

sub json_class {
   our $JSON_CLASS ||= eval { require JSON::XS; "JSON::XS" }
                    || do { require JSON::PP; "JSON::PP" };
}

sub utf8enc($) {
   my $text = shift;

   utf8::encode $text;
   $text
}

sub utf8dec($) {
   my $bytes = shift;

   utf8::decode $bytes
      or die "invalid UTF-8\n";
   $bytes
}

sub parse_ini {
   my ($text, $cb, $file) = @_;
   $file //= "INI";
   my ($name, $kv, $line) = ("", {}, 0);

   for (split /\n/, $text) {
      ++$line;
      s/\r\z//;
      next if /\A\s*(?:[#;]|\z)/;
      if (/\A\s*\[([^\]\r\n]+)\]\s*\z/) {
         my $next = $1;
         $cb->($name, $kv);
         ($name, $kv) = ($next, {});
      } elsif (/\A\s*([^=\s]+)\s*=\s*(.*?)\s*\z/) {
         $kv->{$1} = $2;
      } else {
         die "$file:$line: invalid INI line\n";
      }
   }

   $cb->($name, $kv);
}

sub random_bytes($) {
   my ($length) = @_;

   defined $length && $length =~ /\A[0-9]+\z/
      or die "Invalid random byte count\n";
   return "" unless $length;

   my $bytes = "";

   if (open my $fh, "<", "/dev/urandom") {
      binmode $fh;
      while (length $bytes < $length) {
         read ($fh, $bytes, $length - length ($bytes), length $bytes)
            or last;
      }
      close $fh;

      return $bytes if length $bytes == $length;
   }

   if (open my $fh, "-|", "openssl", "rand", $length) {
      binmode $fh;
      local $/;
      $bytes = <$fh>;
      my $success = close $fh;

      return $bytes
         if $success && defined $bytes && length $bytes == $length;
   }

   die "Cannot obtain $length random bytes from /dev/urandom or openssl rand\n";
}

sub normalize_udiff {
   my $diff = shift;
   my @line = split /\n/, $diff, -1;
   my $delta = 0;
   my $hunks = 0;
   my @max_offset;

   pop @line while @line and !length $line[-1];

   for (my $i = 0; $i < @line; ++$i) {
      next unless $line[$i] =~ /^@@ /;

      $line[$i] =~ /^@@ -(\d+)(?:,\d+)?(?: \+\d+(?:,\d+)?)? @@(.*)$/
         or die "normalize_udiff: bad hunk header '$line[$i]'\n";

      my ($old_start, $suffix) = ($1, $2);
      my ($old_count, $new_count) = (0, 0);
      my %old_line;
      my $j = $i + 1;

      # GNU patch mishandles hunks with more prefix than suffix context.
      # Make the first context line an identity change without losing it.
      # see https://unix.stackexchange.com/questions/414542/does-patch-work-with-asymmetric-context
      splice @line, $i + 1, 1, "-$1", "+$1"
         if $line[$i + 1] =~ /^ (.*)\z/;

      for (; $j < @line; ++$j) {
         last if $line[$j] =~ /^@@ /;

         my $tag = substr $line[$j], 0, 1;

         if ($tag eq " ") {
            ++$old_count;
            ++$new_count;
            $old_line{substr $line[$j], 1} = 1;
         } elsif ($tag eq "-") {
            ++$old_count;
            $old_line{substr $line[$j], 1} = 1;
         } elsif ($tag eq "+") {
            ++$new_count;
         } elsif ($line[$j] eq "\\ No newline at end of file") {
            # Marker belongs to the preceding body line and counts neither side.
         } else {
            die "normalize_udiff: bad hunk line '$line[$j]'\n";
         }
      }

      $old_count or $new_count
         or die "normalize_udiff: empty hunk at old line $old_start\n";

      $old_count or !$old_start
         or die "normalize_udiff: hunk " . ($hunks + 1)
              . " needs old-side context for insertion after old line $old_start\n";

      my $new_start = $old_start + $delta;
      ++$new_start unless $old_count;
      --$new_start unless $new_count;

      $new_start >= 0
         or die "normalize_udiff: invalid new line $new_start\n";

      $line[$i] = sprintf "@@ -%d,%d +%d,%d @@%s",
         $old_start, $old_count, $new_start, $new_count, $suffix;

      $delta += $new_count - $old_count;
      ++$hunks;
      my $max_offset = keys %old_line;
      --$max_offset
         if $max_offset;
      push @max_offset, $max_offset;
      $i = $j - 1;
   }

   $hunks
      or die "normalize_udiff: no hunks\n";

   (join ("\n", @line, ""), \@max_offset)
}

sub parse_patch_output {
   my ($output) = @_;
   my (@hunks, @unparsed);

   for (split /\n/, $output) {
      if (/^Hunk #(\d+) (succeeded|FAILED|ignored) at (-?\d+)(?: with fuzz (\d+))?(?: \(offset (-?\d+) lines?\))?\.\z/) {
         push @hunks, {
            hunk    => 0 + $1,
            success => $2 eq "succeeded",
            line    => 0 + $3,
            fuzz    => 0 + $4,
            offset  => 0 + $5,
         };
      } elsif (!length
         || /^Hmm\.\.\. +Looks like a unified diff to me\.\.\.\z/
         || /^The text leading up to this was:\z/
         || /^-+\z/ || /^\|/
         || /^patching file / || /^checking file /
         || /^Using Plan [AB]\.\.\.\z/ || /^done\z/) {
         # GNU patch --verbose framing, not hunk results.
      } else {
         push @unparsed, $_;
      }
   }

   { hunks => \@hunks, unparsed => \@unparsed }
}

sub check_patch_output {
   my ($status, $output, $max_offset) = @_;
   my $parsed = parse_patch_output $output;
   my $hunks = $parsed->{hunks};

   die "patch failed (wait status $status):\n$output"
      if $status;
   die "patch: unrecognized output:\n" . (join "\n", @{$parsed->{unparsed}}) . "\n"
      if @{$parsed->{unparsed}};
   die "patch: expected " . @$max_offset . " hunks, got " . @$hunks . "\n"
      unless @$hunks == @$max_offset && @$hunks;

   for my $i (0 .. $#$hunks) {
      my $hunk = $hunks->[$i];

      die "patch: unexpected hunk number $hunk->{hunk}\n"
         unless $hunk->{hunk} == $i + 1;
      die "patch: hunk $hunk->{hunk} failed\n"
         unless $hunk->{success};
      die "patch: hunk $hunk->{hunk} used fuzz $hunk->{fuzz}\n"
         if $hunk->{fuzz};
      die "patch: hunk $hunk->{hunk} offset $hunk->{offset} exceeds $max_offset->[$i]\n"
         if abs $hunk->{offset} > $max_offset->[$i];
   }

   $hunks
}

sub apply_udiff {
   my ($input, $output, $diff) = @_;
   my ($normalized, $max_offset) = normalize_udiff $diff;

   require AnyEvent::Util;
   require File::Spec;
   require File::Basename;
   require Fcntl;

   $input  = File::Spec->rel2abs ($input);
   $output = File::Spec->rel2abs ($output);
   my $directory = File::Basename::dirname ($output);

   sysopen my $fh, $output, Fcntl::O_WRONLY () | Fcntl::O_CREAT () | Fcntl::O_EXCL (), 0600
      or die "$output: $!\n";
   close $fh or do { my $error = $!; unlink $output; die "$output: $error\n" };

   my $cv = AE::cv ();
   my $log;
   my $process = eval {
      AnyEvent::Util::run_cmd ([
         "patch", "--verbose", "--batch", "--forward", "--binary", "--fuzz=0",
         "--no-backup-if-mismatch", "--reject-file=-", "--output=$output", "--", $input,
      ],
         "<" => \$normalized,
         ">" => \$log,
         close_all => 1,
         on_prepare => sub {
            $ENV{LC_ALL} = "C";
            chdir $directory or die "$directory: $!\n";
            defined POSIX::dup2 (1, 2) or die "dup2: $!\n";
         },
      );
   };

   if ($@) {
      my $error = $@;
      unlink $output;
      die $error;
   }

   $process->cb (sub {
      my $hunks;
      eval { $hunks = check_patch_output $_[0]->recv, $log, $max_offset; 1 } or do {
         my $error = $@;
         unlink $output;
         $cv->croak ($error);
         return;
      };

      $cv->send ($hunks);
   });

   $cv
}

sub _clean_text($) {
   my ($text) = @_;

   my ($prefix) = (join "\n", grep /\S/, split /\n/, $text)
      =~ /\A([ \t]*)[^\n]*(?:\n\1[^\n]*)*\z/;

   $text =~ s/^\Q$prefix\E//mg;
   $text =~ s/\A\s+//;
   $text =~ s/\s+\z//;
   $text
}

package AnyEvent::MCP::Base;

sub new {
   my ($class, %kv) = @_;

   bless \%kv, $class
}

sub event {
   my ($self, $event, @args) = @_;

   ($self->{"on_$event"} or return)->($self, @args)
}

=head1 SEE ALSO

L<AnyEvent::MCP::Intro>, L<AnyEvent::MCP::Server::Simple>,
L<AnyEvent::MCP::Helper>, L<mcp-ask-user>, L<anyevent-mcp-form-elicitation>,
L<AnyEvent>, L<https://modelcontextprotocol.io/>

=head1 AUTHOR

The main author of this module is OpenAI ChatGPT.

Additional guidance received by:

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1

