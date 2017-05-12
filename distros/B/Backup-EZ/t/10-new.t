#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;

my $ez = Backup::EZ->new( conf      => 'share/ezbackup.conf',
						  exclude_file => 'share/ezbackup_exclude.rsync'
);
ok($ez);

done_testing();
