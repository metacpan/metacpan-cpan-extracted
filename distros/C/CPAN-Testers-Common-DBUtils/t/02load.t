#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Common::DBUtils;
use Test::More tests => 3;

my ($ct,%options);

eval { $ct = CPAN::Testers::Common::DBUtils->new(%options) };
like($@,qr/needs a driver/);

$options{driver} = 'Test';
eval { $ct = CPAN::Testers::Common::DBUtils->new(%options) };
like($@,qr/needs a database/);

$options{dbfile} = 'Test';
eval { $ct = CPAN::Testers::Common::DBUtils->new(%options) };
is($@,'');
