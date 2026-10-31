=head1 NAME

AnyEvent::MCP::Server::Permissions - action authorization and sandbox grants

=head1 SYNOPSIS

   my $permissions = AnyEvent::MCP::Server::Permissions->new (
      name           => "example",
      actions        => { read => "Read file contents", write => "Modify files" },
      sandbox_grants => {
         "workdir-read"  => [],
         "workdir-write" => ["workdir-read"],
      },
      sandbox_grant_descriptions => {
         "workdir-read" => "Read the configured workdir",
      },
      sandbox_implementation => "bubblewrap",
   );

   my $grant = $req->require_permission ({
      tool           => $req->{tool},
      action         => "read",
      dimensions     => { subject => {
         label => "File", value => $path,
         choices => [{ label => "this file", match => $path }],
      } },
      sandbox_grants => ["workdir-read"],
      reason         => "read $path",
   });

=head1 DESCRIPTION

This module lets an MCP server check whether a tool operation is allowed
before doing the work. It applies ordered permission rules and asks the
user when a decision is needed. Users can allow or deny one operation,
or save a rule for future requests.

Attach a Permissions object to your server, then have each tool call
C<< $req->require_permission >> before starting its operation. The tool
describes what it wants to do and which worker privileges it needs. An
allowed request receives the granted sandbox privileges; a denied request
must not proceed.

By default, questions go to a local graphical or terminal helper. You can
instead configure the server to ask through an MCP client that supports
form elicitation. Saved rules can answer later requests without another
prompt; see L</RULE FILES>.

For HTTP, the transport must authenticate callers before dispatching MCP
requests. This module then authorizes operations for the accepted caller. The tool
must enforce the returned grants, for example by constructing a restricted
sandbox. The permission engine does not construct that sandbox or enforce
worker isolation itself.

=head2 The three separate questions

Authentication establishes who may call the MCP endpoint.
The permission engine answers whether a requested B<action> on a
B<subject> may proceed and which B<sandbox grants> the user approved.
The application's sandbox or other enforcement then determines what
the operation can actually do. None of the three substitutes for the others.

For example, a user may approve C<write> on a project but only with
C<workdir-write> authority. This does not authorize an arbitrary
command with network access, and an approval to write a buffer does not
imply approval to save it. Ask before side effects: permission prompts
can restart the tool callback. See
L<AnyEvent::MCP::Server::Toolset/Permission checks and retries>
and L<AnyEvent::MCP::Intro> for examples from actual servers.

=head1 PERMISSION REQUESTS

A request names an C<action> (a server-defined class of authority such as
C<inspect>, C<read>, C<write>, C<manage> or C<exec>), optional named
C<dimensions>, and the C<sandbox_grants> required by its worker. These are independent:
authorization to write does not imply authorization to read, although
sandbox-level C<workdir-write> may imply C<workdir-read>. C<tool> is optional
human-readable context identifying the actual MCP tool; rules do not match it.

An action may have a short human-readable description declared in C<actions>.
C<sandbox_grant_descriptions> similarly describes worker privileges, and
C<sandbox_implementation> identifies the enforcement environment (for example,
C<bubblewrap> or C<NONE - UNSANDBOXED>). These labels are explanatory, not
authorization identifiers, and the trusted server supplies them.

C<details> optionally maps plain display labels to Unicode text, for example
C<< { "View patch" => $diff } >>. These details are display-only and never
participate in rule matching or persistence. Supply complete text; the UI
chooses presentation, escaping and preview limits. Labels carry no UI
punctuation such as an ellipsis. The local YAD helper opens a text viewer;
terminal and native MCP forms include bounded previews in the prompt.

=head1 RULE FILES

Rules are evaluated in order, with the first match deciding. C<decision> is
C<allow>, C<deny> or C<ask>; omitted decisions are invalid. C<action> is the
server-defined action class, not the decision. A matcher beginning with C<^>
is interpreted as a Perl regular expression; otherwise it matches exactly.
Omitted C<match.NAME> fields do not restrict that dimension. For example:

   [rule]
   decision=allow
   action=read
   match.subject=^/home/example/documents/
   sandbox-grants=workdir-read

   [rule]
   decision=deny
   action=^

If any saved rule is invalid (including an obsolete pre-1.0 field), the
entire file is silently ignored and permissions are requested normally.
Reading does not modify the file; the next ordinary save replaces it,
discarding all old rules. Explicit saves do not validate rule semantics;
file I/O errors still fail normally.

An allow rule requires C<sandbox-grants>, which may be empty for actions
that need no worker grants. It matches only requests whose required grants
(including implied grants) are contained in the allowed closure. Omitted
C<sandbox-grants> on deny and ask rules matches any requested grants.
An explicit ask rule takes precedence over any later allow rules.
Deny rules may also specify an exact C<path> matched against any entry in
the request's C<paths> array and a human-readable C<message> included in
subsequent denial errors.
Neither field is permitted on allow rules. Exact-path denials apply even
when an operation requires additional sandbox grants for other files.
File paths are lexical strings, not a sandbox or inode identity.
With no matching rule the user is asked.

An optional C<expires> field is an unsigned integer Unix timestamp. Rules
with C<expires> at or before the current time are removed from the returned
list on every read, before matching. Omit it for indefinite rules. Reads do
not rewrite the file; the next ordinary save removes expired entries from
disk. Permission prompts offer indefinite (the default), 900 seconds or
16 hours. Expiry does not interrupt operations already authorized.

Decisions received after asynchronous prompting are rechecked against the
current policy. Persistent answers are appended. Rule files are private,
updates use locking and atomic rename, and failed persistence is reported as
a failed grant rather than a successful permanent authorization.

=head1 METHODS

=over

=item $permissions = AnyEvent::MCP::Server::Permissions->new (%config)

Creates a permission engine. It does not enforce worker isolation.
Options are:

=over

=item actions => { $action => $description, ... }

Maps action names to descriptions, defaulting to an empty hash. When
nonempty, unknown actions are rejected.

=item sandbox_grants => { $grant => [$implied_grant...], ... }

Defines grant names and their implications, defaulting to an empty hash.
Every requested or implied grant must be declared.

=item sandbox_grant_descriptions => { $grant => $description, ... }

=item sandbox_grant_descriptions => $callback->($request)

Optional display descriptions. The callback returns a description hash
reference. These labels come from the server; request-supplied overrides
are ignored.

=item sandbox_implementation => $description

Optional display label, such as C<bubblewrap>. It does not select or
construct an enforcement mechanism.

=item rules => [$rule...]

Ordered in-memory rule hashes, defaulting to an empty array.
See L</RULE FILES> for their fields.

=item file => $file

UTF-8 rule file. When supplied, rules are read from this file on permission
checks. A missing file supplies an empty rule list.

=item name => $name

Optional name used for display and, when C<file> is omitted, the default
filename C<$XDG_CONFIG_HOME/anyevent-mcp/rules/NAME.ini>, or
C<$HOME/.config/anyevent-mcp/rules/NAME.ini>. Without a name or file,
policy stays in memory. Applications can supply a different C<file>;
C<mcp-fs> uses C<anyevent-mcp/rules/fs-NAME.ini>.

=item ask => $method

C<helper>, C<tty>, C<yad>, C<auto> or C<mcp>. When omitted, uses
C<PERL_ANYEVENT_MCP_PERMISSION_ASK>, defaulting to C<helper>.
C<helper> prompts locally using the configured helper. C<tty> and C<yad>
run the built-in permission helper with only that interface, ignoring custom
helper settings and without interface fallback. C<auto> uses modern MCP form elicitation when
advertised for the request, otherwise the helper. C<mcp> requires modern
form elicitation and fails when unavailable. A declined prompt never
falls back to a different approval mechanism.

=item ask => $callback->($prepared, $done->($success, $decision))

Local asynchronous asking callback. C<$prepared> is the prepared request;
C<$done> receives a decision hash on success or an error on failure.
Callback success means a decision was obtained, not that access was granted.

=item helper => $executable

=item helper => [$executable, $arg...]

External helper, not a shell command. Defaults to
C<PERL_ANYEVENT_MCP_PERMISSION_HELPER> or C<anyevent-mcp-askpermission>.

=item timeout => $seconds

External helper timeout, defaulting to 300 seconds. Also determines the
lifetime of each modern permission continuation. Use a positive value;
zero makes continuations expire immediately, while the helper treats
zero as its default timeout.

=item auto_rules => $rules

Ordered process-local permission rules, each C<[DECISION, SPEC]> where
C<DECISION> is C<allow> or C<deny> and C<SPEC> is
C<TOOL[,ACTION[,CAPABILITY]]>. Each field is an exact name or C<*>
(any); omitted trailing fields mean C<*>. Tool names treat underscores
and hyphens alike. A named capability must be known to this server.
Allow matches when all requested grants are implied by the specified
capability; deny matches when the requested grants imply that capability.
C<*> matches any capability set in either direction. First match wins,
before saved rules and prompting. Only tools which call the permission
engine are affected. Automatic allowance grants exactly the requested
sandbox grants; tool validation and sandbox enforcement still apply.

=back

=item $grant = $permissions->check ($request, $tool)

C<$request> contains C<action>, C<reason>, and C<sandbox_grants> (an array
reference; it may be empty). C<tool> in the request is optional display
context. The separate optional C<$tool> argument is the trusted dispatched
MCP tool name for automatic overrides; Server supplies it from the call.
C<dimensions> is an optional hash of independent, named identities. Every
dimension has a display C<label>, a nonempty C<value>, and an array of
permitted persistent C<choices>, each with C<label> and C<match>. For example:

   dimensions => {
      origin => {
         label => "Origin",
         value => "https://example.org:8443",
         default => "https://example.org:8443",
         choices => [
            { label => "This origin", match => "https://example.org:8443" },
            { label => "Any origin", match => "^" },
         ],
      },
   }

C<default> optionally selects the initially proposed matcher for persistent
rule prompts; it must be one of the offered choices. Without it, the first
choice is selected.
The engine does not interpret dimension names. Saved rules use
C<match.origin>, C<match.subject>, C<match.workdir>, or any other
C<match.NAME>. Every selected matcher must match the corresponding request
value. A saved matcher for a missing dimension does not match. An omitted
C<match.NAME> in a manually written rule matches any value, including absent
dimensions; persistent prompts instead require a choice for every dimension.
An empty choices array disables permanent approvals, not one-time approvals.
Matchers are literal unless beginning with C<^>, which denotes a Perl regex.
The caller must supply trustworthy dimension values, not untrusted tool arguments.
The former C<subject>, C<subjects>, C<origin>, C<origins>, and C<workdir>
request and saved-rule fields are unsupported.
The multibroker alias, when supplied by the child's environment, is display-only
and does not change rule matching or policy file selection.
C<paths> may contain a list of affected filenames for display in permission
prompts and for optional B<deny-only> exact-file rules. Such matching does
not restrict sandbox authority and is not a substitute for sandboxing.
Absent a C<path> matcher, the permission rule is not limited by paths.

Returns C<{decision =E<gt> "allow", sandbox_grants =E<gt> [...]}>,
C<{decision =E<gt> "deny", sandbox_grants =E<gt> []}>, or
C<{decision =E<gt> "ask", request =E<gt> $prepared}>.
Denials can also include a saved C<message>. C<check> does not prompt or
execute the operation.

=item $grant = $permissions->resolve ($request, $approval)

C<$request> is the original permission request. C<$approval> is
C<{ request =E<gt> $prepared, decision =E<gt> $decision }>, where
C<$prepared> is the request returned by C<check> and C<$decision> is the
helper's decision hash. Resolves the answer to that prepared request. Approval decisions are
C<allow-once>, C<allow-always>, C<deny-once>, and C<deny-always>.
Allow-once uses exactly the requested sandbox grants. Allow-always may save
a broader or narrower set of grants for future invocations; the present
invocation still receives no more than requested. Permanent decisions
contain a validated rule restricted to the offered action and dimension scopes.
Denial decisions may include an optional human C<message>; allowed tool
results are never modified by permission prompting.

This is a trusted application interface. Do not pass unauthenticated client
metadata directly to it.

=item $grant = $permissions->require_permission ($req, { %request })

Synchronous interface used by C<< $req->require_permission >>. Returns
the granted sandbox-grant array, dies on denial, or throws a permission-needed
exception for the server to handle. The worker must enforce the returned grants;
never treat merely requested grants as sufficient.

=item $permissions->require ($req, $request, $done->($success, $grant))

Asynchronous interface. C<$grant> is the allowed sandbox-grant array or an
error. Check before starting side effects.

With a local prompt, C<$done> runs when permission is resolved. Modern
MCP prompting instead completes C<$req> with C<input_required> without
calling C<$done>; the client repeats the call with input. Original
callbacks are not retained.
Continuations are short-lived and bound to the method, parameters, and request,
and are consumed once. Approval retries retain earlier one-time grants
within the same call. Always decisions and Back use additional protected C<input_required>
rounds, capped at 32, without executing the original tool. Messages in
persistent deny rules are returned to subsequent callers, including later
sessions. Client-side elicitation is only appropriate when the connected
client is the trusted approval authority.

=item $closure = $permissions->closure ([$grant...])

Returns a hash reference whose keys contain the supplied sandbox grants
and all grants they imply. Unknown grants or malformed implication lists
die. This expands authority names; it does not grant permission.

=item $permissions->auto_rules ($rules)

Replace the ordered process-local rule chain. Parsing and validation
occur once, at installation. An empty list disables automatic rules.

=item $rules = $permissions->rules

Returns the ordered, uncompiled in-memory or file-backed rule array reference.
File-backed rules are reread, so changes apply to subsequent checks.

=item $permissions->save ($rules)

Replaces the ordered rules without semantic validation, using atomic file
replacement if backed by a file.

=back

=cut

package AnyEvent::MCP::Server::Permissions;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent ();
use AnyEvent::MCP::Permissions::Ask ();
use JSON::XS ();
use AnyEvent::MCP::File ();
use Errno qw(ENOENT);
use Scalar::Util qw(weaken);

our @ISA = qw(AnyEvent::MCP::Base);

sub new {
   my ($class, %kv) = @_;

   my $auto_rules = delete $kv{auto_rules} || [];
   my $ask = exists $kv{ask} ? $kv{ask} : $ENV{PERL_ANYEVENT_MCP_PERMISSION_ASK};
   $ask = "helper" unless defined $ask && length $ask;
   die "Invalid permission ask mode (expected helper, tty, yad, auto, or mcp)\n"
      unless ref $ask eq "CODE" || !ref $ask && $ask =~ /\A(?:helper|tty|yad|auto|mcp)\z/;

   my $self = $class->SUPER::new (sandbox_grants => {}, actions => {}, rules => [], ask => $ask, timeout => 300, %kv);

   if (!exists $kv{file} && defined $kv{name}) {
      my $name = AnyEvent::MCP::utf8enc $kv{name};
      $name =~ s/([^A-Za-z0-9_.-])/sprintf "%%%02X", ord $1/ge;
      my $dir = $ENV{XDG_CONFIG_HOME} || ($ENV{HOME} || die "HOME is not set\n") . "/.config";
      $self->{file} = "$dir/anyevent-mcp/rules/$name.ini";
   }

   $self->closure ([keys %{$self->{sandbox_grants}}]);
   $self->_rule ($_) for @{$self->rules};
   $self->auto_rules ($auto_rules);
   $self
}

sub auto_rules {
   my ($self, $rules) = @_;

   ref $rules eq "ARRAY" or die "Automatic permission rules must be an array\n";
   my @compiled;
   for my $entry (@$rules) {
      ref $entry eq "ARRAY" && @$entry == 2
         && defined $entry->[0] && !ref $entry->[0] && $entry->[0] =~ /\A(?:allow|deny)\z/
         && defined $entry->[1] && !ref $entry->[1]
         or die "Invalid automatic permission rule\n";
      my @parts = split /,/, $entry->[1], -1;
      @parts && @parts <= 3 && !grep { !length || ($_ ne "*" && /[\s*]/) } @parts
         or die "Invalid automatic permission rule '$entry->[1]'\n";
      my ($tool, $action, $capability) = (@parts, ("*") x (3 - @parts));
      $tool =~ y/_/-/;
      push @compiled, {
         decision   => $entry->[0],
         tool       => $tool,
         action     => $action,
         capability => $capability,
         closure    => $capability eq "*" ? undef : $self->closure ([$capability]),
      };
   }
   $self->{auto_rules} = \@compiled;
}

sub closure {
   my ($self, $sandbox_grants) = @_;

   ref $sandbox_grants eq "ARRAY"
      or die "Sandbox grants must be an array\n";

   my %set;

   my @todo = @$sandbox_grants;

   while (@todo) {
      my $capability = pop @todo;

      defined $capability && !ref $capability
         && ref $self->{sandbox_grants}{$capability} eq "ARRAY"
         or die "Unknown sandbox grant\n";

      next if $set{$capability}++;
      push @todo, @{$self->{sandbox_grants}{$capability}};
   }

   \%set
}

sub _regex {
   my ($pattern) = @_;

   defined $pattern && !ref $pattern
      or die "Permission matcher must be a string\n";

   $pattern =~ /\A\^/ ? qr/$pattern/ : qr/\A\Q$pattern\E\z/
}

sub _rule {
   my ($self, $rule) = @_;

   ref $rule eq "HASH"
      or die "Invalid permission rule\n";
   !grep !/\A(?:decision|action|path|message|sandbox-grants|expires|match\.[a-z][a-z0-9_-]*)\z/, keys %$rule
      or die "Unknown permission rule field\n";

   die "Invalid permission rule expiry\n" if exists $rule->{expires}
      && (!defined $rule->{expires} || ref $rule->{expires} || $rule->{expires} !~ /\A[0-9]+\z/);

   my $decision = $rule->{decision};

   die "Invalid permission rule decision\n" unless defined $decision && $decision =~ /\A(?:allow|deny|ask)\z/;
   die "Only deny rules can have paths or messages\n"
      if $decision ne "deny" && (exists $rule->{path} || exists $rule->{message});
   die "Allow rule needs sandbox-grants\n" if $decision eq "allow" && !exists $rule->{"sandbox-grants"};

   defined $rule->{action}
      or die "Permission rule needs action\n";

   my $compiled = { decision => $decision, action => _regex ($rule->{action}) };
   if (exists $rule->{path}) {
      die "Invalid exact denial path\n" if !defined $rule->{path}
         || ref $rule->{path} || !length $rule->{path};
      $compiled->{path} = $rule->{path};
   }
   my $message = $rule->{message};
   if (defined $message) {
      die "Invalid permission message\n" if ref $message
         || length $message > 2048 || $message =~ /[\r\n]/;
      $compiled->{message} = $message;
   }

   for my $key (grep /^match\./, keys %$rule) {
      (my $name = $key) =~ s/^match\.//;
      $compiled->{matches}{$name} = _regex ($rule->{$key});
   }


   if (exists $rule->{"sandbox-grants"}) {
      die "Invalid rule sandbox-grants\n" if ref $rule->{"sandbox-grants"};
      $compiled->{sandbox_grants} = $self->closure ([length $rule->{"sandbox-grants"}
         ? split /,/, $rule->{"sandbox-grants"}, -1 : ()]);
   }

   $compiled
}

sub rules {
   my ($self) = @_;

   my $now = time;

   [grep {
      die "Invalid permission rule expiry\n" if exists $_->{expires}
         && (!defined $_->{expires} || ref $_->{expires} || $_->{expires} !~ /\A[0-9]+\z/);
      !exists $_->{expires} || $_->{expires} > $now
   } @{$self->_read_rules}]
}

sub _read_rules {
   my ($self) = @_;

   return $self->{rules} unless defined $self->{file};

   open my $fh, "<", $self->{file} or do {
      return [] if $! == ENOENT;
      die "$self->{file}: $!\n";
   };

   local $/;
   my $text = scalar (<$fh>);
   close $fh or die "$self->{file}: $!\n";

   my @rules;
   my $valid = eval {
      $text = AnyEvent::MCP::utf8dec $text;
      AnyEvent::MCP::parse_ini $text, sub {
         my ($name, $kv) = @_;
         if ($name eq "") {
            %$kv and die "$self->{file}: permission rule outside [rule]\n";
         } elsif ($name eq "rule") {
            push @rules, $kv;
         } else {
            die "$self->{file}: invalid permission rule section '$name'\n";
         }
      }, $self->{file};
      $self->_rule ($_) for @rules;
      1
   };

   $valid ? \@rules : []

}

sub _write {
   my ($self, $rules) = @_;

   unless (defined $self->{file}) {
      $self->{rules} = $rules;
      return
   }

   my $text = join "", map {
      my $rule = $_;
      "[rule]\n" . (join "", map {
         die "Multiline permission rule value\n" if $rule->{$_} =~ /[\r\n]/;
         "$_=$rule->{$_}\n"
      } sort keys %$rule) . "\n"
   } @$rules;

   AnyEvent::MCP::File::replace $self->{file}, AnyEvent::MCP::utf8enc ($text);
}

sub _lock {
   my ($self) = @_;

   defined $self->{file} ? AnyEvent::MCP::File::lock ($self->{file}) : undef
}

sub save {
   my ($self, $rules) = @_;

   my $lock = $self->_lock;
   $self->_write ($rules);
}

sub check {
   my ($self, $request, $tool) = @_;

   my $need = $self->closure ($request->{sandbox_grants} // []);
   die "Permission action must be a string\n" unless defined $request->{action}
      && !ref $request->{action} && length $request->{action};
   die "Unknown permission action\n" if keys %{$self->{actions}}
      && !exists $self->{actions}{$request->{action}};
   die "Obsolete permission request scope\n"
      if grep exists $request->{$_}, qw(subject subjects origin origins workdir workdir_scope);
   my $dimensions = exists $request->{dimensions} ? $request->{dimensions} : {};
   ref $dimensions eq "HASH" or die "Invalid permission dimensions\n";
   for my $name (keys %$dimensions) {
      $name =~ /\A[a-z][a-z0-9_-]*\z/ or die "Invalid permission dimension name\n";
      my $dim = $dimensions->{$name};
      ref $dim eq "HASH" && defined $dim->{value} && !ref $dim->{value} && length $dim->{value}
         && defined $dim->{label} && !ref $dim->{label} && length $dim->{label}
         && ref $dim->{choices} eq "ARRAY"
         or die "Invalid permission dimension '$name'\n";
      for my $choice (@{$dim->{choices}}) {
         ref $choice eq "HASH" && defined $choice->{label} && !ref $choice->{label}
            && length $choice->{label} && defined $choice->{match}
            && $dim->{value} =~ _regex ($choice->{match})
            or die "Permission dimension scope does not match request\n";
      }
      if (exists $dim->{default}) {
         defined $dim->{default} && !ref $dim->{default}
            && (grep $_->{match} eq $dim->{default}, @{$dim->{choices}})
            or die "Permission dimension default was not offered\n";
      }
   }

   if (exists $request->{details}) {
      ref $request->{details} eq "HASH"
         or die "Permission details must be a hash\n";
      defined && !ref
         or die "Permission detail must be text\n"
         for values %{$request->{details}};
   }

   # Use the dispatched tool name, never the request's display label.
   my $tool_name = $tool // "";
   $tool_name =~ y/_/-/;
   for my $rule (@{$self->{auto_rules}}) {
      next if $rule->{tool} ne "*" && $rule->{tool} ne $tool_name;
      next if $rule->{action} ne "*" && $rule->{action} ne $request->{action};
      if ($rule->{capability} ne "*") {
         if ($rule->{decision} eq "allow") {
            next if grep !$rule->{closure}{$_}, keys %$need;
         } else {
            next unless $need->{$rule->{capability}};
         }
      }
      return {
         decision       => $rule->{decision},
         sandbox_grants => $rule->{decision} eq "allow" ? [@{$request->{sandbox_grants} || []}] : [],
      };
   }

   my @rules = map { $self->_rule ($_) } @{$self->rules};
   for my $rule (@rules) {
      next unless $request->{action} =~ $rule->{action};
      next if grep {
         !exists $dimensions->{$_} || $dimensions->{$_}{value} !~ $rule->{matches}{$_}
      } keys %{$rule->{matches} || {}};

      next if exists $rule->{path} && !(ref $request->{paths} eq "ARRAY"
         && grep defined && !ref && $_ eq $rule->{path}, @{$request->{paths}});
      # an exact-file denial applies even when a multi-path operation requests
      # additional sandbox authority for its other paths.
      next if !exists $rule->{path} && exists $rule->{sandbox_grants}
         && grep !$rule->{sandbox_grants}{$_}, keys %$need;

      return {
         decision       => $rule->{decision},
         sandbox_grants => $rule->{decision} eq "allow" ? [@{$request->{sandbox_grants} || []}] : [],
         ($rule->{decision} eq "deny" && defined $rule->{message} ? (message => $rule->{message}) : ()),
      } unless $rule->{decision} eq "ask";

      last
   }

   die "Permission request needs a reason\n" unless !ref $request->{reason} && $request->{reason} =~ /\S/;

   my $action_class = $request->{action};
   $action_class = "^\Q$action_class\E\\z" if $action_class =~ /\A\^/;

   my $descriptions = $self->{sandbox_grant_descriptions};
   $descriptions = $descriptions->($request) if ref $descriptions eq "CODE";
   die "Invalid sandbox grant descriptions\n"
      if defined $descriptions && ref $descriptions ne "HASH";

   {
      decision => "ask",
      request  => {
         %$request,
         sandbox_grants             => $request->{sandbox_grants} || [],
         version                    => 1,
         name                       => $self->{name},
         (length ($ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS} // "")
            ? (multibroker_alias => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS}) : ()),
         action_matcher             => $action_class,
         sandbox_grant_choices      => [sort keys %{$self->{sandbox_grants}}],
         sandbox_grant_descriptions => $descriptions || {},
         action_description         => $self->{actions}{$request->{action}},
         sandbox_implementation     => $self->{sandbox_implementation},
      }
   }
}

sub resolve {
   my ($self, $request, $approval, $tool) = @_;

   my $lock = $self->_lock;
   my $grant = $self->check ($request, $tool);

   return $grant unless $grant->{decision} eq "ask";

   my $json = JSON::XS->new->canonical;

   die "Permission approval does not match request\n" unless ref $approval eq "HASH"
      && $json->encode ($approval->{request}) eq $json->encode ($grant->{request});

   my $prepared = $grant->{request};
   my $decision = $approval->{decision};

   die "Invalid permission decision\n" unless ref $decision eq "HASH"
      && $decision->{decision} =~ /\A(?:allow|deny)-(?:once|always)\z/;

   my $allow = $decision->{decision} =~ /\Aallow-/;
   my $granted = [];

   if ($allow) {
      my $have = $self->closure ($prepared->{sandbox_grants});
      my $give = $self->closure ($decision->{sandbox_grants});
      my %choices = map { $_ => 1 } @{$prepared->{sandbox_grant_choices}};

      die "Unknown selected sandbox grant\n" if grep !$choices{$_}, @{$decision->{sandbox_grants}};
      $granted = [(grep !$give->{$_}, keys %$have)
         ? (grep $give->{$_}, sort keys %$have)
         : @{$prepared->{sandbox_grants}}];
   }

   if ($decision->{decision} =~ /-always\z/) {
      my $rule = $decision->{rule};
      $rule = { decision => "allow", %$rule } if $allow && ref $rule eq "HASH";
      my $action = $allow ? "allow" : "deny";

      # the rule contains only the selected dimensions, never extra authority.
      my %fields = map { $_ => 1 } qw(decision action sandbox-grants path message expires);
      $fields{"match.$_"} = 1 for keys %{$prepared->{dimensions} || {}};

      ref $rule eq "HASH"
         && $rule->{action} eq $prepared->{action_matcher}
         && ($rule->{decision} || "allow") eq $action
         && !grep !$fields{$_}, keys %$rule
         or die "Invalid persistent permission rule\n";

      die "Persistent permission sandbox-grants mismatch\n"
         unless defined $rule->{"sandbox-grants"} && $rule->{"sandbox-grants"} eq
            (join ",", @{$allow ? $decision->{sandbox_grants} : $prepared->{sandbox_grants}});

      for my $name (keys %{$prepared->{dimensions} || {}}) {
         my $key = "match.$name";
         die "Persistent dimension scope was not offered\n"
            unless defined $rule->{$key}
               && grep $_->{match} eq $rule->{$key},
                  @{$prepared->{dimensions}{$name}{choices}};
      }
      if (exists $rule->{path}) {
         die "Invalid persistent denial path\n" unless !$allow
            && ref $prepared->{paths} eq "ARRAY"
            && grep defined && !ref && $_ eq $rule->{path}, @{$prepared->{paths}};
      }
      die "Persistent denial message mismatch\n"
         unless (!$allow || !defined $decision->{message})
            && (defined $rule->{message} ? $rule->{message} : "")
               eq (defined $decision->{message} ? $decision->{message} : "");

      my $rules = $self->rules;
      push @$rules, { %$rule };
      $self->_write ($rules);
   }

   {
      decision       => $allow ? "allow" : "deny",
      sandbox_grants => $granted,
      (!$allow && defined $decision->{message} ? (message => $decision->{message}) : ()),
   }
}

sub _call {
   my ($req) = @_;

   my %params = %{$req->{params}};
   delete @params{qw(inputResponses requestState _meta)};
   # _meta is per-request context, not stable operation identity: retries can
   # carry different client capabilities, progress tokens and clientInfo.
   # bind the one-use token to the protocol version and semantic parameters.
   JSON::XS->new->canonical->encode ([$req->{protocol_version}, $req->{method}, \%params])
}

sub _remember {
   my ($self, $req, $request, $grant) = @_;

   my $key = JSON::XS->new->canonical->encode ($request);
   $req->{_permission_grants}{$key} = $grant;
}

sub denial_message {
   my ($grant) = @_;

   "Permission denied" . (defined $grant->{message} && length $grant->{message}
      ? ": $grant->{message}" : "")
}

sub _challenge {
   my ($self, $req, $request, $prepared, $grants, $stage, $rounds, $selection) = @_;

   return $req->error ("Too many permission rounds") if $rounds > 32;

   AE::log debug => "permission elicitation: challenge created (stage $stage)";
   my $state = "ae-mcp-permission:" . unpack "H*", AnyEvent::MCP::random_bytes 32;
   $self->{pending}{$state} = {
      call      => $req->{_permission_call} || _call ($req),
      request   => $request,
      prepared  => $prepared,
      grants    => { %{$grants || {}} },
      stage     => $stage,
      rounds    => $rounds,
      selection => $selection || {},
   };

   weaken $self;
   $self->{pending}{$state}{timer} = AnyEvent->timer (after => $self->{timeout}, cb => sub {
      if ($self && delete $self->{pending}{$state}) {
         AE::log debug => "permission elicitation: challenge expired (stage $stage)";
      }
   });

   $req->reply ({
      resultType    => "input_required",
      requestState  => $state,
      inputRequests => {
         permission => {
            method => "elicitation/create",
            params => {
               mode  => "form",
               _meta => {
                  "anyevent-mcp/permission" => {
                     version   => 1,
                     request   => $prepared,
                     stage     => $stage,
                     selection => $selection || {},
                  },
               },
               message => $stage eq "rule" ? "Configure the persistent permission rule.\n"
                     . (($selection->{decision} || "") eq "deny-always"
                        ? "Denial reason: " . ($selection->{message} // "(none)") . "\n" : "")
                     . AnyEvent::MCP::Permissions::Ask::message ($prepared, $stage)
                  : AnyEvent::MCP::Permissions::Ask::message ($prepared),
               requestedSchema => AnyEvent::MCP::Permissions::Ask::schema ($prepared, $stage, $selection),
            },
         },
      },
   });
}

sub _next_stage {
   my ($decision, $stage) = @_;

   return "rule" if $stage eq "choice" && $decision->{decision} =~ /-always\z/;
   return "choice" if $stage eq "rule" && $decision->{decision} eq "back";
   undef
}

sub _resume {
   my ($self, $req) = @_;

   return if $req->{_permission_resumed}++;

   $req->{_permission_call} = _call ($req);

   my $state = $req->{params}{requestState};
   return unless defined $state && $state =~ /\Aae-mcp-permission:/;

   my $pending = delete $self->{pending}{$state};
   AE::log debug => "permission elicitation: continuation has no pending challenge"
      unless $pending;
   AE::log debug => "permission elicitation: continuation request mismatch"
      if $pending && $pending->{call} ne $req->{_permission_call};
   die "Invalid or expired permission continuation\n"
      unless $pending && $pending->{call} eq $req->{_permission_call};

   my $response = $req->{params}{inputResponses}{permission};
   my $action = ref $response eq "HASH" && !ref $response->{action}
      && ($response->{action} // "") =~ /\A(?:accept|decline|cancel)\z/
      ? $response->{action} : "invalid";
   AE::log debug => "permission elicitation: continuation received (stage $pending->{stage}, action $action)";
   my $decision = AnyEvent::MCP::Permissions::Ask::decision
      $pending->{prepared}, $response, $pending->{stage}, $pending->{selection};
   if (my $next = _next_stage ($decision, $pending->{stage})) {
      $self->_challenge ($req, $pending->{request}, $pending->{prepared}, $pending->{grants},
         $next, ($pending->{rounds} || 1) + 1, { %{$pending->{selection} || {}}, %$decision });
      return
   }
   my $grant = $self->resolve ($pending->{request}, {
      request => $pending->{prepared}, decision => $decision,
   }, $req->{tool});

   die denial_message ($grant) . "\n" unless $grant->{decision} eq "allow";

   $req->{_permission_grants} = $pending->{grants};
   $self->_remember ($req, $pending->{request}, $grant->{sandbox_grants});
}

sub require_permission {
   my ($self, $req, $request) = @_;

   my $grant = $self->check ($request, $req->{tool});

   return $grant->{sandbox_grants} if $grant->{decision} eq "allow";

   if ($grant->{decision} eq "deny") {
      AE::log debug => "permission policy: denied";
      die denial_message ($grant) . "\n";
   }

   my $key = JSON::XS->new->canonical->encode ($request);

   return $req->{_permission_grants}{$key}
      if exists $req->{_permission_grants}{$key};

   die bless { request => $request }, "AnyEvent::MCP::Server::Permissions::Required";
}

sub require {
   my ($self, $req, $request, $done) = @_;

   my $grant = eval { $self->check ($request, $req->{tool}) };

   return $done->(0, "$@") if $@;

   if ($req->{_permission_resumed} && $grant->{decision} eq "ask") {
      my $key = JSON::XS->new->canonical->encode ($request);
      return $done->(1, $req->{_permission_grants}{$key})
         if exists $req->{_permission_grants}{$key};
   }

   my $state = $req->{params}{requestState};

   if (!$req->{_permission_resumed} && defined $state && $state =~ /\Aae-mcp-permission:/) {
      my $pending = delete $self->{pending}{$state};
      return $done->(0, "Invalid or expired permission continuation")
         unless $pending && $pending->{call} eq _call ($req)
            && JSON::XS->new->canonical->encode ($pending->{request}) eq JSON::XS->new->canonical->encode ($request);
      my $response = $req->{params}{inputResponses}{permission};
      my $decision = eval {
         AnyEvent::MCP::Permissions::Ask::decision
            $pending->{prepared}, $response, $pending->{stage}, $pending->{selection}
      };
      return $done->(0, "$@") if $@;
      if (my $next = _next_stage ($decision, $pending->{stage})) {
         $self->_challenge ($req, $pending->{request}, $pending->{prepared}, $pending->{grants},
            $next, ($pending->{rounds} || 1) + 1, { %{$pending->{selection} || {}}, %$decision });
         return
      }
      $grant = eval { $self->resolve ($request, { request => $pending->{prepared}, decision => $decision }, $req->{tool}) };
      return $done->(0, "$@") if $@;
   }

   return $done->(1, $grant->{sandbox_grants}) if $grant->{decision} eq "allow";
   if ($grant->{decision} eq "deny") {
      AE::log debug => "permission policy: denied";
      return $done->(0, denial_message ($grant));
   }

   my $prepared = $grant->{request};
   my $ask = $self->{ask};
   my $client_caps = $req->{params}{_meta}{"io.modelcontextprotocol/clientCapabilities"};
   my $mcp = $req->{protocol_version} ge "2026" && ref $client_caps eq "HASH"
      && ref $client_caps->{elicitation} eq "HASH"
      && (!keys %{$client_caps->{elicitation}} || ref $client_caps->{elicitation}{form} eq "HASH");

   if (!ref $ask && ($ask eq "mcp" || $ask eq "auto" && $mcp)) {
      return $done->(0, "MCP form elicitation is unavailable") unless $mcp;

      $self->_challenge ($req, $request, $prepared, $req->{_permission_grants},
         "choice", 1);
      return
   }

   weaken $self;

   my $finished;
   my $finish = sub {
      my ($success, $decision) = @_;

      return if !$self || $req->{finished};
      die "Permission prompt already finished\n" if $finished++;
      return $done->(0, $decision) unless $success;

      my $grant = eval { $self->resolve ($request, { request => $prepared, decision => $decision }, $req->{tool}) };

      return $done->(0, "$@") if $@;

      $done->($grant->{decision} eq "allow" ? (1, $grant->{sandbox_grants})
         : (0, denial_message ($grant)));
   };

   if (ref $ask eq "CODE") {
      $ask->($prepared, $finish);
   } else {
      die "Unknown permission asking method\n" unless $ask =~ /\A(?:auto|helper|tty|yad)\z/;

      my $job = AnyEvent::MCP::Permissions::Ask->new (
         helper => $ask eq "tty" || $ask eq "yad"
            ? ["anyevent-mcp-askpermission", "--$ask"] : $self->{helper},
         timeout => $self->{timeout},
      );

      my $old_cancel = $req->{on_cancel};
      $req->{on_cancel} = sub { $job->cancel; $old_cancel->(@_) if $old_cancel };
      $job->ask ($prepared, $finish);
   }
}

1
