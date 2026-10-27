package UpdateConfigTest;

# Helper to test the update_config program. Each object is a sandbox with a
# temporary home directory and configuration directory, in which the program
# can be run.

use strict;
use warnings;

use English;
use Exporter 'import';
use POSIX 'WEXITSTATUS';
use File::Basename 'dirname';
use File::Path 'make_path';
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use FindBin;

our $VERSION = 0.01;

our @EXPORT_OK = qw(guarded);

my $script = catfile($FindBin::Bin, '..', 'script', 'update_config');

# Returns a new sandbox, which is deleted at the end of the test.
sub new {
  my ($class) = @_;
  my $root = tempdir(CLEANUP => 1);
  my $self = bless {root => $root}, $class;
  make_path($self->home, $self->config_dir);
  return $self;
}

# Returns the root of the sandbox, which can be used to store arbitrary files.
sub root {
  my ($self) = @_;
  return $self->{root};
}

# Returns the (fake) home directory used when running the program.
sub home {
  my ($self) = @_;
  return catfile($self->{root}, 'home');
}

# Returns the default configuration directory read by the program.
sub config_dir {
  my ($self) = @_;
  return catfile($self->home, '.config', 'update_config');
}

# Returns the absolute path of the given path, relative to the home directory.
sub home_path {
  my ($self, $path) = @_;
  return catfile($self->home, $path);
}

# Adds a configuration fragment, $name is relative to the configuration
# directory and can include sub-directories.
sub add_fragment {
  my ($self, $name, $content) = @_;
  write_file(catfile($self->config_dir, $name), $content);
  return;
}

# Writes a file at the given path, relative to the home directory.
sub write_home_file {
  my ($self, $path, $content) = @_;
  write_file($self->home_path($path), $content);
  return;
}

# Returns the content of the file at the given path, relative to the home
# directory, or undef if that file does not exist.
sub read_home_file {
  my ($self, $path) = @_;
  return read_file($self->home_path($path));
}

# Runs the program with the given arguments and returns a hash-ref with the
# `stdout`, `stderr` and `exit` (the exit code) of the program. The first
# argument can be a hash-ref of options:
#   - `script`: the path of the program to run, instead of
#     script/update_config. Used to run the output of --pack.
#   - `stdin`: like `script` but the program is passed on the standard input
#     of `perl -`, as it would be through ssh.
#   - `cwd`: the directory in which the program is executed (default to the
#     root of the sandbox).
#   - `env`: a hash-ref of environment variables to set (or unset with undef).
sub run {
  my ($self, @args) = @_;
  my %opts = ref $args[0] eq 'HASH' ? %{shift @args} : ();
  my $out_file = catfile($self->{root}, 'stdout');
  my $err_file = catfile($self->{root}, 'stderr');
  my @cmd = ($EXECUTABLE_NAME, defined $opts{stdin} ? '-' : $opts{script} // $script, @args);
  my $pid = fork // die "Cannot fork: $OS_ERROR\n";
  if ($pid == 0) {
    local %ENV = (
      %ENV,
      HOME => $self->home,
      XDG_CONFIG_HOME => undef,
      XDG_STATE_HOME => undef,
      %{$opts{env} // {}}
    );
    delete @ENV{grep { !defined $ENV{$_} } keys %ENV};
    chdir($opts{cwd} // $self->{root}) or die "Cannot chdir: $OS_ERROR\n";
    open STDIN, '<', $opts{stdin} // '/dev/null' or die "Cannot open stdin: $OS_ERROR\n";
    open STDOUT, '>', $out_file or die "Cannot open stdout: $OS_ERROR\n";
    open STDERR, '>', $err_file or die "Cannot open stderr: $OS_ERROR\n";
    exec {$cmd[0]} @cmd or die "Cannot exec: $OS_ERROR\n";
  }
  waitpid $pid, 0;
  return {
    exit => WEXITSTATUS($CHILD_ERROR),
    stdout => read_file($out_file),
    stderr => read_file($err_file)
  };
}

# Returns the given content surrounded by the guard markers added by the
# program, with the given comment char (default to '#') and guard suffix.
sub guarded {
  my ($content, $char, $suffix) = @_;
  my $c = $char // '#';
  my $deco = "${c}${c}${c}";
  my $guard = 'AUTO-CONFIG'.(defined $suffix ? ":${suffix}" : q{});
  return "${deco}${guard} START${deco}\n${content}${deco}${guard} END${deco}\n";
}

sub write_file {
  my ($path, $content) = @_;
  make_path(dirname($path));
  open my $fh, '>', $path or die "Cannot write '${path}': ${OS_ERROR}\n";
  print {$fh} $content;
  close $fh or die "Cannot close '${path}': ${OS_ERROR}\n";
  return;
}

sub read_file {
  my ($path) = @_;
  open my $fh, '<', $path or return;
  local $RS = undef;
  my $content = <$fh>;
  close $fh or die "Cannot close '${path}': ${OS_ERROR}\n";
  return $content;
}

1;
