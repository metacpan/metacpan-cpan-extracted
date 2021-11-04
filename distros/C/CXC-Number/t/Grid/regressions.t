#! perl

use Test2::V0;
use CXC::Number::Grid qw( overlay_n );

use constant Grid => 'CXC::Number::Grid';

sub Failure { join( '::', 'CXC::Number::Grid::Failure', @_ ) }


subtest 'overlap' => sub {

    subtest 'use numerical comparison' => sub {
       # this will blow up if Tree::Range isn't set up for numerical comparisons

        my $gti = Grid->new( {
            edges   => [ -1, 2, 4, 5 ],
            include => [ 1,  0, 1 ],
        } );

        my $bins
          = Grid->new( { edges => [ map { -1.5 + $_ * 0.5 } 0 .. 10 ] } );

        ok ( lives {$gti->overlay( $bins ) } )
          or note $@;
    };

};

done_testing;
