#!/usr/bin/perl

use strict;
use CPAN::CachingProxy;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

die "please use 'wget -qO - http://www.cpan.org/MIRRORED.BY | grep dst_http | less' to select a proxy";

my $mirror   = "http://www.perl.com/FAKE";
my $keyspace = "CK0"; # just increment this to "reset" the cache

CPAN::CachingProxy->new(

       mirrors => [$mirror],
     key_space => $keyspace,
    cache_root => "/home/voltar/nobody.cache/",
         debug => 0,

)->run;

