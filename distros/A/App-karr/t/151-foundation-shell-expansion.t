use strict;
use warnings;

# Ticket #159. App::karr::Foundation::Runner::_run_command used to splice %ENV
# into the command string in Perl before handing it to /bin/sh -c:
#
#   $command =~ s/\$\{(\w+)\}/$ENV{$1} \/\/ ''/ge;
#   $command =~ s/\$(\w+)/$ENV{$1} \/\/ ''/ge;
#
# PROMPT, KARR_REPO and KARR_ROLE are exported into the child's environment
# anyway, so the shell could expand them itself -- and safely, because it does
# not rescan an expanded value for substitutions. Splicing first meant the shell
# parsed the *values*, with two consequences this file pins:
#
#   1. a prompt is board content written in Markdown, so its backtick spans and
#      $(...) ran as commands, in the board's own directory, and the agent then
#      received an instruction nobody wrote;
#   2. the substitution reached inside single quotes, where sh guarantees a
#      literal, so the output-shaping technique the foundation POD documents
#      (`... | jq -r '...'`) broke silently: awk '{print $2}' arrived at awk as
#      '{print }'.
#
# Both halves need a real fork and a real /bin/sh, so they go through
# _run_command rather than a unit test of a substitution that should not exist.

use Test::More;
use Path::Tiny qw( tempdir );

use App::karr::Foundation;

# _stream_to_terminal is pinned off: on a TTY the runner tees the agent's output
# to STDOUT, which under prove would be TAP.
my $f = App::karr::Foundation->new(
  _config_data        => {},
  _stream_to_terminal => 0,
);

subtest 'a prompt is data: backticks and $(...) in it are not executed' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  my $tick = $repo->child('RAN-BACKTICK');
  my $dollar = $repo->child('RAN-DOLLAR-PAREN');

  my $prompt = "Run `touch $tick` and \$(touch $dollar), keep it under \$500";

  my ( $code, $out ) = $f->_run_command(
    $repo,
    { prompt => $prompt, max_runtime => 60 },
    'printf "%s" "$PROMPT"',
  );

  is $code, 0, 'command ran';
  ok !$tick->exists,   'the backtick span was not executed';
  ok !$dollar->exists, 'the $(...) was not executed';
  is $out, $prompt,
    'the agent receives the prompt verbatim, $500 and all';
};

subtest q{single quotes protect $2: awk '{print $2}' reaches awk} => sub {
  my $repo = tempdir( CLEANUP => 1 );

  # POSIX awk; if this ever fails to *run*, check that awk exists before
  # reading it as a regression.
  my ( $code, $out ) = $f->_run_command(
    $repo,
    { max_runtime => 60 },
    q{echo "alpha beta" | awk '{print $2}'},
  );

  is $code, 0, 'command ran';
  is $out, "beta\n",
    'the single-quoted awk program is passed through untouched';
};

subtest 'the variables a template may reference all still expand' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  local $ENV{KARR_TEST_INHERITED} = 'from-parent';

  my ( $code, $out ) = $f->_run_command(
    $repo,
    { prompt => 'PROMPT-VALUE', max_runtime => 60 },
    'printf "%s|%s|%s|%s|[%s]"'
      . ' "$PROMPT" "${KARR_REPO}" "$KARR_ROLE"'
      . ' "$KARR_TEST_INHERITED" "$KARR_TEST_NEVER_SET"',
  );

  is $code, 0, 'command ran';
  is $out, "PROMPT-VALUE|$repo|agent|from-parent|[]",
    'PROMPT, ${VAR} braced form, KARR_ROLE, an inherited var; unset is empty';
};

subtest 'the synthesized claude command hands the prompt over as one argument'
  => sub {
  my $bin_dir = tempdir( CLEANUP => 1 );
  my $bin     = $bin_dir->child('fake-claude');
  $bin->spew_utf8( <<'SH' );
#!/bin/sh
printf 'argc=%s\n' "$#"
for a in "$@"; do printf 'arg=[%s]\n' "$a"; done
SH
  chmod 0755, "$bin" or die "chmod $bin: $!";

  my $repo = tempdir( CLEANUP => 1 );
  $repo->child('globbed.txt')->spew_utf8('x');   # something for * to catch
  my $ran = $repo->child('RAN');

  # Everything a Markdown prompt throws at a shell: a glob, a backtick span,
  # word-splitting whitespace, a metacharacter and an apostrophe.
  my $prompt = "Pick * next; run `touch $ran`, mind the spaces, don't quote";

  my $karr = {
    claude      => 1,
    claude_bin  => "$bin",
    prompt      => $prompt,
    max_runtime => 60,
  };

  my $cmd = $f->_agent_command( $repo, $karr );
  like $cmd, qr/-p "\$PROMPT"/,
    'the synthesized template quotes $PROMPT for the shell';

  my ( $code, $out ) = $f->_run_command( $repo, $karr, $cmd );

  is $code, 0, 'command ran';
  like $out, qr/^argc=6$/m,
    'six arguments: the prompt was neither word-split nor globbed';
  like $out, qr/\Qarg=[$prompt]\E/,
    'the prompt arrives as exactly one argument, verbatim';
  ok !$ran->exists, 'and its backtick span did not run';
};

subtest 'the START log line records the template handed to /bin/sh' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  my $cmd  = 'printf "%s" "$PROMPT" >/dev/null';

  $f->_run_command( $repo, { prompt => 'PROMPT-VALUE', max_runtime => 60 }, $cmd );

  my ($start) = grep { /START command=/ }
    split /\n/, $repo->child('.karr.log')->slurp_utf8;

  like $start, qr/\QSTART command=$cmd\E/,
    'the template is logged verbatim';
  unlike $start, qr/PROMPT-VALUE/,
    'not the substituted result: env values stay out of .karr.log';
};

done_testing;
