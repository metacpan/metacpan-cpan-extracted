use common::sense;
use Test::More;
use AnyEvent::Util ();
use AnyEvent::MCP ();
use File::Temp ();
use JSON::XS ();
use POSIX ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
my $json = JSON::XS->new->canonical;
sub write_file {
   my ($path, $text) = @_;
   open my $fh, ">", $path or die "$path: $!";
   print {$fh} $text;
   close $fh or die "$path: $!";
}
write_file "$dir/yad", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
local $/;
open my $fh, "<", $ENV{MCP_TEST_FORM_QUEUE} or die $!;
my $queue = JSON::XS::decode_json <$fh>;
close $fh;
my $reply = shift @$queue or die "Unexpected form";
open $fh, ">", $ENV{MCP_TEST_FORM_QUEUE} or die $!;
print {$fh} JSON::XS::encode_json $queue;
close $fh;
utf8::decode ($_) for @ARGV;
open $fh, ">>", $ENV{MCP_TEST_FORM_LOG} or die $!;
print {$fh} JSON::XS::encode_json (\@ARGV), "\n";
close $fh;
my @fields = grep /\A--field=/, @ARGV;
my @quoted = map {
   my $value = $_;
   my $field = shift @fields;
   $value =~ s/([\x09\x0a\x5c])/chr (92) . (ord $1 == 10 ? "n" : ord $1 == 9 ? "t" : chr (92))/ge
      if $field =~ /:TXT\z/;
   $value =~ s/'/chr (39) . chr (92) . chr (39) . chr (39)/ge;
   "'$value'"
} @{$reply->{values} || []};
my $output = join " ", @quoted;
utf8::encode $output;
print $output, "\n";
exit $reply->{status};
};
chmod 0700, "$dir/yad" or die $!;
local $ENV{PATH} = "$dir:$ENV{PATH}";
local $ENV{MCP_TEST_FORM_QUEUE} = "$dir/queue";
local $ENV{MCP_TEST_FORM_LOG} = "$dir/log";

sub run_form {
   my ($params, $queue, @options) = @_;

   write_file "$dir/queue", $json->encode ($queue || []);
   my ($output, $error);
   my $status = AnyEvent::Util::run_cmd (
      [$^X, "-Ilib", "-MPOSIX", "-e",
         'defined POSIX::setsid () or die $!; do shift @ARGV; die $@ if $@;',
         "bin/anyevent-mcp-form-elicitation", @options],
      "<" => \(JSON::XS::encode_json $params), ">" => \$output, "2>" => \$error,
   )->recv;
   ($status, length $output ? JSON::XS::decode_json ($output) : undef, $error)
}
sub dialogs {
   open my $fh, "<", "$dir/log" or die $!;
   my @dialogs = map JSON::XS::decode_json ($_), <$fh>;
   close $fh;
   @dialogs
}

my $form = {
   mode => "form", message => "A real question\nwith a second line",
   requestedSchema => {
      type => "object", required => ["a_choice", "b_text", "c_number", "d_boolean"],
      properties => {
         a_choice => { type => "string", oneOf => [
            { const => "literal!\x1f\n", title => "Selected: !" },
            { const => "other", title => "Other" },
         ], default => "other" },
         b_text => { type => "string", title => "Answer:FBTN", default => "--command=not-an-option", maxLength => 4096 },
         c_number => { type => "number", minimum => 0, maximum => 10, default => 5 },
         d_boolean => { type => "boolean", default => JSON::XS::false },
         e_optional => { type => "integer" },
      },
   },
};
my $text = "first line\nsecond 'quoted' \\ line\x1f\x{3c0}\tC:\\tmp\\maps literal \\n and \\t";
my ($status, $response, $error) = run_form ($form, [{
   status => 2, values => ["2", $text, "3.5", "3", ""],
}]);
is $status, 0, "form helper returns a valid response";
is $error, "", "successful form has no diagnostics";
is_deeply $response, {
   action => "accept", content => {
      a_choice => "literal!\x1f\n", b_text => $text, c_number => 3.5, d_boolean => JSON::XS::true,
   },
}, "values preserve enum identity, multiline Unicode, quotes, backslashes and separator characters";
ok JSON::XS::is_bool ($response->{content}{d_boolean}), "boolean answer retains its JSON type";
unlike $json->encode ($response), qr/"c_number":"3.5"/, "numeric answer is a JSON number";
{
   my ($args) = dialogs;
   ok +(grep $_ eq "--quoted-output", @$args), "form requests shell-quoted output";
   ok +(grep $_ eq "--field=Answer\\\\u{3A}FBTN *:TXT", @$args),
      "schema titles cannot select executable YAD field types";
   my ($separator) = grep $args->[$_] eq "--", 0 .. $#$args;
   ok defined $separator && $args->[$separator + 2] eq "--command=not-an-option",
      "initial values are positional data after the option terminator";
   like $args->[$separator + 1], qr/\^Other/, "enum default is selected by value";
}

($status, $response, $error) = run_form ($form, [{
   status => 2, values => ["2", $text, "3.5", "2", "7"],
}]);
is $status, 0, "integer and false boolean answers submit";
like $json->encode ($response), qr/"e_optional":7(?:,|})/,
   "validated integer remains a JSON number after integer and finite checks";
ok JSON::XS::is_bool ($response->{content}{d_boolean}) && !$response->{content}{d_boolean},
   "false remains a JSON boolean";
is $response->{content}{b_text}, $text, "YAD TXT escaping round-trips without altering literal escapes";
{
   my @dialogs = dialogs;
   my ($separator) = grep $dialogs[-1][$_] eq "--", 0 .. $#{$dialogs[-1]};
   (my $escaped = $form->{requestedSchema}{properties}{b_text}{default}) =~ s/\\/\\\\/g;
   is $dialogs[-1][$separator + 2], $escaped, "TXT defaults protect literal backslashes on input";
}

my $optional = { message => "Optional answers", requestedSchema => {
   type => "object", properties => {
      a_choice => { type => "string", enum => ["one", "two"] },
      b_boolean => { type => "boolean" },
      c_number => { type => "number" },
      d_text => { type => "string" },
   },
} };
($status, $response) = run_form ($optional, [{ status => 2, values => ["1", "1", "", ""] }]);
is_deeply $response, { action => "accept", content => { d_text => "" } },
   "unset optional choices, booleans and numbers are omitted; empty text is retained";

my $limited = { message => "At least two characters", requestedSchema => {
   type => "object", required => ["answer"],
   properties => { answer => { type => "string", minLength => 2, maxLength => 8 } },
} };
($status, $response) = run_form ($limited, [
   { status => 2, values => ["x"] }, { status => 2, values => ["fixed"] },
]);
is $response->{content}{answer}, "fixed", "invalid answer is corrected in a second dialog";

{
   my @dialogs = dialogs;
   like join ("\n", @{$dialogs[-1]}), qr/text is too short/, "correction dialog explains validation error";
   is $dialogs[-1][-1], "x", "correction retains the entered value";
}
my $retry_text = "one\nsecond\tliteral \\n";
($status, $response) = run_form ($limited, [
   { status => 2, values => [$retry_text] }, { status => 2, values => ["fixed"] },
]);
is $response->{content}{answer}, "fixed", "multiline invalid input can be corrected";
{
   my @dialogs = dialogs;
   (my $escaped = $retry_text) =~ s/\\/\\\\/g;
   is $dialogs[-1][-1], $escaped, "retry decodes TXT output before re-encoding the preserved input";
}
($status, $response) = run_form ($limited, [{ status => 4 }]);
is_deeply $response, { action => "decline" }, "Decline is a valid distinct response";
($status, $response) = run_form ($limited, [{ status => 252 }]);
is_deeply $response, { action => "cancel" }, "closing a dialog cancels without trying a terminal";
($status, $response) = run_form ($limited, [{ status => 6 }]);
is_deeply $response, { action => "cancel" }, "Cancel is distinct from decline";
($status, $response, $error) = run_form ($limited, [{ status => 1 }]);
ok $status && !defined $response && $error =~ /Neither YAD nor a terminal/,
   "YAD startup failure without a controlling terminal is a helper failure";
my @before = dialogs;
($status, $response, $error) = run_form ($limited, [], "--tty");
my @after = dialogs;
ok $status && !defined $response && @before == @after, "--tty bypasses YAD";

($status, $response, $error) = run_form ($limited, [{ status => 1 }], "--yad");
ok $status && !defined $response && $error =~ /YAD is unavailable/,
   "forced YAD startup failure does not try a terminal";
($status, $response) = run_form ($limited, [{ status => 4 }], "--yad");
is_deeply $response, { action => "decline" }, "forced YAD retains human decline";
($status, $response, $error) = run_form ($limited, [], "--tty", "--yad");
ok $status && !defined $response && $error =~ /mutually exclusive/,
   "conflicting explicit interfaces are rejected";

for my $schema (
   { type => "object", properties => { bad => { type => "array" } } },
   { type => "object", properties => { bad => { type => "string", format => "email" } } },
   { type => "object", properties => {}, required => ["missing"] },
   { type => "object", properties => { bad => { type => "string", enum => ["same", "same"] } } },
) {
   ($status, $response, $error) = run_form ({ message => "Unsupported", requestedSchema => $schema });
   ok $status && !defined $response, "unsupported or invalid form schema fails without inventing a response";
}
($status, $response) = run_form ({ mode => "url", message => "Not a form" });
ok $status && !defined $response, "URL elicitation is explicitly unsupported";

done_testing;
