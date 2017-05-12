#!/usr/bin/perl -w

my $loaded;

use strict;

use Tie::Hash::Transactional;

BEGIN { $| = 1; print "1..2\n"; }

my $warning = undef;
$SIG{__WARN__} = sub { $warning = shift; };

my $test = 0;

tie my %hash, 'Tie::Hash::Transactional';
print 'not ' unless(defined($warning));
print 'ok '.(++$test)." emit warnings when nowarn not specified\n";
undef $warning;

tie %hash, 'Tie::Hash::Transactional', nowarn => 1;
print 'not ' if(defined($warning));
print 'ok '.(++$test)." don't emit warnings when nowarn specified\n";
