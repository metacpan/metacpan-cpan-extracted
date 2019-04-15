#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::SV ();

use Test2::V0;
use Test2::Tools::PDL;

is( PDL->sequence(5)->length, 5, 'length()' );

{
    is( [ PDL::SV->new( [qw(foo bar)] )->flatten ],
        [qw(foo bar)], '$pdlsv->flatten' );
    is( [ pdl( [ 1 .. 5 ] )->flatten ], [ 1 .. 5 ], '$p->flatten' );
}

subtest diff => sub {
    pdl_is( PDL->sequence(10)->diff,    pdl([ (1) x 9 ]), 'diff()' );
    pdl_is( PDL->sequence(10)->diff(2), pdl([ (2) x 8 ]), 'diff()' );
};

subtest repeat => sub {
    my @repeat_cases = (
        {
            params => [ pdl([]), 3 ],
            out => pdl([]),
        },
        {
            params => [ pdl([ 1, 2, 3 ]), 3 ],
            out => pdl([ 1, 2, 3, 1, 2, 3, 1, 2, 3 ]),
        },
    );

    for (@repeat_cases) {
        my $pdl = $_->{params}[0];
        my $n   = $_->{params}[1];
        pdl_is( $pdl->repeat($n), $_->{out}, '$p->repeat' );
    }

    my $na = pdl("nan")->setnantobad;
    pdl_is( $na->repeat(3)->isbad, pdl([1,1,1]), '$bad->repeat' );

    pdl_is( pdl(1)->repeat(1), pdl([1]),
            'repeat() can convert a 0D piddle to 1D' );
};

subtest repeat_to_length => sub {
    my @repeat_to_length_cases = (
        {
            params => [ pdl([]), 3 ],
            out => pdl([]),
        },
        {
            params => [ pdl([ 1, 2, 3 ]), 2 ],
            out => pdl([ 1, 2 ]),
        },
        {
            params => [ pdl([ 1, 2, 3 ]), 5 ],
            out => pdl([ 1, 2, 3, 1, 2 ]),
        },
    );
    for (@repeat_to_length_cases) {
        my $pdl = $_->{params}[0];
        my $n   = $_->{params}[1];
        pdl_is( $pdl->repeat_to_length($n),
            $_->{out}, '$pdl->repeat_to_length' );
    }
};

done_testing;
