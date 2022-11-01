use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More $^O eq 'MSWin32' ? (skip_all => 'on_signal not supported on windows') : (tests => 6);
use AnyEvent::Open3::Simple;
use File::Temp qw( tempdir );
use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
do {
  my $fh;
  open($fh, '>', File::Spec->catfile($dir, 'child_sig9.pl'));
  print $fh "#!$^X\nkill 9, \$\$\n";
  close $fh;

  open($fh, '>', File::Spec->catfile($dir, 'child_normal.pl'));
  print $fh "#!$^X\n";
  close $fh;
};

my $done;

my($proc, $signal1, $signal2, $exit_value);

my $ipc = AnyEvent::Open3::Simple->new(
  on_signal => sub {
    ($proc, $signal1) = @_;
  },
  on_exit   => sub {
    ($proc, $exit_value, $signal2) = @_;
    $done->send;
  },
);

my $timeout = AnyEvent->timer (
  after => 5,
  cb    => sub { diag 'timeout!'; exit 2 },
);

do {
  $done = AnyEvent->condvar;

  my $ret = $ipc->run($^X, File::Spec->catfile($dir, 'child_normal.pl'));
  diag $@ if $@;
  isa_ok $ret, 'AnyEvent::Open3::Simple';

  $done->recv;

  is $signal1, undef, 'signal1 = undef';
  is $signal2, 0, 'signal2 = 0';
};

do {
  $done = AnyEvent->condvar;

  my $ret = $ipc->run($^X, File::Spec->catfile($dir, 'child_sig9.pl'));
  diag $@ if $@;
  isa_ok $ret, 'AnyEvent::Open3::Simple';

  $done->recv;

  is $signal1, 9, 'signal1 = 9';
  is $signal2, 9, 'signal2 = 9';
};
