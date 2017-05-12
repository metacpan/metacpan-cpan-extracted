package CLIDTestClass::Log::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use Try::Tiny;

sub initialize {
  my $class = shift;
  try   { require IO::Capture::Stderr }
  catch { $class->skip_this_class('this test requires IO::Capture') };
}

sub no_args : Test {
  my $class = shift;

  my $ret = $class->dispatch();

  is $ret => '', $class->message("don't log unless verbose");
}

sub verbose : Test(4) {
  my $class = shift;

  my $ret = $class->dispatch(qw/-v/);

  unlike $ret => qr/\[debug\] debug/, $class->message("no debug log");
  like   $ret => qr/\[info\] info/, $class->message("log info");
  like   $ret => qr/\[warn\] warn/, $class->message("log warn");
  like   $ret => qr/\[error\] error/, $class->message("log error");
}

sub debug : Test(4) {
  my $class = shift;

  my $ret = $class->dispatch(qw/--debug/);

  like $ret => qr/\[debug\] debug/, $class->message("debug log");
  like $ret => qr/\[info\] info/, $class->message("log info");
  like $ret => qr/\[warn\] warn/, $class->message("log warn");
  like $ret => qr/\[error\] error/, $class->message("log error");
}

sub logfilter : Test(4) {
  my $class = shift;

  my $ret = $class->dispatch("--logfilter=info,error");

  unlike $ret => qr/\[debug\] debug/, $class->message("no debug log");
  like $ret => qr/\[info\] info/, $class->message("log info");
  unlike $ret => qr/\[warn\] warn/, $class->message("no log warn");
  like $ret => qr/\[error\] error/, $class->message("log error");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $capture = IO::Capture::Stderr->new;

  my $ret;
  $capture->start;
  try   { $ret = CLIDTest::Log::DumpMe->run_directly }
  catch { $ret = $_ || 'Obscure error' };
  $capture->stop;

  my $log = join "\n", $capture->read;

  return $ret eq 'ok' ? $log : $ret;
}

1;
