# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Convert-TLI.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => '5';
BEGIN { use_ok('Convert::TLI') };

#########################
my $tli = Convert::TLI->new();
ok( $tli->detect_tli('0x0002333337f00001'), "TLI detection" );
my ($ip, $port) = $tli->decode_tli('0x0002333337f00001');
ok( $ip eq '55.240.0.1', "Got IP" );
ok( $port eq '13107', "Got port" );
my $decoded =  $tli->encode_tli($ip,$port);
ok( $decoded eq '0x0002333337f00001', "Encoded TLI" );
