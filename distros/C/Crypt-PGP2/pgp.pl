#!/usr/bin/perl -Tw

$ENV{'PATH'} = '';

use strict;      # must scope all symbols
use diagnostics; # lint checking and verbose warnings

my $pipe_failed = 0;

$SIG{'PIPE'} = &watch_for_sigpipe;

use Crypt::PGP2;

   my $plaintext = 'Sample plaintext';
   my ($ciphertext, $msg, $error) = encrypt($plaintext,'james','at');

   if ($error == PGP_ERR_SUCCESS) {
      print "Ciphertext: $ciphertext\nMsg: $msg\nError: $error\n";
   }
   else {
      print "PGP error: $error\n";
   }

   print "Likely SIGPIPE caught in IPC::Open3." if $pipe_failed;

sub watch_for_sigpipe {
   $pipe_failed++;
}

