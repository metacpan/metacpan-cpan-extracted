#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::PEM ':all';
use Crypt::Bear::PEM::Decoder;

my $payload = 'blablabla';

my $encoded = pem_encode('CERTIFICATE', $payload);

my ($name, $decoded) = pem_decode($encoded);

is $name, 'CERTIFICATE', 'Banner is as expected';
is $payload, $decoded, 'Payload is as expected';

done_testing;
