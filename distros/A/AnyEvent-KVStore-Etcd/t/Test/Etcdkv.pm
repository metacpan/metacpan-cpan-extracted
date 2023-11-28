=head1 NAME

   Test::Etcdkv -- Testing setup for etcd

=cut

package Test::Etcdkv;

=head1 SYNOPSIS 

   use Test::Etcdkv;
   my $guard = Test::Etcdkv->guard;
   $config = Test::Etcdkv->config;

   # do tests here
   #
   undef $guard; #optional, will get called at end of script.

=cut

use strict;
use warnings;
use Test::More;
use Capture::Tiny;
use File::Path qw(rmtree);

=head1 DESCRIPTION

This module sets up the etcd testing parameters.  In this case etcd will be set
up as a standalone system, without peers listening on a port defined in the
environment variables set in t/README.txt.  Config information is available
with the config() method of this package.

=cut

sub import {
    plan (skip_all => 'TEST_ETCD not set') unless $ENV{TEST_ETCD};
    plan (skip_all => 'TEST_ETCD_PORT needed') unless $ENV{TEST_ETCD_PORT};
    start_etcd();
}

my $pid;

my $port;

sub start_etcd {
    $port = $ENV{TEST_ETCD_PORT};
    my $url = "http://127.0.0.1:$port";
    my $path = '';
    $path = $ENV{BAGGER_TEST_ETCD_PATH} if $ENV{TEST_ETCD_PATH};
    $path .= '/' if $path and ($path !~ m|/$|);
    $path .= 'etcd' unless $path =~ 'etcd$';
    if ($pid = fork){
        # nothing to do
    } else {
        capture {
          rmtree 't/data'; # etcd data dir
          system($path, '--listen-client-urls', $url,
              '--advertise-client-urls', $url, '--data-dir', 't/data',
              '--log-level=error', '--logger=zap'
          );
        }; # and do nothing with it
    }
}

sub config { { host => '127.0.0.1', port => $port } }
sub cleanup {
    kill(15, $pid);
    system('fuser', '-k', '-n', 'tcp', $ENV{TEST_ETCD_PORT});
}

sub DESTROY { cleanup }

=head2 guard

Returns a guard that runs cleanup() when it goes out of scope.  This allows for
automatic cleanup to the extent permitted by circumstance.

=cut

sub guard {
    my $pkg = __PACKAGE__;
    my $guard = \$pkg;
    bless $guard;
}

1;
