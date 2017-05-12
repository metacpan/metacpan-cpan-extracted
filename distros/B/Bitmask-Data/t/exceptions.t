# -*- perl -*-

# t/basic.t - check exceptions

use Test::More tests=>17;
use Test::Warn;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use Testmask1;

my $tm = Testmask1->new();

my @broken_input = (
    'hase', qr/Could not turn <hase> into something meaningful/,
    262143, qr/<262143> exceeds maximum lenth of 16/,
    '0b11001010101010101', qr/<0b11001010101010101> exceeds maximum lenth of 16/,
    'value99', qr/Could not turn <value99> into something meaningful/,
    ['value1',262149], qr/<262149> exceeds maximum lenth of 16/,
    '0b1100101010101010', qr/<0b1100101010101010> tries to set undefined bits/,
);

while (scalar @broken_input ) {
    my $test = shift @broken_input;
    my $error = shift @broken_input;
    $@ = '';
    eval {
        $tm->add($test);
    };
    like($@,$error);
}

push @Exceptionmask::ISA,qw(Bitmask::Data);

Exceptionmask->bitmask_length(undef);
eval {
    Exceptionmask->init(
        'hase',
        'baer',
        'luchs'
    );
};
like($@,qr/Bitmask length not set/);

Exceptionmask->bitmask_length(-1);
eval {
    Exceptionmask->init(
        'hase',
        'baer',
        'luchs'
    );
};
like($@,qr/Bitmask length not set/);

Exceptionmask->bitmask_length(4);
Exceptionmask->bitmask_default(16);
Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->init(
        'hase'  => 1,
        'baer'  => 2,
        'luchs' => 4,
        'eber'  => 8,
    );
};
like($@,qr/<16> exceeds maximum lenth of 4/);

Exceptionmask->bitmask_default(undef);

warnings_like {
    Exceptionmask->init(
        'hase',
        'baer',
        'luchs',
        'sackratte',
    );
} [qr/Lazy bitmask initialization detected/,qr/Lazy bitmask initialization detected/,qr/Lazy bitmask initialization detected/,qr/Lazy bitmask initialization detected/], "Lazy init warning";

Exceptionmask->bitmask_items({});

eval {
    Exceptionmask->init(
        'hase' => 1,
        'baer' => 2,
        'luchs' => 4,
        'sackratte' => 8,
        'maus' => 16
    );
};
like($@,qr/Too many values in bitmask: max/);

Exceptionmask->bitmask_lazyinit(1);
Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->init(
        'hase',
        'baer',
        'baer',
        'luchs',
    );
};
like($@,qr/Duplicate value <\w+> in bitmask/);

Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->init(
        'hase'      => 1,
        'baer'      => 2,
        'luchs'     => 4,
        'sackratte' => 4,
    );
};
like($@,qr/Duplicate bit <[01]+> in bitmask/);


Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->init(
        'hase'      => 1,
        'baer'      => 2,
        'luchs'     => 3,
        'sackratte' => 8,
    );
};
like($@,qr/Duplicate bit <[01]+> in bitmask/);


Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->new();
};
like($@,qr/Bitmask not initialized/);

Exceptionmask->bitmask_length(4);
Exceptionmask->bitmask_items({});
eval {
    Exceptionmask->init(
        'hase'      => '0b0001',
        'baer'      => 2,
        'luchs'     => 4,
        'sackratte' => 16,
    );
};
like($@,qr/Invalid bit value/);
