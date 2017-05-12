#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;

my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');
my $rv;

my $sth = $dbh->select(
                                     -table => 'album',
                                     -fields => 'album_id',                                     
                                     -where => [album_id => ['d',1]],
                                     -rawsth => 1,
                                    );
      

# Uncomment this execute to get the test to pass. The bug is that this execute
# should not be necessary
#$sth->execute();

# Get the first album row (Note that sqlite uses 'undef' when a result set has
# been exhausted, and also when there is an error).
my $result = $sth->fetchrow_hashref;

ok ($result, "fetchrow_hashref");

done_testing();
