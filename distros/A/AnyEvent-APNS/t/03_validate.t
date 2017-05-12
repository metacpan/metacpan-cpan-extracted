use utf8;
use Test::Base;

use AnyEvent::APNS;

use Test::Exception;
use Test::TCP;

plan tests => 4;

my $port = empty_port;

lives_ok {
    my $apns; $apns = AnyEvent::APNS->new(
        debug_port  => $port,
        certificate => 'dummy',
        private_key => 'dummy',
    );
} 'set certificate and private_key ok';

lives_ok {
    my $apns; $apns = AnyEvent::APNS->new(
        debug_port  => $port,
        certificate => \'dummy',
        private_key => \'dummy',
    );
} 'set certificate ref and private_key ref ok';

throws_ok {
    my $apns; $apns = AnyEvent::APNS->new(
        debug_port  => $port,
        private_key => 'dummy',
    );
} qr/certificate.+is required/
, 'not set certificate';

throws_ok {
    my $apns; $apns = AnyEvent::APNS->new(
        debug_port  => $port,
        certificate => 'dummy',
    );
} qr/private_key.+is required/
, 'not set private_key';
