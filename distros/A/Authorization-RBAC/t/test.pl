#!/usr/bin/env perl
use strict;
use warnings;
use Authorization::RBAC;
use lib 't/lib';
use Cache::Memory;

#my $conf = 't/conf/permsfromfile.yml';
my $conf = 't/conf/permsfromdb.yml';

my $cache = Cache::Memory->new();

my $rbac = Authorization::RBAC->new( configfile => $conf,
                                     configword => 'Authorization::RBAC',
                                     cache      => $cache,
                                     debug => 1 );
$rbac->load_datas;

my $permission2 = {
                   operations => [ 'view', 'create' ],
                   typeobj    => 'Page',
                   unique     => '/an/inexistant/path',
                  };


# 10000 => 6.7s sans cache
my $t=2;

while ( $t) {
  my $res = $rbac->perm(['member'],   $permission2);
  print "res=$res\n\n";
  $t--;
}
