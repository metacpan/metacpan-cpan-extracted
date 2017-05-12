use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More tests => 6;
use AnyEvent::Open3::Simple;
use File::Temp qw( tempdir );
use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
do {
  my $fh;
  open($fh, '>', File::Spec->catfile($dir, 'child_exit3.pl'));
  print $fh "#!$^X\nexit 3\n";
  close $fh;
  
  open($fh, '>', File::Spec->catfile($dir, 'child_normal.pl'));
  print $fh "#!$^X\n";
  close $fh;
};

my $done;

my($proc, $signal, $exit_value1, $exit_value2);

my $ipc = AnyEvent::Open3::Simple->new(
  on_fail => sub {
    ($proc, $exit_value1) = @_;
  },
  on_exit   => sub {
    ($proc, $exit_value2, $signal) = @_;
    $done->send;
  },
);

my $timeout = AnyEvent->timer (
  after => 5,
  cb   => sub { diag 'timeout!'; exit 2; },
);

do {
  $done = AnyEvent->condvar;

  my $ret = $ipc->run($^X, File::Spec->catfile($dir, 'child_normal.pl'));
  isa_ok $ret, 'AnyEvent::Open3::Simple';
  
  $done->recv;
  
  is $exit_value1, undef, 'exit_value1 = undef';
  is $exit_value2, 0, 'exit_value2 = 0';
};

do {
  $done = AnyEvent->condvar;

  my $ret = $ipc->run($^X, File::Spec->catfile($dir, 'child_exit3.pl'));
  isa_ok $ret, 'AnyEvent::Open3::Simple';

  $done->recv;
  
  is $exit_value1, 3, 'exit_value1 = 3';
  is $exit_value2, 3, 'exit_value2 = 3';
};
