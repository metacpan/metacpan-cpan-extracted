#!/usr/bin/perl -w

use warnings;
use strict;
use lib qw(./t);
use English qw(-no_match_vars);

# Track warnings down during debugging
#use Carp;$SIG{__WARN__} = \&Carp::cluck;

BEGIN
{ 
   # use a BEGIN block to get variables in SOAP::Lite::Constants at compile time
   use Test::More tests => 8;
   use_ok('CAM::SOAPApp', 'lenient' => 1);  # Need lenient to work around warning in SOAP::Lite v0.67
   use_ok('Example::Server');
}

my $PORT = 9670; # an arbitrary choice
my $TIMEOUT = 5; # seconds

if ($OSNAME eq 'darwin' && $ENV{HOST} && $ENV{HOST} eq 'chris.clotho.com')
{
   # Developer workaround for MacOSX issue where port is busy on
   # subsequent runs of this test because the OS holds the listening
   # port open too long.  So, we vary the port number semi-randomly.

   $PORT += (time)%10;
}

SKIP: {

   if (! -f 't/ENABLED')
   {
      skip('User elected to skip tests.',
           # Hack: get the number of tests we expect, skip all but one
           # This hack relies on the soliton nature of Test::Builder
           Test::Builder->new()->expected_tests() - 
           Test::Builder->new()->current_test());
   }

   my $child = fork;
   if ($child)
   {
      # We're the parent, continue below
   }
   elsif (defined $child)
   {
      
      # We're in the child.  Launch the server and continue until parent
      # kills us, or we time out.
      
      $SIG{ALRM} = sub {exit 1};
      alarm $TIMEOUT;
      runServer();
      exit 0;
   }
   else
   {
      die "Fork error...\n";
   }
   
   pass('forked off a server daemon process, waiting 2 seconds');
   
   sleep 2; # wait for server
   
   require IO::Socket;
   my $s = IO::Socket::INET->new(PeerAddr => "localhost:$PORT",
                                 Timeout  => 10);
   ok($s, 'server is running');
   if ($s)
   {
      close $s;
   }

   my $som;
   my $result;
   my $uri = 'http://localhost/Example/Server';
   my $soap = SOAP::Lite->can('ns') ? SOAP::Lite->ns($uri) : SOAP::Lite->uri($uri);
   my $client = $soap
       -> proxy("http://localhost:$PORT/")
       -> on_fault( sub { my ($soap, $fault) = @_;
                          $main::error = ref $fault ? $fault->faultcode() : 'Unknown'; } );

   my $prefix = $SOAP::Constants::PREFIX_ENV || 'SOAP-ENV';
   call($client, 'isLeapYear', [             ], [0, $prefix.':NoYear'], 'Fault: NoYear');
   call($client, 'isLeapYear', [year => 'doh'], [0, $prefix.':BadYear'],'Fault: BadYear');
   call($client, 'isLeapYear', [year => 1996 ], [1, 1], '1996 is a leap year');
   call($client, 'isLeapYear', [year => 2003 ], [1, 0], '2003 is not a leap year');

   # Stop the server
   $client->call('quit');
   kill 9, $child; # just in case
}

exit 0;

sub call
{
   my $client = shift;
   my $method = shift;
   my $args = shift;
   my $expect = shift;
   my $desc = shift;

   my @args = ();
   for (my $i=0; $i<@{$args}; $i+=2)
   {
      my $key = $args->[$i];
      my $val = $args->[$i+1];
      push @args, SOAP::Data->name($key, $val);
   }
   
   $main::error = q{};
   my $som = $client->call($method, @args);
   if ($expect->[0])
   {
      if (ref $som)
      {
         is($som->result(), $expect->[1], $desc);
      }
      else
      {
         fail($desc);
      }
   }
   else
   {
      if (ref $som)
      {
         fail($desc);
      }
      else
      {
         is($som, $expect->[1], $desc);
      }
   }
   return;
}

sub runServer
{
   require SOAP::Transport::HTTP;
   SOAP::Transport::HTTP::Daemon
       -> new(LocalAddr => 'localhost', LocalPort => $PORT)
       -> dispatch_to('Example::Server')
       #-> on_fault( sub {} )
       -> handle;

   return;
}
