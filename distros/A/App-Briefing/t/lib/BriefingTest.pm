package BriefingTest;

use strict;
use warnings;

use Carp qw( croak );
use Cwd qw( getcwd );
use Exporter qw( import );
use File::Temp ();
use IPC::Open3 qw( open3 );
use JSON::MaybeXS qw( decode_json );
use Path::Tiny qw( path );
use POSIX qw( WNOHANG );
use if $^O eq 'MSWin32', 'Win32::LongPath', qw( mkdirL openL testL );

our @EXPORT_OK = qw(
  claude_agent
  claude_skill
  codex_agent
  codex_skill
  decode_json_output
  hook_payload
  repo_root
  run_cli
  sandbox
  write_file
);

sub repo_root {
  return path(__FILE__)->parent->parent->parent->absolute->stringify;
}

sub _make_dir {
  my ( $directory ) = @_;
  if ($^O eq 'MSWin32') {
    return if testL('d', $directory);
    my $parent = path($directory)->parent->stringify;
    _make_dir($parent) unless testL('d', $parent);
    mkdirL($directory)
      or croak 'cannot create '.$directory.': '.$!;
    return;
  }
  path($directory)->mkpath;
  return;
}

sub sandbox {
  my $tmp = File::Temp->newdir(CLEANUP => 1);
  my $root = "$tmp";
  my %paths = (
    tmpdir     => $tmp,
    root       => $root,
    cwd        => path($root, 'project')->stringify,
    home       => path($root, 'home')->stringify,
    codex_home => path($root, 'codex-home')->stringify,
  );
  _make_dir($paths{cwd});
  _make_dir($paths{home});
  _make_dir($paths{codex_home});
  return \%paths;
}

sub write_file {
  my ( $file, $body ) = @_;
  my $path = path($file);
  _make_dir($path->parent->stringify);
  if ($^O eq 'MSWin32') {
    my $fh;
    openL(\$fh, '>:encoding(UTF-8)', $path->stringify)
      or croak 'cannot write '.$path.': '.$!;
    print {$fh} $body
      or croak 'cannot write '.$path.': '.$!;
    close $fh
      or croak 'cannot close '.$path.': '.$!;
  }
  else {
    $path->spew_utf8($body);
  }
  return $path->stringify;
}

sub claude_agent {
  my ( $box, $name, @skills ) = @_;
  my $items = join '', map { '    - '.$_."\n" } @skills;
  return write_file(
    path($box->{cwd}, '.claude', 'agents', $name.'.md'),
    "---\nname: $name\nbriefing:\n  skills:\n$items---\nbody\n",
  );
}

sub claude_skill {
  my ( $box, $name, $body ) = @_;
  $body = "BODY\n" unless defined $body;
  return write_file(
    path($box->{cwd}, '.claude', 'skills', $name, 'SKILL.md'),
    $body,
  );
}

sub codex_agent {
  my ( $box, $name, $body ) = @_;
  return write_file(
    path($box->{cwd}, '.codex', 'agents', $name.'.toml'),
    $body,
  );
}

sub codex_skill {
  my ( $box, $name, $body ) = @_;
  $body = "BODY\n" unless defined $body;
  return write_file(
    path($box->{cwd}, '.agents', 'skills', $name, 'SKILL.md'),
    $body,
  );
}

sub hook_payload {
  my ( $box, %overrides ) = @_;
  return {
    hook_event_name => 'SubagentStart',
    agent_type      => 'demo',
    agent_id        => 'agent-1',
    turn_id         => 'turn-1',
    cwd             => $box->{cwd},
    transcript_path => path(
      $box->{home}, '.claude', 'projects', 'project', 'session.jsonl',
    )->stringify,
    %overrides,
  };
}

sub decode_json_output {
  my ( $text ) = @_;
  return decode_json($text);
}

sub run_cli {
  my ( %args ) = @_;
  my $box = $args{sandbox} or croak 'run_cli requires sandbox';
  my $argv = $args{argv} or croak 'run_cli requires argv';
  my $input = defined $args{input} ? $args{input} : '';
  my $extra_env = $args{env} || {};

  local %ENV = %ENV;
  $ENV{HOME} = $box->{home};
  $ENV{CODEX_HOME} = $box->{codex_home};
  delete $ENV{CLAUDE_PLUGIN_ROOT};
  @ENV{keys %{$extra_env}} = values %{$extra_env};

  my $original_cwd = getcwd();
  chdir $box->{cwd}
    or croak 'cannot chdir to '.$box->{cwd}.': '.$!;

  # stdin/stdout/stderr go through temp files, never pipes: a pipe whose
  # write end leaks into another process never delivers EOF on Windows, and
  # reading stdout to EOF before stderr can deadlock. The child is also
  # killed after a timeout so a hang fails the test instead of the build.
  my $timeout = defined $args{timeout} ? $args{timeout} : 60;
  my $dir = File::Temp->newdir(CLEANUP => 1);
  my $in_file  = path($dir, 'stdin');
  my $out_file = path($dir, 'stdout');
  my $err_file = path($dir, 'stderr');
  $in_file->spew_raw($input);

  my ( $stdout, $stderr, $wait_status, $timed_out );
  my $ok = eval {
    open my $in, '<', $in_file->stringify
      or croak 'cannot open CLI stdin file: '.$!;
    open my $out, '>', $out_file->stringify
      or croak 'cannot open CLI stdout file: '.$!;
    open my $err, '>', $err_file->stringify
      or croak 'cannot open CLI stderr file: '.$!;
    binmode $_ for $in, $out, $err;

    my $pid = open3(
      '<&'.fileno($in), '>&'.fileno($out), '>&'.fileno($err),
      @{$argv},
    );
    close $in;
    close $out;
    close $err;

    my $deadline = time + $timeout;
    my $reaped;
    while (1) {
      $reaped = waitpid($pid, WNOHANG);
      last if $reaped == $pid || $reaped == -1;
      if (time >= $deadline) {
        $timed_out = 1;
        kill 'KILL', $pid;
        waitpid($pid, 0);
        last;
      }
      select undef, undef, undef, 0.05;
    }
    $wait_status = $?;
    $stdout = $out_file->slurp_raw;
    $stderr = $err_file->slurp_raw;
    1;
  };
  my $error = $@;
  chdir $original_cwd
    or croak 'cannot restore cwd to '.$original_cwd.': '.$!;
  croak $error unless $ok;
  croak 'run_cli: timed out after '.$timeout.'s: '.join(' ', @{$argv})
    .(length $stderr ? "\nstderr so far: ".$stderr : '')
    if $timed_out;

  return {
    stdout    => $stdout,
    stderr    => $stderr,
    exit_code => $wait_status >> 8,
  };
}

1;
