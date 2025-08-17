#!/usr/bin/env perl

use Test2::V0 -target => 'Data::KSUID';
use Test2::Tools::Spec;

tests create => sub {
    ok CLASS->new, 'Creates a random KSUID';

    ok my $k1 = CLASS->new( my $time = time + 1000 ),
        'Creates a random KSUID with a timestamp';

    ok my $k2 = CLASS->new( undef, "\xde\xfa\xce\xd0" x 4 ),
        'Creates a random KSUID with a payload';

    is $k1->time, $time,
        'Created KSUID with specified time';

    is $k2->payload, "\xde\xfa\xce\xd0" x 4,
        'Created KSUID with specified payload';

    like dies { CLASS->new("tomorrow") },
        qr/^Timestamp must be numeric/,
        'Rejects timestamps that are not numbers';

    like dies { CLASS->new( -123) },
        qr/^Timestamp must be between 0 and/,
        'Rejects timestamps that are too small';

    like dies { CLASS->new( 999999999999999 ) },
        qr/^Timestamp must be between 0 and/,
        'Rejects timestamps that are too big';

    like dies { CLASS->new( undef, "\x01" x 15 ) },
        qr/^KSUID payloads must have 16 bytes, got instead 15/,
        'Rejects payloads that are too small';

    like dies { CLASS->new( undef, "\x01" x 17 ) },
        qr/^KSUID payloads must have 16 bytes, got instead 17/,
        'Rejects payloads that are too big';
};

describe serde => sub {
    tests random => sub {
        my $k = CLASS->new;
        my $s = $k->string;

        is length($s), 27, 'Serialised to 27-char string';
        is CLASS->parse($s), $k, 'Roundtrips OK';
    };

    tests known => sub {
        my $time = 1755084253;
        my $payload = "\xde\xfa\xce\xd0" x 4;

        my $k = CLASS->new( $time, $payload );
        my $s = $k->string;

        is $s, '31ELOc2E4AznzCCUDuq2hN3CIee', 'Expected string';
    };
};

tests sequence => sub {
    my $this = CLASS->new;
    ok my $next = $this->next, 'Can create next KSUID';
    ok my $prev = $this->previous, 'Can create previous KSUID';

    cmp_ok $this, 'eq', $this, 'Sanity check';
    cmp_ok $this, 'gt', $prev, 'Previous KSUID sorts earlier';
    cmp_ok $this, 'lt', $next, 'Next KSUID sorts later';

    my $tail = sub {
        unpack( 'C', substr( shift->bytes, -1 ) );
    };

    is $this->$tail, ( $next->$tail - 1 ) % 256,
        'Next is one more than this';

    is $this->$tail, ( $prev->$tail + 1 ) % 256,
        'Previous is one less than this';
};

done_testing;
