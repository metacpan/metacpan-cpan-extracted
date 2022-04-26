#! perl

use Test2::V0;
use Import::Into;

use feature 'state';
use experimental 'signatures';

sub my::export ( $src, @args ) {
    state $package = 'Package000';
    ++$package;
    $src->import::into( $package, @args );
    $package;
}

package My::Exporter {
    use CXC::Exporter::Tagged 'install_CONSTANTS', 'install_EXPORTS';
    use Exporter 'import';

    install_CONSTANTS( {
            DETECTOR => [
                ACIS => 'acis',
                HRC  => 'hrc',
            ],

            AGGREGATE => {
                ALL  => 'all',
                NONE => 'none',
                ANY  => 'any',
            },
        } );

    install_EXPORTS;
}

++$INC{'My/Exporter.pm'};

use constant class => 'My::Exporter';

is( [ class->my::export( 'DETECTORS' )->DETECTORS ], [ 'acis', 'hrc' ] );
is( class->my::export( ':detector' )->ACIS,          'acis' );
is( class->my::export( ':detector' )->HRC,           'hrc' );

is(
    [ class->my::export( 'AGGREGATES' )->AGGREGATES ],
    bag {
        item 'all';
        item 'none';
        item 'any';
        end;
    } );
is( class->my::export( ':aggregate' )->ALL,  'all' );
is( class->my::export( ':aggregate' )->NONE, 'none' );
is( class->my::export( ':aggregate' )->ANY,  'any' );

done_testing;
