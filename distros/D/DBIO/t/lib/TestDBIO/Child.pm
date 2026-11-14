package TestDBIO::Child;
# ABSTRACT: Run a child perl for a test, the same way on every platform

use strict;
use warnings;

use Carp ();
use File::Spec ();
use File::Temp ();
use IPC::Open3 ();
use POSIX ();
use Time::HiRes ();

# POSIX::WNOHANG is 1 on Windows too (perl's win32.h).
use constant WNOHANG => POSIX::WNOHANG();

# Whether the child writes CRLF line ends: perl's default layer is :crlf on
# Windows, while the temporary file is read back as bytes.
our $CRLF = do {
  open my $p, '>', File::Spec->devnull or die "open devnull: $!";
  (grep { $_ eq 'crlf' } PerlIO::get_layers($p)) ? 1 : 0;
};

=head1 SYNOPSIS

  use TestDBIO::Child;
  my $r = TestDBIO::Child::run_perl(code => $source, timeout => 30);
  $r->{output}; $r->{exit}; $r->{status}; $r->{timed_out};

=head1 DESCRIPTION

Starts C<$^X> on a script file with C<IPC::Open3> (list form, no shell, no
pipe open), the child's standard output going to a temporary file. The child
is given a time limit by polling C<waitpid>; at the limit it is killed.

=head2 run_perl

Options: C<script> (a file) or C<code> (source, written to a temporary file);
C<args> (arguments after the script); C<inc> (default: the non-reference
C<@INC>); C<merge_stderr> (stderr into the same output, else it is passed
on); C<timeout> (seconds, default 60).

Returns a hashref: C<output>, C<status> (the raw C<$?>), C<exit> (C<<
$? >> 8 >>), C<timed_out>. Line ends in C<output> are always C<\n>, on
every platform.

=cut

sub run_perl {
  my (%o) = @_;

  Carp::croak 'run_perl needs script or code' unless defined $o{script} || defined $o{code};

  my $keep;
  my $script = $o{script};
  if (!defined $script) {
    $keep = File::Temp->new(SUFFIX => '.pl');
    print {$keep} $o{code};
    close $keep or Carp::croak "close script: $!";
    $script = $keep->filename;
  }

  my @inc     = map { "-I$_" } @{ $o{inc} || [ grep { !ref } @INC ] };
  my $timeout = defined $o{timeout} ? $o{timeout} : 60;

  my $out = File::Temp->new(SUFFIX => '.out');
  $out->autoflush(1);

  # open3 closes the handles it is given by number in the parent, so it gets
  # duplicates.
  open my $in_dup,  '<', File::Spec->devnull or Carp::croak "open devnull: $!";
  open my $out_dup, '>&', $out or Carp::croak "dup output: $!";
  my $err_dup;
  if (!$o{merge_stderr}) {
    open $err_dup, '>&', \*STDERR or Carp::croak "dup stderr: $!";
  }
  my $pid = IPC::Open3::open3(
    '<&' . fileno($in_dup), '>&' . fileno($out_dup),
    ($err_dup ? '>&' . fileno($err_dup) : undef),
    $^X, @inc, $script, @{ $o{args} || [] },
  );

  my $deadline  = Time::HiRes::time() + $timeout;
  my $timed_out = 0;
  my $got;
  while (1) {
    $got = waitpid($pid, WNOHANG);
    last if $got == $pid || $got == -1;
    if (Time::HiRes::time() >= $deadline) {
      kill 'KILL', $pid;
      waitpid($pid, 0);
      $timed_out = 1;
      last;
    }
    Time::HiRes::sleep(0.05);
  }
  my $status = $?;

  seek $out, 0, 0 or Carp::croak "seek output: $!";
  binmode($out, ':crlf') if $CRLF;
  my $output = do { local $/; <$out> } // '';

  return {
    output    => $output,
    status    => $status,
    exit      => $status >> 8,
    timed_out => $timed_out,
  };
}

1;
