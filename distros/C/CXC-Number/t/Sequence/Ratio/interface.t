#! perl

use Test2::V0;

use CXC::Number::Sequence::Ratio;
use constant Sequence => 'CXC::Number::Sequence::Ratio';

sub Failure { join( '::', 'CXC::Number::Sequence::Failure', @_ ) }


# make sure things fail

subtest 'constraints' => sub {

    subtest 'min > soft_max' => sub {
        my $err = dies {
            Sequence->new( min => 1, soft_max => 0, w0 => 1, ratio => 2 );
        };
        isa_ok( $err, Failure( 'parameter::constraint' ) );
        like( $err, qr/min < soft_max/ );
    };

    subtest 'soft_min > max' => sub {
        my $err = dies {
            Sequence->new( soft_min => 1, max => 0, w0 => 1, ratio => 2 );
        };
        isa_ok( $err, Failure( 'parameter::constraint' ) );
        like( $err, qr/soft_min < max/ );
    };

    subtest 'shrinking spacing, ratio && w0 too small' => sub {

        subtest 'E[0] == min' => sub {
            my $err = dies {
                Sequence->new(
                    min      => 1,
                    soft_max => 10,
                    w0       => .01,
                    ratio    => 0.1
                );
            };
            isa_ok( $err, Failure( 'parameter::constraint' ) );
            like( $err, qr/spacing.*too small/ );
        };

        subtest 'E[0] == max' => sub {
            my $err = dies {
                Sequence->new(
                    soft_min => 1,
                    max      => 10,
                    w0       => -.01,
                    ratio    => 0.1
                );
            };
            isa_ok( $err, Failure( 'parameter::constraint' ) );
            like( $err, qr/spacing.*too small/ );
        };


    };
};

subtest 'parameter combinations' => sub {

    isa_ok(
        dies {
            Sequence->new( min => 1, soft_max => 2, ratio => 2 );
        },
        ['Error::TypeTiny'],
        'no w0',
    );

    isa_ok(
        dies {
            Sequence->new( min => 1, max => 2, w0 => 1, ratio => 2 );
        },
        [ Failure( 'parameter::IllegalCombination' ) ],
        'min & max'
    );

    isa_ok(
        dies {
            Sequence->new( soft_min => 1, soft_max => 2, w0 => 1, ratio => 2 );
        },
        [ Failure( 'parameter::IllegalCombination' ) ],
        'soft_min & soft_max'
    );

    isa_ok(
        dies {
            Sequence->new(
                min      => 1,
                soft_max => 2,
                w0       => 1,
                nelem    => 2,
                ratio    => 2
            );
        },
        [ Failure( 'parameter::IllegalCombination' ) ],
        'min & soft_max & nelem'
    );

    isa_ok(
        dies {
            Sequence->new(
                soft_min => 1,
                max      => 2,
                w0       => 1,
                nelem    => 2,
                ratio    => 2
            );
        },
        [ Failure( 'parameter::IllegalCombination' ) ],
        'soft_min & max & nelem'
    );
};

done_testing;
