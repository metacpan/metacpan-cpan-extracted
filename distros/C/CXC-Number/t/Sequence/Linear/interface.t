#! perl

use strict;
use warnings;

use Test2::V0;

use Set::Partition;

use aliased 'CXC::Number::Sequence::Linear' => 'Sequence';
use Carp;

sub new {
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
    Sequence->new( @_ );
}

my $tol = 4e-15;

=item I<min>, I<max>, I<nelem>.

Extrema are as specified. The sequence exactly covers the range.

=cut

{
    my %exp = ( min => 1, max => 10, nelem => 10 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min   => float( $exp{min} );
            call max   => float( $exp{max} );
            # call nelem => $exp{nelem};
            call spacing  => meta {
                prop size => 9;
                prop this => array {
                    all_items number( 1 );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );
}


=item I<min>, I<max>, I<spacing>

The extrema are soft and are as specified. The number of bins is chosen
to minimally cover the specified range, with center at ( min + max ) / 2

=cut

{
    my %exp = ( min => 1, max => 10, spacing => 1.1 );

    my $sequence = new( %exp );
    is(
        $sequence,
        object {
            call min  => float( 0.55 );
            call max  => float( 10.45 );
            call spacing => meta {
                prop size => 9;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );


}

=pod

=item I<min>, I<nelem>, I<spacing>

=item I<max>, I<nelem>, I<spacing>

The extremum is as specified.  The sequence exactly covers the calculated
range.

=cut

{
    my %exp = ( min => 1, nelem => 10, spacing => 1.1 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( 1.0 );
            call max  => float( $exp{min} + ($exp{nelem}-1) * $exp{spacing} );
            call spacing => meta {
                prop size => 9;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );
}

{
    my %exp = ( max => 10.9, nelem => 10, spacing => 1.1 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( $exp{max} - ($exp{nelem}-1) * $exp{spacing} );
            call max  => float( $exp{max} );
            call spacing => meta {
                prop size => 9;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );

}

=item I<min>, I<soft_max>, I<spacing>

=item I<max>, I<soft_min>, I<spacing>

The hard extremum is as specified. The number of bins is chosen to
minimally cover the specified range.


=cut

{
    my %exp = ( min => 1, soft_max => 10, spacing => 1.1 );

    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( $exp{min} );
            call max  => float( 10.9 );
            call spacing => meta {
                prop size => 9;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );

}

{
    my %exp = ( soft_min => 1, max => 10, spacing => 1.1 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( 0.1 );
            call max  => float( $exp{max} );
            call spacing => meta {
                prop size => 9;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", sort keys %exp ),
    );

}



=pod

=item I<center>, I<rangew>, I<nelem>

The sequence exactly covers the range.

=cut

{
    my %exp = ( center => 0, rangew => 10, nelem => 11 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5 );
            call max  => float( 5 );
            call spacing => meta {
                prop size => 10;
                prop this => array {
                    all_items number( 1 );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), 'nelem odd' ),
    );

}


{
    my %exp = ( center => 0, rangew => 11, nelem => 12 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5.5 );
            call max  => float( 5.5 );
            call spacing => meta {
                prop size => 11;
                prop this => array {
                    all_items number( 1 );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), 'nelem even' ),
    );

}

=pod

=item I<center>, I<rangew>, I<spacing>

The bins are aligned so that the center of a bin is at the specified
center; the sequence minimally covers the range.


=cut


{
    my %exp = ( center => 0, rangew => 10, spacing => 1 );
    my $sequence = new( %exp );
    is(
        $sequence,
        object {
            call min  => float( -5 );
            call max  => float( 5 );
            call spacing => meta {
                prop size => 10;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ) ),
    );

}



=pod

=item I<center>, I<nelem>, I<spacing>

The sequence exactly covers the range.

=cut

{
    my %exp = ( center => 0, spacing => 1, nelem => 11 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5 );
            call max  => float( 5 );
            call spacing => meta {
                prop size => 10;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), "nelem odd" ),
    );

}


{
    my %exp = ( center => 0, spacing => 1, nelem => 12 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5.5 );
            call max  => float( 5.5 );
            call spacing => meta {
                prop size => 11;
                prop this => array {
                    all_items float( $exp{spacing} );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), "nelem even" ),
    );

}

=pod



=item I<center>, I<soft_min>, I<soft_max>, I<nelem>

The sequence is centered on the specified center and the sequence minimally
covers the specified range.

=cut

{
    my %exp = ( center => 0, soft_min => -5, soft_max => 3, nelem => 11 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5 );
            call max  => float( 5 );
            call spacing => meta {
                prop size => 10;
                prop this => array {
                    all_items number( 1 );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), "nelem odd" ),
    );

}


{

    my %exp = ( center => 0, soft_min => -3, soft_max => 5, nelem => 12 );

    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min  => float( -5 );
            call max  => float( 5 );
            call spacing => meta {
                prop size => 11;
                prop this => array {
                    all_items float( 10 / 11 );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ), "nelem even" ),
    );
}

=pod


=item I<center>, I<soft_min>, I<soft_max>, I<spacing>

The sequence is centered on the specified center and the sequence minimally
covers the specified range.

=cut


{
    my %exp = ( center => 0, soft_min => -5.5, soft_max => 2, spacing => 1 );
    my $sequence = new( %exp );

    is(
        $sequence,
        object {
            call min   => float( -5.5 );
            call max   => float( 5.5 );
            # call nelem => number 12;
            call spacing  => meta {
                prop size => 11;
                prop this => array {
                    all_items number( 1 );
                    etc;
                };
            };
        },
        join( ", ", ( sort keys %exp ) ),
    );

}

isa_ok(
    dies {
        CXC::Number::Sequence::Linear->new(
            max   => 1,
            min   => 0,
            nelem => 11,
            spacing  => 3
          )
    },
    [ 'CXC::Number::Sequence::Failure::parameter::IllegalCombination' ],
    "overspecified"
);

# check all underspecified combinations
{
    my %args = ( max => 1, min => 0, nelem => 11, spacing => 3 );
    my $s = Set::Partition->new(
        list      => [qw( max min nelem spacing )],
        partition => [2] );

    isa_ok(
        dies {
            CXC::Number::Sequence::Linear->new( map { $_ => $args{$_} }
                  @{ $_->[0] } )
        },
        ['CXC::Number::Sequence::Failure::parameter::IllegalCombination'],
        join( ' ', 'underspecified: ', @{ $_->[0] } ),
    ) while $_ = $s->next;
}


done_testing;
