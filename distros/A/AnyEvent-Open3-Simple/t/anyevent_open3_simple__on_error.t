use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More;

if($^O eq 'MSWin32')
{
  plan skip_all => 'open3 does not die on missing program on MSWin32';
}
elsif(eval q{ use 5.14.0; 1 })
{
  plan tests => 4;
}
else
{
  plan skip_all => 'test requires perl 5.14 or better';
}

use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Temp qw( tempdir );
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );

my $done = AnyEvent->condvar;

my $called_on_error = 0;
my $message = '';
my $cmd;
my @args;

my $ipc = AnyEvent::Open3::Simple->new(
  on_error => sub {
    ($message, $cmd, @args) = @_;
    $called_on_error = 1;
    $done->send;
  },
  on_exit => sub {
    my($proc, $exit, $sig) = @_;
    note "exit = $exit";
    note "sig  = $sig";
    $done->send;
  },
);

$ipc->run(File::Spec->catfile($dir, 'bogus.pl'), 'arg1', 'arg2');

$done->recv;

is $called_on_error, 1, 'called on_error';
chomp $message;
like $message, qr/^open3: /, "message = $message";

is $cmd, File::Spec->catfile($dir, 'bogus.pl'), 'cmd';
is_deeply \@args, [qw( arg1 arg2 )], 'args';
