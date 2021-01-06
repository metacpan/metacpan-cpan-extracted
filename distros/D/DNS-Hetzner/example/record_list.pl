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

my $all_records = $records->list();
p $all_records;

