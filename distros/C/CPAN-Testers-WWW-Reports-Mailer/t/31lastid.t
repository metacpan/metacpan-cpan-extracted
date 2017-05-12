#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use IO::File;
use Test::More tests => 21;

use CPAN::Testers::WWW::Reports::Mailer;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';
my $LASTID = 't/_DBDIR/lastmail';

# -------------------------------------------------------------------
# Tests

unlink $LASTID;

SKIP: {
    skip "No supported databases available", 21  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );

    ok($obj->lastmail($LASTID),'reset last mail file');
    is($obj->lastmail,$LASTID, 'reset last mail');

    ok(!-f $LASTID, 'lastmail not created');
    is($obj->_get_lastid,0, 'new last id');
    ok(-f $LASTID, 'lastmail now exists');

    # defaults to daily mode
    ok($obj->_get_lastid(12), 'set last id - daily mode');
    is($obj->_get_lastid,12, 'get last id - daily mode');

    $obj->mode('weekly');
    ok($obj->_get_lastid(14), 'set last id - weekly mode');
    is($obj->_get_lastid,14, 'get last id - weekly mode');

    $obj->mode('reports');
    ok($obj->_get_lastid(16), 'set last id - reports mode');
    is($obj->_get_lastid,16, 'get last id - reports mode');

    $obj->mode('daily');
    is($obj->_get_lastid,12, 'get last id - daily mode still valid');
    $obj->mode('weekly');
    is($obj->_get_lastid,14, 'get last id - weekly mode still valid');
    $obj->mode('reports');
    is($obj->_get_lastid,16, 'get last id - reports mode still valid');

    my @lines = _readfile($obj->lastmail);
    is($lines[0],'daily=12,weekly=14,reports=16', 'read last id');

    $obj->mode('monthly');
    is($obj->_get_lastid,0, 'get last id - monthly mode zero');
    @lines = _readfile($obj->lastmail);
    is($lines[0],'daily=12,weekly=14,reports=16', 'read last id no monthly');

    ok($obj->_get_lastid(20), 'set last id - monthly mode');
    @lines = _readfile($obj->lastmail);
    is($lines[0],'daily=12,weekly=14,reports=16,monthly=20', 'read last id with monthly');
    is($obj->_get_lastid,20, 'get last id - monthly mode 20');
}

sub _readfile {
    my $file = shift;
    my $fh = IO::File->new($file,'r');
    my @lines = do { <$fh> };
    $fh->close;

    return @lines;
}
