#!perl

use strict;

use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }
use AnyEvent::Util;
use AnyEvent::Handle;
use Socket;

print "1..7\n";

my $cv = AnyEvent->condvar;

my ($rd, $wr) = portable_socketpair;

my $rd_ae =
   AnyEvent::Handle->new (
      fh => $rd,
      on_eof => sub {
         warn "reader got EOF";
         $cv->broadcast
      }
   );

my $wr_ae =
   AnyEvent::Handle->new (
      fh => $wr,
      on_eof => sub {
         warn "writer got EOF\n";
         $cv->broadcast
      }
   );

my $dat = '';

$rd_ae->push_read (chunk => 5132, sub {
   my ($rd_ae, $data) = @_;
   $dat = substr $data, 0, 2;
   $dat .= substr $data, -5;

   print "ok 4 - first read chunk\n";
   my $n = 5;
   $wr_ae->push_write ("A" x 5000);
   $wr_ae->on_drain (sub {
      my ($wr_ae) = @_;
      $wr_ae->on_drain;
      print "ok " . $n++ . " - fourth write\n";

   });

   $rd_ae->push_read (chunk => 5000, sub {
      print "ok " . $n++ . " - second read chunk\n";
      $cv->broadcast
   });
});

$wr_ae->push_write ("A" x 5000);
$wr_ae->push_write ("X" x 130);

# and now some extreme CPS action:
$wr_ae->on_drain (sub {
   my ($wr_ae) = @_;
   $wr_ae->on_drain;
   print "ok 1 - first write\n";

   $wr_ae->push_write ("Y");
   $wr_ae->on_drain (sub {
      my ($wr_ae) = @_;
      $wr_ae->on_drain;
      print "ok 2 - second write\n";

      $wr_ae->push_write ("Z");
      $wr_ae->on_drain (sub {
         my ($wr_ae) = @_;
         $wr_ae->on_drain;
         print "ok 3 - third write\n";
      });
   });
});

$cv->wait;

if ($dat eq "AAXXXYZ") {
   print "ok 7 - received data\n";
} else {
   warn "dat was '$dat'\n";
   print "not ok 7 - received data\n";
}
