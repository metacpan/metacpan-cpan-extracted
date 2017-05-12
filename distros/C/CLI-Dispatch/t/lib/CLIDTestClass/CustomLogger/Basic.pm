package CLIDTestClass::CustomLogger::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use Try::Tiny;

sub initialize {
  my $class = shift;
  try   { require IO::Capture::Stderr }
  catch { $class->skip_this_class('this test requires IO::Capture') };
  try   { require Log::Handler }
  catch { $class->skip_this_class('this test requires Log::Handler') };
}

sub no_args : Test {
  my $class = shift;

  my $ret = $class->dispatch();

  is $ret => '', $class->message("don't log unless verbose");
}

sub verbose : Test(4) {
  my $class = shift;

  my $ret = $class->dispatch(qw/-v/);

  unlike $ret => qr/\[DEBUG\] debug/, $class->message("no debug log");
  like   $ret => qr/\[INFO\] info/, $class->message("log info");
  like   $ret => qr/\[WARNING\] warn/, $class->message("log warn");
  like   $ret => qr/\[ERROR\] error/, $class->message("log error");
}

sub debug : Test(4) {
  my $class = shift;

  my $ret = $class->dispatch(qw/--debug/);

  like $ret => qr/\[DEBUG\] debug/, $class->message("debug log");
  like $ret => qr/\[INFO\] info/, $class->message("log info");
  like $ret => qr/\[WARNING\] warn/, $class->message("log warn");
  like $ret => qr/\[ERROR\] error/, $class->message("log error");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $capture = IO::Capture::Stderr->new;

  $CLIDTest::CustomLogger::DumpMe::Logger = Log::Handler->new;
  $CLIDTest::CustomLogger::DumpMe::Logger->add(
    screen => {
      log_to => 'STDERR',
      maxlevel => 'info',
      message_layout => '[%L] %m',
      alias => 'stderr',
    },
  );

  my $ret;
  $capture->start;
  try   { $ret = CLIDTest::CustomLogger::DumpMe->run_directly }
  catch { $ret = $_ || 'Obscure error' };
  $capture->stop;

  my $log = join "\n", $capture->read;

  return $ret eq 'ok' ? $log : $ret;
}

1;
