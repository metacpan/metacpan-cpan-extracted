#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';

package My::Exporter {
    use CXC::Exporter::Util 'install_CONSTANTS', 'install_EXPORTS';
    use Exporter 'import';

    BEGIN {
        install_CONSTANTS( {
                DETECTORS => [
                    ACIS => 'acis',
                ],
            },
            [
                [ 'Tag', 'ValueFunc', 'NameFunc' ] => {
                    ALL  => 'all',
                    NONE => 'none',
                    ANY  => 'any',
                },
            ] );
    }

    # check for proper merge
    install_CONSTANTS( {
            DETECTORS => [    # add a bunch to increase the probability that the
                              # enumerating function will return the wrong order
                              # if this is treated as a hash
                HRC => 'hrc',
                do {
                    my $detname = "DET000";
                    map { ++$detname; ( $detname => lc $detname ) } 0 .. 10;
                }
            ] } );

    # check for alternate id, func_name
    install_CONSTANTS( [
            [ 'Tag' => 'FryingPan' ] => {
                MAYBE => 'maybe',
            } ] );

    install_EXPORTS;
}

++$INC{'My/Exporter.pm'};

use constant class => 'My::Exporter';

# DETECTOR must return the detectors in the order specified
is(
    [ export_from( class, 'DETECTORS' )->DETECTORS ],
    array {
        item 'acis';
        item 'hrc';
        do {
            my $detname = "DET000";
            item lc( ++$detname ) for 0 .. 10;
        }
    } );

is(
    [ export_from( class, 'DETECTORS_NAMES' )->DETECTORS_NAMES ],
    array {
        item 'ACIS';
        item 'HRC';
        do {
            my $detname = "DET000";
            item ++$detname for 0 .. 10;
        }
    } );

is( export_from( class, ':detectors' )->ACIS, 'acis' );
is( export_from( class, ':detectors' )->HRC,  'hrc' );

is(
    [ export_from( class, 'ValueFunc' )->ValueFunc ],
    bag {
        item 'all';
        item 'none';
        item 'any';
        item 'maybe';
        end;
    } );

is(
    [ export_from( class, 'NameFunc' )->NameFunc ],
    bag {
        item 'ALL';
        item 'NONE';
        item 'ANY';
        item 'MAYBE';
        end;
    } );


is(
    [ export_from( class, 'FryingPan' )->FryingPan ],
    bag {
        item 'all';
        item 'none';
        item 'any';
        item 'maybe';
        end;
    } );

is( export_from( class, ':Tag' )->ALL,   'all' );
is( export_from( class, ':Tag' )->NONE,  'none' );
is( export_from( class, ':Tag' )->ANY,   'any' );
is( export_from( class, ':Tag' )->MAYBE, 'maybe' );

subtest 'constant_funcs' => sub {
    is( export_from( class, ':constant_funcs' )->ValueFunc,     D(), 'ValueFunc' );
    is( export_from( class, ':constant_name_funcs' )->NameFunc, D(), 'NameFunc' );
};

done_testing;
