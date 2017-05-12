#!/usr/bin/env perl
# This script can be used as template for daemons.
# First, start the daemon.
#   ./net.pl -vvv
# Then you may run the test with
#   echo "ping" | netcat localhost 5422
#   kill $(cat /tmp/net.pid)
# Don't forget to check /var/log/messages!

# Also, have a look at the example script of Any::Daemon::HTTP

use warnings;
use strict;

use Log::Report 'any-daemon-example';
use Any::Daemon;

use Getopt::Long     qw/GetOptions :config no_ignore_case bundling/;
use IO::Socket::INET ();

#
## get command-line options
#

my $mode     = 0;     # increase output

my %os_opts  =
  ( pid_file   => '/tmp/net.pid'  # usually in /var/run
  , user       => undef
  , group      => undef
  );

my %run_opts =
  ( background => 1
  , max_childs => 1    # there can only be one multiplexer
  );

my %net_opts =
  ( host       => 'localhost:5422'
  , port       => undef
  );

GetOptions
   'background|bg!' => \$run_opts{background}
 , 'childs|c=i'     => \$run_opts{max_childs}
 , 'group|g=s'      => \$os_opts{group}
 , 'host|h=s'       => \$net_opts{host}
 , 'pid-file|p=s'   => \$os_opts{pid_file}
 , 'port|p=s'       => \$net_opts{port}
 , 'user|u=s'       => \$os_opts{user}
 , 'v+'             => \$mode  # -v -vv -vvv
    or exit 1;

$run_opts{background} //= 1;

unless(defined $net_opts{port})
{   my $port = $net_opts{port} = $1
        if $net_opts{host} =~ s/\:([0-9]+)$//;
    defined $port or error __"no port specified";
}

#
## initialize the daemon activities
#

# From now on, all errors and warnings are also sent to syslog,
# provided by Log::Report. Output still also to the screen.
dispatcher SYSLOG => 'syslog', accept => 'INFO-'
  , identity => 'any-daemon-test', facility => 'local0';

# Do not send info to the terminal anymore
# dispatcher close => 'default';

dispatcher mode => $mode, 'ALL' if $mode;

my $socket = IO::Socket::INET->new
  ( LocalHost => $net_opts{host}
  , LocalPort => $net_opts{port}
  , Listen    => 5
  , Reuse     => 1
  ) or fault __x"cannot create socket at {host}:{port}"
        , host => $net_opts{host}, port => $net_opts{port};

my $daemon = Any::Daemon->new(%os_opts);

$daemon->run
  ( child_task => \&run_task
  , %run_opts
  );

exit 1;   # will never be called

sub run_task()
{
    while(my $client = $socket->accept)
    {   info __x"new client {host}", host => $client->peerhost;
        my $line = <$client>;
        chomp $line;
        info __x"received {line}", line => $line;
        $client->print(scalar(reverse $line), "\n");
        $client->close;
    }

    exit 0;
}

1;
