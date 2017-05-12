use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More tests => 5;
use File::Temp qw( tempdir );
use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
open(my $fh, '>', File::Spec->catfile($dir, 'child.pl'));
print $fh join "\n", "#!$^X",
                     '$| = 1;',
                     'print "message1\n";',
                     'print "message2\n";',
                     'print STDERR "message3\n";';
close $fh;

my $done = AnyEvent->condvar;

my @out;
my @err;
my $exit_value;
my $signal;
my $proc;

my $ipc = AnyEvent::Open3::Simple->new(
  on_stdout => sub { push @out, pop },
  on_stderr => sub { push @err, pop },
  on_exit   => sub {
    ($proc, $exit_value, $signal) = @_;
    $done->send;
  },
);

my $timeout = AnyEvent->timer (
  after => 5,
  cb    => sub { diag 'timeout!'; exit 2; },
);

my $ret = $ipc->run($^X, File::Spec->catfile($dir, 'child.pl'));
diag $@ if $@;
isa_ok $ret, 'AnyEvent::Open3::Simple';

$done->recv;

is $out[0], 'message1', 'out[0] = message1';
is $out[1], 'message2', 'out[1] = message2';
is $err[0], 'message3', 'err[0] = message3';

pass 'Event Loop Is: ' . AnyEvent::detect();
