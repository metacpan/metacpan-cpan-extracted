#!/usr/bin/perl

use strict;
use warnings;

use Mojo::File qw(curfile);
use lib curfile->dirname->child('..','lib')->to_string;

use DNS::Hetzner;
use Data::Printer;

my $dns = DNS::Hetzner->new(
    token => $ENV{HETZNER_DNS_TOKEN} || 'ABCDEFG1234567',    # your api token
);

my $records = $dns->records;

my $res = $records->create(
    name    => '1235.test',
    value   => '193.148.166.125',
    type    => 'A',
    zone_id => 'zone_id',
);

p $res;

