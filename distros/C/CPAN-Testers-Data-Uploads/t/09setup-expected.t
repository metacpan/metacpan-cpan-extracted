#!/usr/bin/perl -w
use strict;

$|=1;

use Test::More tests => 1;
use Archive::Extract;

my $EXPECTEDPATH = 't';
my $ae = Archive::Extract->new( archive => 't/Expected.zip' );
ok( $ae->extract(to => $EXPECTEDPATH), 'extracted expected files' );
