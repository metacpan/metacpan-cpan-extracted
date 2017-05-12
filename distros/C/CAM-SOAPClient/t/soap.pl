#!/usr/bin/perl -w

use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/lib");
use English qw(-no_match_vars);
BEGIN
{
   eval {
      require CAM::SOAPApp;
      CAM::SOAPApp->import(lenient => 1);
   };
   if ($EVAL_ERROR)
   {
      die 'Could not find optional module CAM::SOAPApp needed for the advanced tests';
   }
}
use Example;
use SOAP::Transport::HTTP;

my $PORT = shift || 9674;
my $TIMEOUT = 600; # seconds

# This server will auto-terminate after TIMEOUT seconds
$SIG{ALRM} = sub{exit 0};
alarm $TIMEOUT;

SOAP::Transport::HTTP::Daemon
       -> new(LocalAddr => 'localhost', LocalPort => $PORT)
       -> dispatch_to('Example')
       -> handle;
