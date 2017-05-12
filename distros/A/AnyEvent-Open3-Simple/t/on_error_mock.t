use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More tests => 2;

package IPC::Open3;

BEGIN { $INC{'IPC/Open3.pm'} = __FILE__ }
use base qw( Exporter );
BEGIN { our @EXPORT_OK = 'open3' }

sub open3 { die "open3: this is an error" }

package main;

use AnyEvent;
use AnyEvent::Open3::Simple;


my $done = AnyEvent->condvar;

my $called_on_error = 0;
my $message = '';

my $ipc = AnyEvent::Open3::Simple->new(
  on_error => sub {
    $message = shift;
    $called_on_error = 1;
    $done->send;
  },
  on_exit => sub {
    $done->send;
  },
);

$ipc->run('foo', 'bar');

$done->recv;

is $called_on_error, 1, 'called on_error';
chomp $message;
like $message, qr/^open3: /, "message = $message";
