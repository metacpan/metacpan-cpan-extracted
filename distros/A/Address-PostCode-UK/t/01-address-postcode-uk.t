#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Address::PostCode::UK;

my $address = Address::PostCode::UK->new;

eval { $address->details; };
like($@, qr/ERROR: Missing required param 'post code'/);

eval { $address->details(1234); };
like($@, qr/ERROR: Invalid format for UK post code/);

eval { $address->details('XYZ12345'); };
like($@, qr/ERROR: Invalid format for UK post code/);

eval { $address->details('12345XYZ'); };
like($@, qr/ERROR: Invalid format for UK post code/);
