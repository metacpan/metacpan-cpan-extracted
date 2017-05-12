#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;
use Address::PostCode::Australia;

eval { Address::PostCode::Australia->new; };
like($@, qr/Missing required arguments: auth_key/);

my $address = Address::PostCode::Australia->new({ 'auth_key' => 'Dummy' });

eval { $address->details; };
like($@, qr/ERROR: Missing params list/);

eval { $address->details(1234); };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $address->details('XYZ12345'); };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $address->details('12345XYZ'); };
like($@, qr/ERROR: Parameters have to be hash ref/);

eval { $address->details({}); };
like($@, qr/ERROR: Missing required key postcode\/location/);
