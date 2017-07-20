use strict;
use warnings;

use Crypt::SRP;
use Test::More tests => 2;

my $Bytes_I  = '366B4165DD64AD3A';
my $Bytes_P  = '1234';
my $Bytes_s  = pack('H*', 'd62c98fe76c77ad445828c33063fc36f');
my $Bytes_B  = pack('H*', '4223ddb35967419ddfece40d6b552b797140129c1c262da1b83d413a7f9674aff834171336dabadf9faa95962331e44838d5f66c46649d583ee44827755651215dcd5881056f7fd7d6445b844ccc5793cc3bbd5887029a5abef8b173a3ad8f81326435e9d49818275734ef483b2541f4e2b99b838164ad5fe4a7cae40599fa41bd0e72cb5495bdd5189805da44b7df9b7ed29af326bb526725c2b1f4115f9d91e41638876eeb1db26ef6aed5373f72e3907cc72997ee9132a0dcafda24115730c9db904acbed6d81dc4b02200a5f5281bf321d5a3216a709191ce6ad36d383e79be76e37a2ed7082007c51717e099e7bedd7387c3f82a916d6aca2eb2b6ff3f3');
my $Bytes_a  = pack('H*', 'a18b940d3e1302e932a64defccf560a0714b3fa2683bbe3cea808b3abfa58b7d');

my $client = Crypt::SRP->new({ group => 'RFC5054-2048bit', hash => 'SHA1', appletv => 1 });
$client->client_init($Bytes_I, $Bytes_P, $Bytes_s, $Bytes_B, undef, $Bytes_a);

my $Bytes_M1 = $client->client_compute_M1();
my $Bytes_K  = $client->get_secret_K();

is(unpack('H*', $Bytes_K),  '9a689113a76b44583e73f9662eb172e830886ed988f04c6c0030f0e93c68784de27dbf30c5d151fb', 'test K');
is(unpack('H*', $Bytes_M1), '4b4e638bf08526e4229fd079675fedfd329b97ef', 'test M1');
