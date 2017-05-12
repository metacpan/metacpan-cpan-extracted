use Authen::OATH::OCRA;
use Test::More tests => 10;
use Test::Exception;
use strict;

my $key20 = '3132333435363738393031323334353637383930';
my $key32
    = '3132333435363738393031323334353637383930313233343536373839303132';
my $key64
    = '31323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334';
my $pin = '7110eda4d09e062aa5e4a390b0a572ac0d2c0220';

my $oath = Authen::OATH::OCRA->new(

    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08',
    key       => $key20,
);
throws_ok { $oath->ocra() } qr/Parameter "question" is required/,
    'No question';

$oath = Authen::OATH::OCRA->new(

    ocrasuite => 'THIS-IS-NO-OCRASUITE',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() } qr/Invalid ocrasuite/, 'Invalid ocrasuite';

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA1-3:QN08',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() } qr/Must request at least 4 digits/,
    'More digits than allowed';

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA1-11:QN08',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() } qr/Must request at most 10 digits/,
    'Fewer digits than allowed';

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08',
    question  => '1234'
);
throws_ok { $oath->ocra() } qr/Parameter "key" is required/, 'No key';
$oath = Authen::OATH::OCRA->new(
    key      => $key20,
    question => '1234'
);
throws_ok { $oath->ocra() } qr/Parameter "ocrasuite" is required/,
    'No ocrasuite';

$oath = Authen::OATH::OCRA->new(

    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08-PSHA1',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() }
qr/Parameter "password" is required for the provided ocrasuite/,
    'No password';

$oath = Authen::OATH::OCRA->new(

    ocrasuite => 'OCRA-1:HOTP-SHA1-6:C-QN08',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() }
qr/Parameter "counter" is required for the provided ocrasuite/, 'No counter';
$oath = Authen::OATH::OCRA->new(

    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08-S10',
    key       => $key20,
    question  => '1234'
);
throws_ok { $oath->ocra() }
qr/Parameter "session_information" is required for the provided ocrasuite/,
    'No session_information';

$oath = Authen::OATH::OCRA->new(

    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08',
    key       => $key20,
    question  => 'THIS_IS_NO_HEX'
);
throws_ok { $oath->ocra() }
qr/: not in hex format/,
    'No hex format';

