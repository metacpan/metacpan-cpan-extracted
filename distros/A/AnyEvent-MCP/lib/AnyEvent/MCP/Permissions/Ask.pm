=head1 NAME

AnyEvent::MCP::Permissions::Ask - pluggable external permission prompts

=head1 DESCRIPTION

An MCP tool may need to ask a human for permission, but its server should not
have to know whether the answer comes from a terminal, a graphical dialog or
a desktop service. This module runs a separate permission helper so the
prompting mechanism can be changed without changing the tool.

The helper receives one UTF-8 JSON request on stdin, terminated by EOF,
and writes one JSON decision to stdout. C<helper> is an executable or an
argument array. C<timeout> limits elapsed time; C<max_size> limits output,
defaulting to 1 MiB. C<PERL_ANYEVENT_MCP_PERMISSION_HELPER> selects the
default executable.

C<ask ($prepared, $done)> calls C<$done-E<gt>($success, $decision)> once.
C<cancel> terminates the helper and completes with failure. Helpers are reaped
by AnyEvent::Util even after cancellation.

The default helper tries YAD, letting GTK select its display backend,
and asks on C</dev/tty> if YAD cannot start. If neither is available,
the request is denied rather than silently allowed. Applications can substitute a desktop-daemon client.
Rule management is available separately via C<anyevent-mcp manage-rules NAME>.

C<< AnyEvent::MCP::Permissions::Ask->elicitation ($req, %config) >> handles
a permission-tagged Client::Request with the external helper and replies to it.
Use this in the client's C<on_request> callback for local permission dialogs.
It preserves cancellation and validates the selected C<sandbox_grants>
and all named dimension scopes.

The functions C<schema>, C<message>, C<decision> and C<build> implement the
shared form/helper representation. The initial form offers allow/deny,
once/always, and an optional denial C<message>. Persistent choices are omitted
if any requested dimension has no available persistent scope. Approval never
attaches that message to a successful tool result. Only the C<always>
choices lead to a second form for persistent rule grants, scopes and lifetime;
C<back> returns to the first form. The local graphical helper can
complete this two-screen flow without a network round-trip; the terminal
helper offers a C<m> shortcut to edit the denial reason. Decisions are
validated again by the permission engine before use.

The typical place to use C<elicitation> is in an
L<AnyEvent::MCP::Client/on_request> callback:

   on_request => sub {
      my ($client, $req) = @_;
      AnyEvent::MCP::Permissions::Ask->elicitation ($req);
   },

Load this module before using the callback. It handles
permission-tagged requests; the application must route or reject
unrelated form requests. The server-side authorization logic lives in
L<AnyEvent::MCP::Server::Permissions>.

=head1 METHODS

=over

=item $ask = AnyEvent::MCP::Permissions::Ask->new (%config)

Create a helper runner with these options:

=over

=item helper => $executable

=item helper => [$executable, $arg...]

Executable or argument array, not a shell command. Defaults to
C<PERL_ANYEVENT_MCP_PERMISSION_HELPER> or C<anyevent-mcp-askpermission>.

=item timeout => $seconds

Maximum elapsed time for a prompt, defaulting to 300 seconds. Zero
also selects the default; it does not disable the timer.

=item max_size => $bytes

Maximum helper output size, defaulting to 1 MiB.

=back

=item $ask->ask ($prepared, $done->($success, $decision))

Send a prepared permission request to the external helper. C<$done> receives
the decoded decision hash on successful completion, or an error message
when C<$success> is false. Process success does not mean permission was
granted: the permission engine validates the decision separately.
Only one request may be active per runner.

=item $ask->cancel ($reason)

Terminate an active helper, completing its callback with failure.
C<$reason> is optional. The child is reaped asynchronously.

=item $job = AnyEvent::MCP::Permissions::Ask->elicitation ($req, %config)

Handle a permission-tagged C<elicitation/create> Client::Request using the
local helper. C<%config> is passed to the runner constructor. Cancellation
of C<$req> cancels the helper. Other elicitation requests are rejected.

=back

=head1 FORM UTILITIES

These functions are called with fully qualified names, not as methods.
C<$prepared> is the prepared request returned by the permission engine.
C<$stage> is C<choice> for the initial form or C<rule> for persistent rule
details. C<$previous> holds the selection from the preceding form.

=over

=item $schema = AnyEvent::MCP::Permissions::Ask::schema $prepared, $stage, $previous

Returns the JSON Schema hash reference for the selected form stage.

=item $text = AnyEvent::MCP::Permissions::Ask::message $prepared, $stage

Formats the request and, for the rule stage, available grants and scopes
as readable text.

=item $text = AnyEvent::MCP::Permissions::Ask::detail_text $label, $text

Formats one display-only detail with its size and a preview of at most
65536 Unicode characters. Control and bidi characters are visibly escaped;
tabs and newlines are preserved. Longer text carries an explicit warning.

=item $decision = AnyEvent::MCP::Permissions::Ask::build $prepared, $answer, $stage, $previous

Validates an answer hash and constructs a decision hash. An initial
always choice selects the next stage; the rule stage completes it or
returns C<back>. Grant selections here are arrays, unlike the
comma-separated grant string in the native MCP form. Persistent answers may
select C<lifetime>: C<indefinite> (the default), C<900> or C<57600>, all
strings. A finite lifetime produces an absolute C<expires> Unix timestamp
in the rule; the selected lifetime is retained when forwarding native forms.
Each named dimension is selected as C<dim_NAME> from the matchers offered in
C<dimensions-E<gt>{NAME}{choices}>; the rule saves it as C<match.NAME>.

=item $decision = AnyEvent::MCP::Permissions::Ask::decision $prepared, $response, $stage, $previous

Converts the MCP elicitation response hash to a decision, including
decoding its grant string. A declined or cancelled form becomes deny-once.
Invalid answers die. The permission engine still validates and resolves
the decision against its current policy.

=back

=cut

package AnyEvent::MCP::Permissions::Ask;

use common::sense;
use AnyEvent::MCP ();
use AnyEvent ();
use JSON::XS ();
use parent "AnyEvent::MCP::Helper";

sub schema {
   my ($request, $stage, $previous) = @_;

   $previous ||= {};
   my $persistent = !grep !@{$_->{choices}}, values %{$request->{dimensions} || {}};

   if ($stage && $stage eq "rule") {
      my $chosen = $previous->{decision};
      die "Invalid persistent decision\n" unless $persistent
         && $chosen =~ /\A(?:allow|deny)-always\z/;
      my $allow = $chosen =~ /\Aallow/;
      my $schema = {
         type       => "object",
         required   => ["decision"],
         properties => {
            lifetime => {
               type    => "string",
               enum    => ["indefinite", "900", "57600"],
               default => "indefinite",
               title   => "Rule lifetime (indefinite, 900 seconds, or 57600 seconds / 16 hours)",
            },
            decision => {
               type    => "string",
               enum    => ["back", $chosen],
               default => $chosen,
               title   => "Save rule or go back",
            },
         },
      };
      if ($allow) {
         $schema->{properties}{sandbox_grants} = {
            type    => "string",
            default => join (",", @{$request->{sandbox_grants}}),
            title   => "Allowed sandbox grants (comma-separated; empty for none)",
         };
      } else {
         my @paths = grep defined && !ref, @{$request->{paths} || []};
         $schema->{properties}{path} = {
            type    => "string",
            title   => "Deny-always file scope (empty means all paths)",
            enum    => ["", @paths],
            default => $paths[0],
         } if @paths;
      }
      for my $name (sort keys %{$request->{dimensions} || {}}) {
         my $dim = $request->{dimensions}{$name};
         $schema->{properties}{"dim_$name"} = {
            type    => "string",
            title   => "$dim->{label} scope",
            enum    => [map $_->{match}, @{$dim->{choices}}],
            default => $dim->{default} // $dim->{choices}[0]{match},
         };
      }
      return $schema
   }

   my @decisions = qw(allow-once deny-once);
   push @decisions, qw(allow-always deny-always) if $persistent;
   {
      type       => "object",
      required   => ["decision"],
      properties => {
         message => {
            type      => "string",
            title     => "Reason if denied (optional)",
            maxLength => 2048,
            default   => $previous->{message} // "",
         },
         decision => {
            type    => "string",
            enum    => \@decisions,
            default => "deny-once",
            title   => "Decision",
         },
      },
   }
}

sub message {
   my ($request, $stage) = @_;

   my $json = JSON::XS->new;
   my %label = (
      name                   => "Server",
      multibroker_alias      => "Multibroker alias",
      tool                   => "Tool",
      action                 => "Action",
      action_description     => "Action description",
      sandbox_implementation => "Sandbox",
      paths                  => "Paths",
   );

   my $reason = $request->{reason};
   $reason =~ s/([\x00-\x08\x0b-\x1f\x7f-\x9f\x{202a}-\x{202e}\x{2066}-\x{2069}])/sprintf "\\u{%X}", ord $1/ge
      if defined $reason;

   join "\n",
      "Permission request",
      "Requested sandbox grants: " . join (", ", @{$request->{sandbox_grants}}),
      (map { "$label{$_}: " . $json->encode ($request->{$_}) }
         grep defined $request->{$_},
            qw(name multibroker_alias tool action action_description sandbox_implementation paths)),
      (defined $reason ? "Reason: $reason" : ()),
      (map {
         my $dim = $request->{dimensions}{$_};
         "$dim->{label}: " . $json->encode ($dim->{value})
      } sort keys %{$request->{dimensions} || {}}),
      (map { detail_text ($_, $request->{details}{$_}) } sort keys %{$request->{details} || {}}),
      ($stage && $stage eq "rule" ? (
         "Available sandbox grants:",
         (map {
            my $description = $request->{sandbox_grant_descriptions}{$_};
            "  $_" . (defined $description && length $description ? " - $description" : "")
         } @{$request->{sandbox_grant_choices}}),
         (map {
            my $dim = $request->{dimensions}{$_};
            map { "  " . $json->encode ($_->{label}) . ": " . $json->encode ($_->{match}) }
               @{$dim->{choices}}
         } sort keys %{$request->{dimensions} || {}})
      ) : ())
}

sub detail_text {
   my ($label, $text) = @_;

   defined $text && !ref $text
      or die "Invalid permission detail\n";

   my $chars = length $text;
   my $bytes = length AnyEvent::MCP::utf8enc $text;
   my $truncated = $chars > 65536;
   $text = substr $text, 0, 65536;
   $text =~ s/([\x00-\x08\x0b-\x1f\x7f-\x9f\x{202a}-\x{202e}\x{2066}-\x{2069}])/sprintf "\\u{%X}", ord $1/ge;
   $label =~ s/([\x00-\x1f\x7f-\x9f\x{202a}-\x{202e}\x{2066}-\x{2069}])/sprintf "\\u{%X}", ord $1/ge;

   "$label: $chars characters, $bytes UTF-8 bytes\n\n"
      . ($truncated ? "WARNING: INCOMPLETE PREVIEW. Additional text is not shown here.\n\n" : "")
      . $text
}

sub build {
   my ($prepared, $answer, $stage, $previous) = @_;

   $previous ||= {};
   die "Invalid permission answer\n" unless ref $answer eq "HASH"
      && defined $answer->{decision} && !ref $answer->{decision};

   my $choice = $answer->{decision};
   if ($stage && $stage eq "rule") {
      return { decision => "back" } if $choice eq "back";
      die "Invalid rule decision\n" unless $choice eq ($previous->{decision} // "")
         && $choice =~ /-always\z/;
   } else {
      die "Invalid permission decision\n"
         unless $choice =~ /\A(?:allow|deny)-(?:once|always)\z/;
   }

   my $message = $choice =~ /\Adeny-/ ? ($stage && $stage eq "rule"
      ? $previous->{message} : $answer->{message}) : undef;
   if (defined $message) {
      die "Invalid permission message\n" if ref $message || length $message > 2048
         || $message =~ /[\r\n]/;
      undef $message unless $message =~ /\S/;
   }

   # a native MCP "always" choice opens a second form for rule details.
   if ($stage && $stage eq "choice" && $choice =~ /-always\z/) {
      return { decision => $choice, (defined $message ? (message => $message) : ()) };
   }

   my $allow = $choice =~ /\Aallow-/;
   my $decision = { decision => $choice, (defined $message ? (message => $message) : ()) };
   if ($allow) {
      my $grants = $answer->{sandbox_grants};
      $grants = $prepared->{sandbox_grants} if !defined $grants && $choice eq "allow-once";
      die "Permission answer needs sandbox grants\n" unless ref $grants eq "ARRAY";
      my %available = map { $_ => 1 } @{$prepared->{sandbox_grant_choices}};
      die "Unknown selected sandbox grant\n" if grep !$available{$_}, @$grants;
      $decision->{sandbox_grants} = [@$grants];
   }

   if ($choice =~ /-always\z/) {
      my $rule = $decision->{rule} = {
         decision         => $allow ? "allow" : "deny",
         action           => $prepared->{action_matcher},
         "sandbox-grants" => join (",", @{$allow ? $decision->{sandbox_grants} : $prepared->{sandbox_grants}}),
      };
      my $lifetime = exists $answer->{lifetime} ? $answer->{lifetime} : "indefinite";
      defined $lifetime && !ref $lifetime && $lifetime =~ /\A(?:indefinite|900|57600)\z/
         or die "Invalid permission rule lifetime\n";
      $decision->{lifetime} = $lifetime;
      $rule->{expires} = time + $lifetime unless $lifetime eq "indefinite";
      for my $name (keys %{$prepared->{dimensions} || {}}) {
         my $dim = $prepared->{dimensions}{$name};
         my $selected = $answer->{"dim_$name"};
         die "Persistent dimension scope was not offered\n"
            unless defined $selected && !ref $selected
               && grep $_->{match} eq $selected, @{$dim->{choices}};
         $rule->{"match.$name"} = $selected;
      }
      if (!$allow && defined $answer->{path} && length $answer->{path}) {
         die "Unrequested denial path\n"
            unless !ref $answer->{path}
               && grep !ref $_ && $_ eq $answer->{path}, @{$prepared->{paths} || []};
         $rule->{path} = $answer->{path};
      }
      $rule->{message} = $message if !$allow && defined $message;
   }
   $decision
}

sub decision {
   my ($prepared, $response, $stage, $previous) = @_;

   die "Invalid elicitation response\n" unless ref $response eq "HASH";
   return { decision => "deny-once" } if $response->{action} eq "decline" || $response->{action} eq "cancel";
   die "Invalid elicitation action\n" unless $response->{action} eq "accept" && ref $response->{content} eq "HASH";
   my %answer = %{$response->{content}};
   if ($answer{decision} =~ /\Aallow-/ && defined $answer{sandbox_grants}) {
      die "Invalid sandbox-grants answer\n" if ref $answer{sandbox_grants};
      $answer{sandbox_grants} = [length $answer{sandbox_grants}
         ? split /\s*,\s*/, $answer{sandbox_grants}, -1 : ()];
   }
   build ($prepared, \%answer, $stage, $previous)
}

sub elicitation {
   my ($class, $req, %kv) = @_;

   my $meta = $req->{params}{_meta}{"anyevent-mcp/permission"};
   die "Not a permission elicitation\n" unless $req->{method} eq "elicitation/create"
      && ref $meta eq "HASH" && $meta->{version} == 1 && ref $meta->{request} eq "HASH";
   my $stage = $meta->{stage};
   my $job = $class->new (%kv);
   my $old_cancel = $req->{on_cancel};
   $req->{on_cancel} = sub { $job->cancel; $old_cancel->(@_) if $old_cancel };
   $job->ask ({
      %{$meta->{request}},
      _permission_stage     => $stage,
      _permission_selection => $meta->{selection} || {},
   }, sub {
      my ($success, $decision) = @_;

      return if $req->{finished};
      return $req->error (-32603, $decision) unless $success;
      my $valid = eval {
         build ($meta->{request}, {
            %$decision,
            (ref $decision->{rule} eq "HASH"
               ? (map { $_ => $decision->{rule}{$_} } qw(path)) : ()),
            (ref $decision->{rule} eq "HASH"
               ? (map { (my $key = $_) =~ s/^match\./dim_/; $key => $decision->{rule}{$_} }
                  grep /^match\./, keys %{$decision->{rule}}) : ()),
         }, $stage, $meta->{selection});
      };
      return $req->error (-32603, "Invalid permission helper decision: $@") if $@;
      $req->reply ({
         action  => "accept",
         content => {
            decision => $valid->{decision},
            (exists $valid->{lifetime} ? (lifetime => $valid->{lifetime}) : ()),
            (defined $valid->{message} ? (message => $valid->{message}) : ()),
            (ref $valid->{rule} eq "HASH" && defined $valid->{rule}{path}
               ? (path => $valid->{rule}{path}) : ()),
            (exists $valid->{sandbox_grants} ? (sandbox_grants => join (",", @{$valid->{sandbox_grants}})) : ()),
            (ref $valid->{rule} eq "HASH"
               ? (map { (my $key = $_) =~ s/^match\./dim_/; $key => $valid->{rule}{$_} }
                  grep /^match\./, keys %{$valid->{rule}}) : ()),
         },
      });
   });
   $job
}

sub ask {
   my ($self, $prepared, $done) = @_;

   my %input = %$prepared;
   delete $input{rules_file};
   local $self->{helper} = $self->{helper}
      || $ENV{PERL_ANYEVENT_MCP_PERMISSION_HELPER} || "anyevent-mcp-askpermission";
   $self->SUPER::ask (\%input, $done);
}

1
