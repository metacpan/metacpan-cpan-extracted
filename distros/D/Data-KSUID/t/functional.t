#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;

use Data::KSUID ':all';

describe create => sub {
    my ( $new, $to_ksuid );

    case binary => sub {
        $new = \&Data::KSUID::create_ksuid;
        $to_ksuid = sub { shift };
    };

    case string => sub {
        $new = \&Data::KSUID::create_ksuid_string;
        $to_ksuid = sub { goto \&string_to_ksuid };
    };

    it works => { flat => 1 } => sub {
        ok $new->(), 'Creates a random KSUID';

        ok my $k1 = $new->( my $time = time + 1000 ),
            'Creates a random KSUID with a timestamp';

        ok my $k2 = $new->( undef, "\xde\xfa\xce\xd0" x 4 ),
            'Creates a random KSUID with a payload';

        is time_of_ksuid($k1->$to_ksuid), $time,
            'Created KSUID with specified time';

        is payload_of_ksuid($k2->$to_ksuid), "\xde\xfa\xce\xd0" x 4,
            'Created KSUID with specified payload';

        like dies { $new->("tomorrow") },
            qr/^Timestamp must be numeric/,
            'Rejects timestamps that are not numbers';

        like dies { $new->(-123) },
            qr/^Timestamp must be between 0 and/,
            'Rejects timestamps that are too small';

        like dies { $new->(999999999999999) },
            qr/^Timestamp must be between 0 and/,
            'Rejects timestamps that are too big';

        like dies { $new->( undef, "\x01" x 15 ) },
            qr/^KSUID payloads must have 16 bytes, got instead 15/,
            'Rejects payloads that are too small';

        like dies { $new->( undef, "\x01" x 17 ) },
            qr/^KSUID payloads must have 16 bytes, got instead 17/,
            'Rejects payloads that are too big';
    };
};

describe serde => sub {
    tests random => sub {
        my $k = create_ksuid;
        my $s = ksuid_to_string $k;

        is length($s), 27, 'Serialised to 27-char string';
        is string_to_ksuid($s), $k, 'Roundtrips OK';
    };

    tests known => sub {
        my $time = 1755084253;
        my $payload = "\xde\xfa\xce\xd0" x 4;

        my $k = create_ksuid( $time, $payload );
        my $s = ksuid_to_string($k);

        is $s, '31ELOc2E4AznzCCUDuq2hN3CIee', 'Expected string';
    };
};

describe validation => sub {
    describe explicit => sub {
        my $code;

        case is_ksuid_string => sub {
            $code = \&Data::KSUID::is_ksuid_string;
        };

        case is_ksuid => sub {
            $code = \&Data::KSUID::is_ksuid;
        };

        it works => { flat => 1 } => sub {
            is $code->(), F,
                'Rejects implicit undef';

            is $code->(undef), F,
                'Rejects implicit undef';

            is $code->(123), F,
                'Rejects positive numeric';

            is $code->(-123), F,
                'Rejects negative numeric';

            is $code->(''), F,
                'Rejects the empty string';

            is $code->('z' x 27), F,
                'Rejects string beyond upper boundary';
        };
    };

    describe implicit => sub {
        my ( $code, $error );

        before_case reset => sub { undef $error };

        case string_to_ksuid => sub {
            $code = \&Data::KSUID::string_to_ksuid;
            $error = qr/^Expected a string KSUID/;
        };

        for my $name (qw(
            ksuid_to_string
            next_ksuid
            payload_of_ksuid
            previous_ksuid
            time_of_ksuid
        )) {
            case $name => sub {
                $code = Data::KSUID->can($name);
            };
        }

        tests 'bad data' => sub {
            $error //= qr/^Expected a valid KSUID/;

            like dies { $code->() },
                qr/$error, got instead an undefined value/,
                'Rejects implicit undef';

            like dies { $code->(undef) },
                qr/$error, got instead an undefined value/,
                'Rejects implicit undef';

            like dies { $code->(123) },
                qr/$error, got instead "123"/,
                'Rejects positive numeric';

            like dies { $code->(-123) },
                qr/$error, got instead "-123"/,
                'Rejects negative numeric';

            like dies { $code->('') },
                qr/$error, got instead ""/,
                'Rejects the empty string';

            like dies { $code->('z' x 27) },
                qr/$error, got instead "z{27}"/,
                'Rejects string beyond upper boundary';
        };
    };
};

tests sequence => sub {
    my $this = create_ksuid;
    ok my $next = next_ksuid($this), 'Can create next KSUID';
    ok my $prev = previous_ksuid($this), 'Can create previous KSUID';

    cmp_ok $this, 'gt', $prev, 'Previous KSUID sorts earlier';
    cmp_ok $this, 'lt', $next, 'Next KSUID sorts later';

    my $tail = sub {
        unpack( 'C', substr( payload_of_ksuid(+shift), -1 ) );
    };

    is $this->$tail, ( $next->$tail - 1 ) % 256,
        'Next is one more than this';

    is $this->$tail, ( $prev->$tail + 1 ) % 256,
        'Previous is one less than this';
};

done_testing;
