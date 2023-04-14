#! perl

use Test2::V0;

use List::Util 1.54 qw{ reductions };
use CXC::Number::Sequence::Ratio;
use constant Sequence => 'CXC::Number::Sequence::Ratio';
use Hash::Wrap { -as => 'ro_hash', -immutable => 1 };
use POSIX ();

sub expect {
    my ( $ratio ) = @_;

    my $w0    = 0.8;
    my $nelem = 11;

    my @w = map { $w0 * $ratio**$_ } 0 .. $nelem - 2;

    ro_hash( {
        min      => 0.5,
        w0       => $w0,
        ratio    => $ratio,
        elements => [ reductions { $a + $b } 0.5, @w ],
    } );
}


sub test_sequence {

    my ( $exp, %pars ) = @_;

    my $ctx = context;
    my $bool;

  SKIP: {
        my $sequence;
        $bool = ok( lives { $sequence = Sequence->new( %pars ) }, 'create sequence' )
          or do { diag $@; skip 1 };

        $bool = is(
            $sequence,
            object {
                call elements => array {
                    item float( $_ ) foreach $exp->elements->@*;
                    end;
                };
            },
        );
    }

    $ctx->release;
    return $bool;
}

my %tests = (
    'MIN | W0 | NELEM' => sub {
        my $exp = shift;

        test_sequence(
            $exp,
            min   => $exp->min,
            w0    => $exp->w0,
            ratio => $exp->ratio,
            nelem => 0+ $exp->elements->@*,
        );
    },

    'MAX | W0 | NELEM' => sub {
        my $exp = shift;

        test_sequence(
            $exp,
            max   => $exp->elements->[-1],
            w0    => ( $exp->elements->[-1] - $exp->elements->[-2] ),
            ratio => 1 / $exp->ratio,
            nelem => 0+ $exp->elements->@*,
        );
    },

    'MIN | SOFT_MAX | W0' => sub {
        my $exp = shift;

        test_sequence(
            $exp,
            min => $exp->min,
            # this creates a soft edge just larger than the second from last edge,
            # which should drag in another bin
            soft_max => ( $exp->elements->[-2] + $exp->elements->[-1] ) / 2,
            w0       => $exp->w0,
            ratio    => $exp->ratio,
        );
    },

    'SOFT_MIN | MAX | W0' => sub {
        my $exp = shift;

        test_sequence(
            $exp,
            # this creates a soft edge just smaller than the second edge,
            # which should drag in another bin
            soft_min => ( $exp->elements->[0] + $exp->elements->[1] ) / 2,
            max      => $exp->elements->[-1],
            w0       => ( $exp->elements->[-2] - $exp->elements->[-1] ),
            ratio    => 1 / $exp->ratio,
        );
    },

    'E0 | MIN | MAX | W0' => sub {
        my $exp = shift;

        for my $idx ( 0, -1, POSIX::floor( @{ $exp->elements } / 2 ) ) {

            subtest "E0 = edge[$idx]" => sub {

                my $E0 = $exp->elements->[$idx];

                my ( $w0, $ratio ) = do {

                    if ( $idx == 0 ) {
                        ( $exp->elements->[1] - $exp->elements->[0], $exp->ratio )
                    }
                    elsif ( $idx == -1 ) {
                        # need to generate the width of the bin whose minimum is the largest bin edge
                        # that depends upon whether the bins grew to the left or to the right
                        ( $exp->elements->[-2] - $exp->elements->[-1], 1 / $exp->ratio );
                    }
                    else {
                        ( $exp->elements->[ $idx + 1 ] - $exp->elements->[$idx], $exp->ratio )
                    }
                };

                test_sequence(
                    $exp,
                    # this creates soft edges just outward of the second edges from the maxima,
                    # which should drag in another bin
                    e0    => $E0,
                    min   => ( $exp->elements->[0] + $exp->elements->[1] ) / 2,
                    max   => ( $exp->elements->[-2] + $exp->elements->[-1] ) / 2,
                    w0    => $w0,
                    ratio => $ratio,
                );
            };
        }
    },
);



while ( my ( $label, $test ) = each %tests ) {

    subtest $label => sub {
        subtest( 'r > 1', $test, expect( 1.1 ) );
        subtest( 'r < 1', $test, expect( 1 / 1.1 ) );
    };

}

done_testing;

