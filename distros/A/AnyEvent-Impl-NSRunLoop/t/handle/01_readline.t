#!perl

# actually tests a few other read/write types as well

use strict;

use AnyEvent::Impl::NSRunLoop;
use AnyEvent::Handle;
use Test::More;
use Socket;
use Errno;

plan skip_all => 'TODO';
plan tests => 8;

{
   my $cv = AnyEvent->condvar;

   socketpair my $rd, my $wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

   my $rd_ae = AnyEvent::Handle->new (
      fh       => $rd,
      on_error => sub {
         ok ($! == &Errno::EPIPE);
         $cv->broadcast;
      },
      on_eof   => sub {
         ok (0, "got eof");
      },
   );

   my $concat;

   $rd_ae->push_read (line => sub {
      is ($_[1], "A", 'A line was read correctly');
      my $cb; $cb = sub {
         $concat .= $_[1];
         $_[0]->push_read (line => $cb);
      };
      $_[0]->push_read (line => $cb);
   });

   syswrite $wr, "A\012BC\012DEF\012G\012" . ("X" x 113) . "\012";
   close $wr;

   $cv->wait;
   is ($concat, "BCDEFG" . ("X" x 113), 'initial lines were read correctly');
}

{
   my $cv = AnyEvent->condvar;

   socketpair my $rd, my $wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

   my $concat;

   my $rd_ae =
      AnyEvent::Handle->new (
         fh      => $rd,
         on_eof  => sub { $cv->broadcast },
         on_read => sub {
            $_[0]->push_read (line => sub {
               $concat .= "$_[1]:";
            });
         }
      );

   my $wr_ae = new AnyEvent::Handle fh  => $wr, on_eof => sub { die };

   undef $wr;
   undef $rd;

   $wr_ae->push_write (netstring => "0:xx,,");
   $wr_ae->push_write (netstring => "");
   $wr_ae->push_write (storable => [4,3,2]);
   $wr_ae->push_write (packstring => "w", "hallole" x 99999); # try to exhaust socket buffer here
   $wr_ae->push_write ("A\012BC\012DEF\nG\012" . ("X" x 113) . "\012");
   undef $wr_ae;

   $rd_ae->push_read (netstring => sub { is ($_[1], "0:xx,,") });
   $rd_ae->push_read (netstring => sub { is ($_[1], "") });
   $rd_ae->push_read (storable => "w", sub { is ("@{$_[1]}", "4 3 2") });
   $rd_ae->push_read (packstring => "w", sub { is ($_[1], "hallole" x 99999) });

   $cv->wait;

   is ($concat, "A:BC:DEF:G:" . ("X" x 113) . ":", 'second set of lines were read correctly');
}

