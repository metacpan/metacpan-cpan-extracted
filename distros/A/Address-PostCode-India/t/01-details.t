#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use Address::PostCode::India;

my $address = Address::PostCode::India->new;

eval { $address->details; };
like($@, qr/ERROR: Missing required param 'pin code'/);

eval { $address->details('xyz'); };
like($@, qr/ERROR: Invalid pin code/);

eval { $address->details(1234567); };
like($@, qr/ERROR: Invalid pin code/);
