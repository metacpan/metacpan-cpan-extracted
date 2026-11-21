#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::More;

use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use App::Briefing;
use App::Briefing::CLI;
use BriefingTest qw(
  claude_agent
  claude_skill
  decode_json_output
  hook_payload
  repo_root
  run_cli
  sandbox
);
use JSON::MaybeXS qw( encode_json );
use Path::Tiny qw( path );

sub briefing_argv {
  return (
    $^X,
    '-I'.path(repo_root(), 'lib')->stringify,
    path(repo_root(), 'script', 'briefing')->stringify,
    @_,
  );
}

can_ok('App::Briefing::CLI', 'run');
ok(
  path(repo_root(), 't', '00-load.t')->is_file,
  'repo_root resolves the distribution root',
);

my $version_box = sandbox();
my $version = run_cli(
  sandbox => $version_box,
  argv    => [briefing_argv('--version')],
);
is($version->{exit_code}, 0, 'briefing --version exits zero');
is($version->{stderr}, '', 'briefing --version is quiet on stderr');
like(
  $version->{stdout},
  qr/\Q$App::Briefing::VERSION\E/,
  'briefing --version reports the loaded package version',
);

my $hook_box = sandbox();
claude_agent($hook_box, 'demo', 'cli-skill');
claude_skill($hook_box, 'cli-skill', "CLI SKILL BODY\n");
my $hook = run_cli(
  sandbox => $hook_box,
  argv    => [briefing_argv('hook')],
  input   => encode_json(hook_payload($hook_box)),
);
is($hook->{exit_code}, 0, 'briefing hook exits zero for a valid hook payload');
is($hook->{stderr}, '', 'briefing hook does not warn for a small complete briefing');
like(
  decode_json_output($hook->{stdout})->{hookSpecificOutput}{additionalContext},
  qr/CLI SKILL BODY/,
  'briefing hook emits the public hook JSON contract',
);

my $doctor_box = sandbox();
claude_agent($doctor_box, 'reviewer', 'missing-skill');
my $doctor = run_cli(
  sandbox => $doctor_box,
  argv    => [briefing_argv('doctor', '--cwd', $doctor_box->{cwd})],
);
is($doctor->{exit_code}, 1, 'briefing doctor exits one for a missing skill');
like($doctor->{stdout}, qr/reviewer/, 'briefing doctor identifies the broken agent');
like($doctor->{stdout}, qr/missing-skill/, 'briefing doctor identifies the missing skill');

my $notice_box = sandbox();
my $old_plugin_root = path(
  $notice_box->{home}, '.claude', 'plugins', 'cache', 'briefing', 'briefing', '0.1.0',
)->stringify;
my $notice = run_cli(
  sandbox => $notice_box,
  argv    => [briefing_argv('notice')],
  env     => { CLAUDE_PLUGIN_ROOT => $old_plugin_root },
);
is($notice->{exit_code}, 0, 'briefing notice exits zero');
like(
  decode_json_output($notice->{stdout})->{systemMessage},
  qr/Getty\/marketplace/,
  'briefing notice retains the marketplace notice contract',
);
my $notice_again = run_cli(
  sandbox => $notice_box,
  argv    => [briefing_argv('notice')],
  env     => { CLAUDE_PLUGIN_ROOT => $old_plugin_root },
);
is($notice_again->{stdout}, '', 'briefing notice records that it has already been shown');

# k20: `hook marketplace-notice` is the plugin's SessionStart entry for the one-time notice.
my $notice_text = "briefing is now also in the shared Getty marketplace, alongside the other "
  ."plugins: /plugin marketplace add Getty/marketplace \x{2014} then /plugin install "
  ."briefing\@getty. Your install from Getty/briefing keeps working and stays maintained, "
  ."so there is nothing you have to do.";

sub cache_root {
  my ( $box, $marketplace ) = @_;
  return path(
    $box->{home}, '.claude', 'plugins', 'cache', $marketplace, 'briefing', '0.1.0',
  )->stringify;
}

sub state_file {
  my ( $box ) = @_;
  return path($box->{home}, '.claude', '.briefing-marketplace-notice');
}

sub notice_text_of {
  my ( $run ) = @_;
  # A run without the notice must fail its assertion, not abort the file.
  my $output = eval { decode_json_output($run->{stdout}) };
  return defined $output ? $output->{systemMessage} : "(no JSON; stdout: $run->{stdout})";
}

# Both spellings behave alike: the hook is the plugin's entry, `notice` stays.
for my $words ( [qw( hook marketplace-notice )], ['notice'] ) {
  my $label = join ' ', @{$words};

  my $box = sandbox();
  my %env = ( CLAUDE_PLUGIN_ROOT => cache_root($box, 'briefing') );
  my $first = run_cli(
    sandbox => $box, argv => [briefing_argv(@{$words})], env => \%env,
  );
  is($first->{exit_code}, 0, "$label exits zero when it shows the notice");
  is($first->{stderr}, '', "$label keeps stderr empty when it shows the notice");
  is(notice_text_of($first), $notice_text, "$label prints the exact notice text");
  is(
    scalar( () = $first->{stdout} =~ /\n/g ), 1,
    "$label prints the notice as one JSON line",
  );
  is(
    scalar eval { state_file($box)->slurp_utf8 }, "briefing\n",
    "$label records the marketplace it saw",
  );
  my $second = run_cli(
    sandbox => $box, argv => [briefing_argv(@{$words})], env => \%env,
  );
  is_deeply(
    [ @{$second}{qw( stdout stderr exit_code )} ], [ '', '', 0 ],
    "$label is silent, exit zero, once the notice was shown",
  );

  my $shared = sandbox();
  my $getty = run_cli(
    sandbox => $shared, argv => [briefing_argv(@{$words})],
    env => { CLAUDE_PLUGIN_ROOT => cache_root($shared, 'getty') },
  );
  is_deeply(
    [ @{$getty}{qw( stdout stderr exit_code )} ], [ '', '', 0 ],
    "$label is silent for the getty marketplace",
  );
  ok(!state_file($shared)->exists, "$label leaves no state for the getty marketplace");

  my $bare = run_cli(sandbox => sandbox(), argv => [briefing_argv(@{$words})]);
  is_deeply(
    [ @{$bare}{qw( stdout stderr exit_code )} ], [ '', '', 0 ],
    "$label is silent without CLAUDE_PLUGIN_ROOT",
  );

  my $outside_box = sandbox();
  my $outside = run_cli(
    sandbox => $outside_box, argv => [briefing_argv(@{$words})],
    env => { CLAUDE_PLUGIN_ROOT => repo_root() },
  );
  is_deeply(
    [ @{$outside}{qw( stdout stderr exit_code )} ], [ '', '', 0 ],
    "$label is silent outside a plugin cache",
  );
  ok(!state_file($outside_box)->exists, "$label leaves no state outside a plugin cache");

  # An unreadable-for-writing state directory: saying it every session beats never.
  SKIP: {
    skip 'directory permissions do not bind this user or platform', 3
      if $^O eq 'MSWin32' || $> == 0;
    my $locked = sandbox();
    my $claude = path($locked->{home}, '.claude');
    $claude->mkpath;
    chmod 0500, $claude->stringify;
    my $run = run_cli(
      sandbox => $locked, argv => [briefing_argv(@{$words})],
      env => { CLAUDE_PLUGIN_ROOT => cache_root($locked, 'briefing') },
    );
    chmod 0700, $claude->stringify;
    is($run->{exit_code}, 0, "$label exits zero when the state cannot be written");
    is($run->{stderr}, '', "$label keeps stderr empty when the state cannot be written");
    is(notice_text_of($run), $notice_text, "$label still prints with an unwritable .claude");
  }
}

# The marketplace is read from CLAUDE_PLUGIN_ROOT as os.path.normpath reads it: "." is
# dropped and ".." folded, and a backslash separates only on Windows.
my @root_shapes = (
  # label, root, whether the notice is expected
  [ 'a dot before cache', sub { path($_[0]{home}, '.claude', 'plugins', '.', 'cache', 'briefing', 'briefing', '0.1.0')->stringify }, 1 ],
  [ 'a ".." that leaves a cache', sub { path($_[0]{home}, '.claude', 'plugins', 'cache', 'getty', '..', 'briefing', 'briefing', '0.1.0')->stringify }, 1 ],
  [ 'a ".." that enters the getty marketplace', sub { path($_[0]{home}, '.claude', 'plugins', 'cache', 'briefing', '..', 'getty', 'briefing', '0.1.0')->stringify }, 0 ],
  [ 'a ".." that removes cache itself', sub { path($_[0]{home}, '.claude', 'plugins', 'cache', '..', 'briefing', '0.1.0')->stringify }, 0 ],
  [ 'a ".." above the root', sub { '/../cache/briefing/briefing/0.1.0' }, 1 ],
  [ 'cache as the last component', sub { path($_[0]{home}, '.claude', 'plugins', 'cache')->stringify }, 0 ],
  [ 'a backslash path on POSIX', sub { '\\home\\x\\.claude\\plugins\\cache\\briefing\\briefing\\0.1.0' }, $^O eq 'MSWin32' ? 1 : 0 ],
);
for my $words ( [qw( hook marketplace-notice )], ['notice'] ) {
  for my $shape (@root_shapes) {
    my ( $label, $root, $expected ) = @{$shape};
    my $name = join( ' ', @{$words} ).' with '.$label;
    my $box = sandbox();
    my $run = run_cli(
      sandbox => $box, argv => [briefing_argv(@{$words})],
      env => { CLAUDE_PLUGIN_ROOT => $root->($box) },
    );
    is($run->{exit_code}, 0, "$name: exit zero");
    is($run->{stderr}, '', "$name: stderr empty");
    if ($expected) {
      is(notice_text_of($run), $notice_text, "$name: shown");
    }
    else {
      is($run->{stdout}, '', "$name: silent");
    }
  }
}

# A failing notice never takes a session down: silence and exit zero for both spellings.
for my $words ( [qw( hook marketplace-notice )], ['notice'] ) {
  my $label = join ' ', @{$words};
  my $box = sandbox();
  my $run = run_cli(
    sandbox => $box,
    argv    => [
      $^X,
      '-I'.path(repo_root(), 'lib')->stringify,
      '-MApp::Briefing::CLI',
      '-e', q{
        package DyingBriefing; use Moo; extends 'App::Briefing';
        sub process_notice { die "notice exploded\n" }
        package DyingCLI; use Moo; extends 'App::Briefing::CLI';
        sub app_class { 'DyingBriefing' }
        package main; exit( DyingCLI->new->run(\@ARGV) );
      },
      @{$words},
    ],
    env => { CLAUDE_PLUGIN_ROOT => cache_root($box, 'briefing') },
  );
  is($run->{exit_code}, 0, "$label exits zero when process_notice dies");
  is($run->{stdout}, '', "$label prints nothing when process_notice dies");
  is($run->{stderr}, '', "$label keeps stderr empty when process_notice dies");
}

# The hook stays unambiguous: other words are still hook events, never the notice.
{
  my $box = sandbox();
  my $run = run_cli(
    sandbox => $box,
    argv    => [briefing_argv('hook', 'session-start')],
    input   => encode_json(hook_payload($box, hook_event_name => 'SessionStart')),
    env     => { CLAUDE_PLUGIN_ROOT => cache_root($box, 'briefing') },
  );
  is($run->{exit_code}, 0, 'hook session-start still exits zero');
  ok(!state_file($box)->exists, 'hook session-start never writes the notice state');
}

done_testing;
