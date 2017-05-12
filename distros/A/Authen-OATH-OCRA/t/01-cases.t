use Authen::OATH::OCRA;
use Test::More tests => 72;
use strict;
my $key20 = '3132333435363738393031323334353637383930';
my $key32
    = '3132333435363738393031323334353637383930313233343536373839303132';
my $key64
    = '31323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334';
my $pin = '7110eda4d09e062aa5e4a390b0a572ac0d2c0220';

my $testvectors = [
    { question => '00000000', ocra => '237653' },
    { question => '11111111', ocra => '243178' },
    { question => '22222222', ocra => '653583' },
    { question => '33333333', ocra => '740991' },
    { question => '44444444', ocra => '608993' },
    { question => '55555555', ocra => '388898' },
    { question => '66666666', ocra => '816933' },
    { question => '77777777', ocra => '224598' },
    { question => '88888888', ocra => '750600' },
    { question => '99999999', ocra => '294470' }
];

my $question;

my $oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QN08',
    key       => $key20
);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA1-6:QN08 with question ' . $_->{question} );
}

$testvectors = [
    { counter => '00000', question => '00000000', ocra => '07016083' },
    { counter => '00001', question => '11111111', ocra => '63947962' },
    { counter => '00002', question => '22222222', ocra => '70123924' },
    { counter => '00003', question => '33333333', ocra => '25341727' },
    { counter => '00004', question => '44444444', ocra => '33203315' },
    { counter => '00005', question => '55555555', ocra => '34205738' },
    { counter => '00006', question => '66666666', ocra => '44343969' },
    { counter => '00007', question => '77777777', ocra => '51946085' },
    { counter => '00008', question => '88888888', ocra => '20403879' },
    { counter => '00009', question => '99999999', ocra => '31409299' },
];
my $counter;
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA512-8:C-QN08',
    key       => $key64
);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    $oath->counter( $_->{counter} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA512-8:C-QN08 with counter '
            . $_->{counter}
            . ' and question '
            . $_->{question}
    );
}

$testvectors = [
    { counter => '0', question => '12345678', ocra => '65347737' },
    { counter => '1', question => '12345678', ocra => '86775851' },
    { counter => '2', question => '12345678', ocra => '78192410' },
    { counter => '3', question => '12345678', ocra => '71565254' },
    { counter => '4', question => '12345678', ocra => '10104329' },
    { counter => '5', question => '12345678', ocra => '65983500' },
    { counter => '6', question => '12345678', ocra => '70069104' },
    { counter => '7', question => '12345678', ocra => '91771096' },
    { counter => '8', question => '12345678', ocra => '75011558' },
    { counter => '9', question => '12345678', ocra => '08522129' },
];

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA256-8:C-QN08-PSHA1',
    key       => $key32,
    password  => $pin

);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    $oath->counter( $_->{counter} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA256-8:C-QN08-PSHA1 with counter '
            . $_->{counter}
            . ' and question '
            . $_->{question}
    );
}

$testvectors = [
    { question => '00000000', ocra => '83238735' },
    { question => '11111111', ocra => '01501458' },
    { question => '22222222', ocra => '17957585' },
    { question => '33333333', ocra => '86776967' },
    { question => '44444444', ocra => '86807031' },
];

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA256-8:QN08-PSHA1',
    key       => $key32,
    password  => $pin
);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA256-8:QN08-PSHA1 with question ' . $_->{question} );
}

$testvectors = [
    { question => '00000000', time => '20107446', ocra => '95209754' },
    { question => '11111111', time => '20107446', ocra => '55907591' },
    { question => '22222222', time => '20107446', ocra => '22048402' },
    { question => '33333333', time => '20107446', ocra => '24218844' },
    { question => '44444444', time => '20107446', ocra => '36209546' },
];

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA512-8:QN08-T1M',
    key       => $key64

);

foreach ( @{$testvectors} ) {
    $oath->timestamp( $_->{time} );
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA512-8:QN08-T1M with timestamp '
            . $_->{time}
            . ' and question '
            . $_->{question}
    );
}

$testvectors = [
    { question => 'CLI22220SRV11110', ocra => '28247970' },
    { question => 'CLI22221SRV11111', ocra => '01984843' },
    { question => 'CLI22222SRV11112', ocra => '65387857' },
    { question => 'CLI22223SRV11113', ocra => '03351211' },
    { question => 'CLI22224SRV11114', ocra => '83412541' },
];
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA256-8:QA08',
    key       => $key32
);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA256-8:QA08 with question ' . $_->{question} );
}

$testvectors = [
    { question => 'SRV11110CLI22220', ocra => '15510767' },
    { question => 'SRV11111CLI22221', ocra => '90175646' },
    { question => 'SRV11112CLI22222', ocra => '33777207' },
    { question => 'SRV11113CLI22223', ocra => '95285278' },
    { question => 'SRV11114CLI22224', ocra => '28934924' },
];
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA256-8:QA08',
    key       => $key32

);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA256-8:QA08 with question ' . $_->{question} );
}

$testvectors = [
    { question => 'CLI22220SRV11110', ocra => '79496648' },
    { question => 'CLI22221SRV11111', ocra => '76831980' },
    { question => 'CLI22222SRV11112', ocra => '12250499' },
    { question => 'CLI22223SRV11113', ocra => '90856481' },
    { question => 'CLI22224SRV11114', ocra => '12761449' },
];
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA512-8:QA08',
    key       => $key64,

);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA512-8:QA08 with question ' . $_->{question} );
}

$testvectors = [
    { question => 'SRV11110CLI22220', ocra => '18806276' },
    { question => 'SRV11111CLI22221', ocra => '70020315' },
    { question => 'SRV11112CLI22222', ocra => '01600026' },
    { question => 'SRV11113CLI22223', ocra => '18951020' },
    { question => 'SRV11114CLI22224', ocra => '32528969' },
];
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA512-8:QA08-PSHA1',
    key       => $key64,

    password => $pin
);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA512-8:QA08-PSHA1 with question ' . $_->{question} );
}

$testvectors = [
    { question => 'SIG10000', ocra => '53095496' },
    { question => 'SIG11000', ocra => '04110475' },
    { question => 'SIG12000', ocra => '31331128' },
    { question => 'SIG13000', ocra => '76028668' },
    { question => 'SIG14000', ocra => '46554205' },
];
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA256-8:QA08',
    key       => $key32,

);
foreach ( @{$testvectors} ) {
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA256-8:QA08 with question ' . $_->{question} );
}

$testvectors = [
    { question => 'SIG1000000', time => '20107446', ocra => '77537423' },
    { question => 'SIG1100000', time => '20107446', ocra => '31970405' },
    { question => 'SIG1200000', time => '20107446', ocra => '10235557' },
    { question => 'SIG1300000', time => '20107446', ocra => '95213541' },
    { question => 'SIG1400000', time => '20107446', ocra => '65360607' },
];

$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA512-8:QA10-T1M',
    key       => $key64,

);
foreach ( @{$testvectors} ) {
    $oath->timestamp( $_->{time} );
    $oath->question( $_->{question} );
    ok( $oath->ocra() eq $_->{ocra},
        'OCRA-1:HOTP-SHA512-8:QN08-T1M with timestamp '
            . $_->{time}
            . ' and question '
            . $_->{question}
    );
}

$oath = Authen::OATH::OCRA->new(
    ocrasuite           => 'OCRA-1:HOTP-SHA1-6:QH08-S10',
    key                 => $key20,
    question            => '11111111',
    session_information => '1234567890'
);
ok( $oath->ocra(),
          'OCRA-1:HOTP-SHA1-6:QH08-S10 with session_information '
        . $oath->session_information
        . ' and question '
        . $oath->question );
$oath = Authen::OATH::OCRA->new(
    ocrasuite => 'OCRA-1:HOTP-SHA1-6:QH32-T1H',
    question  => 'cafe',
    key       => '7110eda4d09e062aa5e4a390b0a572ac0d2c0220'
);
ok( $oath->ocra(), 'OCRA-1:HOTP-SHA1-6:QA32-T1H with dynamic timestamp' );
