#!/usr/bin/env perl
# This script demonstrates our Apache simulation.
#
# First, start the daemon:    ./apache.pl -vvv
# Don't forget to check /var/log/messages!
# Also, Any-Daemon/examples/net.pl show other tricks.

use warnings;
use strict;

use Log::Report;
use Any::Daemon::HTTP;

use Getopt::Long     qw/GetOptions :config no_ignore_case bundling/;

#
## get command-line options
#

my $mode     = 0;     # increase output

my %os_opts  =
  ( pid_file   => '/tmp/apache.pid'  # usually in /var/run
  , user       => undef
  , group      => undef
  );

my %run_opts =
  ( background => 1
  , max_childs => 1
# , max_conn_per_child =>  10_000
# , max_req_per_child  => 100_000
# , max_req_per_conn   => 100
# , max_time_per_conn  => 120
# , req_time_bonus     =>   5
  );

my %net_opts =
  ( host       => 'localhost:5422'
  );

GetOptions
   'background|bg!' => \$run_opts{background}
 , 'childs|c=i'     => \$run_opts{max_childs}
 , 'group|g=s'      => \$os_opts{group}
 , 'host|h=s'       => \$net_opts{host}
 , 'pid-file|p=s'   => \$os_opts{pid_file}
 , 'user|u=s'       => \$os_opts{user}
 , 'v+'             => \$mode  # -v -vv -vvv
    or exit 1;

$run_opts{background} //= 1;

#
## initialize the daemon activities
#

# From now on, all errors and warnings are also sent to syslog,
# provided by Log::Report. Output still also to the screen.
dispatcher SYSLOG => 'syslog', accept => 'INFO-'
  , identity => 'any-httpd', facility => 'local0';

# Do not send info to the terminal anymore
#dispatcher close => 'default';

dispatcher mode => $mode, 'ALL' if $mode;

my $httpd = Any::Daemon::HTTP->new
  ( %net_opts
  , %os_opts
  , standard_headers =>
      [ X_Daemon => 'my-daemon v3'
      , X_More   => 'later'
      ]

# , proxies     =>
#    { forward_map    => 'RELAY'
#    }
  );

## Simpelest, auto-creates ::Directory
# $httpd->addVirtualHost
#   ( name      => 'test'
#   , aliases   => [$net_opts{host}]
#   , documents => '/etc'
#   );

## More complex, add one or more ::Directory's by config or object
my $vhost = $httpd->addVirtualHost
  ( name        => 'test'
  , aliases     => ['www.test.nl', 'www.example.org', $net_opts{host}, 'default']

  , directories =>
     { path           => '/'
     , location       => '/etc'
     , directory_list => 1
#    , allow          => '127.0.0.1/32'
     }

  , handlers    =>                   # Handlers run when no file is found
     { '/fake.cgi'    => \&fake_cgi  # looks like cgi, is internal function ;-)
     , '/form/submit' => \&form_in   # match all uri start with this
#    , '/'            => \&errors    # overrule default error page
     }

# , proxies     =>
  );

$httpd->run
  ( %run_opts
  );

exit 0;
