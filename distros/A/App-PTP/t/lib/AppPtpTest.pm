package AppPtpTest;

use 5.018;
use strict;
use warnings;

use Exporter 'import';
use App::PTP;
use Cwd;
use Fcntl;
use FindBin;
use File::Spec::Functions 'rel2abs';
use File::Temp 'tempfile';

# If there is the relative 'lib' directory in the input, we're fixing it to an
# absolute path, so that "use" at run-time inside the Safe will still work.
@INC = map { rel2abs($_) } @INC;

our @EXPORT = qw(ptp slurp slurp_and_close);

sub slurp_and_close {
  my ($fh) = @_;
  seek $fh, 0, Fcntl::SEEK_SET;
  binmode $fh;
  local $/; # enable slurp mode;
  my $str = <$fh>;
  close $fh;
  return $str;
}

sub slurp {
  my ($file) = @_;
  open my $fh, '<:bytes', $file;
  local $/; # enable slurp mode;
  my $str = <$fh>;
  close $fh;
  return $str;
}

# ptp(qw(commands...), $input)
# input can be a file name or a reference to a string, it can also be omitted if
# nothing will be read from the standard input.
sub ptp {
  my ($argv, $stdin) = @_;
  my $cur_dir = getcwd();
  chdir "$FindBin::Bin/data" or die "Can't chdir to test data: $!";
  $stdin = \'' unless $stdin;
  my ($stdout, $stderr) = ('', '');
  open my $stdin_fh, '<', $stdin or die "Can't open test STDIN: $!";
  open my $stdout_fh, '+>', \$stdout or die "Can't open test STDOUT: $!";
  open my $stderr_fh, '+>', \$stderr or die "Can't open test STDERR: $!";
  App::PTP::Commands::delete_perl_env();
  App::PTP::Run($stdin_fh, $stdout_fh, $stderr_fh, ['-d', @$argv]);
  close $stdin_fh;
  close $stdout_fh;
  close $stderr_fh;  
  chdir $cur_dir or die "Can't restore the working directory: $!";
  if (wantarray) {
    return ($stdout, $stderr);
  } else {
    return $stdout;
  }
}

1;
