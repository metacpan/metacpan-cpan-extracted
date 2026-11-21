#!/usr/bin/env perl
# Print the module set the packed briefing needs, one name per line: every module that loads
# while the CLI runs each of its commands in this process, plus the runtime requirements and
# backends that load by name (pp's static scan misses those). Run from the dist root:
#   perl -Ilib scripts/loaded-modules.pl
# scripts/binary-pp-args.sh turns the list into pp -M options (binary_pp_args of the
# [@Author::GETTY] bundle); the bundle's require gate checks the binary against binary_require.
# The output never depends on a user's files: the fixture lives in a temporary directory.
use strict;
use warnings;
use File::Spec;
use File::Temp qw( tempdir );

my $root = tempdir( CLEANUP => 1 );
my $home = File::Spec->catdir( $root, 'home' );
my $cwd  = File::Spec->catdir( $root, 'project' );

sub spew {
  my ( $path, $text ) = @_;
  # Keep the volume: without it make_path creates the directory on the current drive (Windows).
  my ( $vol, $dir ) = File::Spec->splitpath($path);
  require File::Path;
  File::Path::make_path( File::Spec->catpath( $vol, $dir, '' ) );
  open my $fh, '>', $path or die "cannot write $path: $!\n";
  binmode $fh;
  print {$fh} $text;
  close $fh or die "cannot write $path: $!\n";
}

spew( File::Spec->catfile( $home, '.claude', 'skills', 'demo-skill', 'SKILL.md' ), "BODY\n" );
spew(
  File::Spec->catfile( $cwd, '.claude', 'agents', 'demo.md' ),
  "---\nname: demo\ndescription: d\nbriefing:\n  skills:\n    - demo-skill\n---\nbody\n",
);
spew(
  File::Spec->catfile( $cwd, '.codex', 'agents', 'cdemo.toml' ),
  qq{# briefing: skills = ["demo-skill"]\nname = "cdemo"\ndescription = "d"\n}
    . qq{developer_instructions = "x"\n},
);

$ENV{HOME}        = $home;
$ENV{USERPROFILE} = $home;
$ENV{CODEX_HOME}  = File::Spec->catdir( $home, '.codex' );
$ENV{CLAUDE_CONFIG_DIR} = File::Spec->catdir( $home, '.claude' );
delete $ENV{CLAUDE_PROJECT_DIR};

require App::Briefing::CLI;

my $devnull = File::Spec->devnull;
open my $saved_out, '>&', \*STDOUT or die "dup stdout: $!\n";
open my $saved_err, '>&', \*STDERR or die "dup stderr: $!\n";
open STDOUT, '>', $devnull or die "stdout: $!\n";
open STDERR, '>', $devnull or die "stderr: $!\n";

my $transcript = File::Spec->catfile( $home, '.claude', 'projects', 'p', 's.jsonl' );
$transcript =~ s{\\}{/}g;
( my $json_cwd = $cwd ) =~ s{\\}{/}g;
my $start = qq({"hook_event_name":"SubagentStart","agent_type":"demo","agent_id":"a",)
  . qq("cwd":"$json_cwd","transcript_path":"$transcript"});
$start .= '}';
my @runs = (
  [ ['--version'], '' ],
  [ ['--help'], '' ],
  [ [ 'doctor', '--cwd', $cwd, '--harness', 'both' ], '' ],
  [ [ 'doctor', '--tsv', '--cwd', $cwd ], '' ],
  [ [ 'hook', 'subagent-start' ], $start ],
  [ [ 'hook', 'pre-tool-use' ],
    qq({"hook_event_name":"PreToolUse","tool_name":"Agent","cwd":"$json_cwd",)
      . qq("tool_input":{"subagent_type":"demo"}}) ],
  [ [ 'hook', 'session-start' ],
    qq({"hook_event_name":"SessionStart","cwd":"$json_cwd","source":"startup"}) ],
  [ ['notice'], '' ],
);
my $failure;
for my $run (@runs) {
  my ( $argv, $stdin ) = @{$run};
  my $input = File::Spec->catfile( $root, 'stdin' );
  spew( $input, $stdin );
  open STDIN, '<', $input or die "stdin: $!\n";
  eval { App::Briefing::CLI->run($argv); 1 } or $failure ||= "briefing @{$argv} died: $@";
}

# Requirements that load by name or only on some platforms.
my @named = qw(
  B Carp Encode JSON::MaybeXS JSON::PP Moo namespace::clean Path::Tiny TOML::Tiny::Parser
);
push @named, 'Win32', 'Win32::LongPath' if $^O eq 'MSWin32';
for my $module ( @named, qw( Cpanel::JSON::XS JSON::XS ) ) {
  ( my $file = "$module.pm" ) =~ s{::}{/}g;
  eval { require $file; 1 };
  $failure ||= "required module $module does not load: $@" if $@ && grep { $_ eq $module } @named;
}

open STDOUT, '>&', $saved_out or die "restore stdout: $!\n";
open STDERR, '>&', $saved_err or die "restore stderr: $!\n";
die $failure if $failure;
my %seen;
for my $file ( sort keys %INC ) {
  next unless $file =~ /\.pm\z/ && !ref $INC{$file};
  ( my $module = $file ) =~ s{/}{::}g;
  $module =~ s/\.pm\z//;
  # Strawberry Perl's portable launcher (Portable, Portable::CPAN, Portable::HomeDir, ...) is
  # already in %INC when this script starts, because the perl.exe startup loads it. The CLI
  # never uses it; packing it would drag in CPAN-client modules such as IO::Socket::SSL and
  # Net::SSLeay, which briefing (no network access) must not ship. The filter is deliberately
  # narrow: subtracting a pre-run %INC snapshot would also drop pragmas and core modules
  # (strict, warnings, Carp, ...) that the CLI needs and that must stay in the list.
  next if $module =~ /\APortable(?:::|\z)/;
  print "$module\n" unless $seen{$module}++;
}
