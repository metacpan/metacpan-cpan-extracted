#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
BEGIN { use_ok('Apache::Sling') };
# sling object:
my $sling = Apache::Sling->new(16);
isa_ok $sling, 'Apache::Sling', 'sling';
ok( $sling->{ 'MaxForks' } eq '16', 'Check MaxForks set' );
ok( $sling->check_forks, 'check check_forks function threads undefined' );
$sling->{'Threads'} = 0;
ok( $sling->check_forks, 'check check_forks function threads 0' );
$sling->{'Threads'} = 8;
ok( $sling->check_forks, 'check check_forks function threads normal' );
$sling->{'Threads'} = 'eight';
ok( $sling->check_forks, 'check check_forks function threads written' );
$sling->{'Threads'} = 17;
ok( $sling->check_forks, 'check check_forks function threads bigger than max' );
