#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';
use experimental 'signatures';

BEGIN {
    eval { require Exporter::Tiny; 1 }
      or skip_all 'Exporter::Tiny required for ui helper tests';
}

use constant HELPERS => qw( ui_list_constants ui_coerce_constant ui_assert_coerce_constant );

package My::Exporter {
    use CXC::Exporter::Util 'install_CONSTANTS', 'install_EXPORTS', ':ui_helpers';
    use parent 'Exporter::Tiny';

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

    install_CONSTANTS( {
            DETECTORS => [
                HRC => 'hrc',
                do {
                    my $detname = 'DET000';
                    map { ++$detname; ( $detname => lc $detname ) } 0 .. 10;
                }
            ] } );

    install_CONSTANTS( [
            [ 'Tag' => 'FryingPan' ] => {
                MAYBE => 'maybe',
            } ] );

    install_EXPORTS;
}

++$INC{'My/Exporter.pm'};

use constant class => 'My::Exporter';

sub imported_sub ( $pkg, $name ) {
    no strict 'refs';    ## no critic (NoStrict)
    return *{"${pkg}::${name}"}{CODE};
}

subtest 'direct imports' => sub {
    my $pkg;
    ok( lives { $pkg = export_from( class, HELPERS ) }, 'import' );
    return unless $pkg;

    my %s;
    ok( $s{$_} = imported_sub( $pkg, $_ ), "$_ imported" ) for HELPERS;

    subtest 'list constants' => sub {
        my $sub = $s{ui_list_constants};
        is(
            [ $sub->( 'detectors' ) ],
            bag {
                item $_ for 'acis', 'hrc';
                my $detname = 'DET000';
                for ( 0 .. 10 ) {
                    ++$detname;
                    item lc $detname;
                }
                end;
            },
            'without name prefix'
        );

        is(
            [ $sub->( 'detectors', 'DET' ) ],
            bag {
                item $_ for 'acis', 'hrc';
                my $detnum = '000';
                item ++$detnum for 0 .. 10;
                end;
            },
            'name prefix'
        );
    };

    subtest 'coerce constant' => sub {
        my $sub = $s{ui_coerce_constant};
        is( $sub->( 'hrc',   'detectors' ), 'hrc',   'known lowercase name' );
        is( $sub->( 'HRC',   'detectors' ), 'HRC',   'uppercase names unchanged' );
        is( $sub->( 'bogus', 'detectors' ), 'bogus', 'unknown names unchanged' );
        is( $sub->( '001', 'detectors', 'DET' ), 'det001', 'prefixed names' );
    };

    subtest 'assert coerce' => sub {
        my $sub = $s{ui_assert_coerce_constant};
        is( $sub->( 'acis', 'detectors' ), 'acis', 'known lowercase names' );

        like(
            dies { $sub->( 'ACIS', 'detectors' ) },
            qr/unknown constant detectors: ACIS/,
            'rejects uppercase names'
        );
    };
};

subtest 'tag import' => sub {
    my $pkg;
    ok( lives { $pkg = export_from( class, ':ui_helpers' ) }, ':ui_helpers can be imported' );
    return unless $pkg;

    my %s;
    ok( $s{$_} = imported_sub( $pkg, $_ ), "$_ imported" ) for HELPERS;

    is( $s{ui_coerce_constant}->( 'any', 'Tag' ),
        'any', 'ui helpers use custom constant-name enumerators' );
};

done_testing;
