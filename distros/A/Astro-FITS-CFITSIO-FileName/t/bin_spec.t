#! perl

use Test2::V0;

use Astro::FITS::CFITSIO::FileName::Regexp;

my %Test = (

    '[bin x = :512:2]' => hash {
        field bin_spec_expression => 'x = :512:2';
        end;
    },
    '[bin x = 1::2]' => hash {
        field bin_spec_expression => 'x = 1::2';
        end;
    },
    '[bin x = 1:512]' => hash {
        field bin_spec_expression => 'x = 1:512';
        end;
    },
    '[bin x = 1:]' => hash {
        field bin_spec_expression => 'x = 1:';
        end;
    },
    '[bin x = :512]' => hash {
        field bin_spec_expression => 'x = :512';
        end;
    },
    '[bin x = 2]' => hash {
        field bin_spec_expression => 'x = 2';
        end;
    },
    '[bin x]' => hash {
        field bin_spec_expression => 'x';
        end;
    },
    '[bin 4]' => hash {
        field bin_spec_expression => '4';
        end;
    },
    '[bin]' => hash {
        end;
    },
    '[bin (X,Y)=1:512:2]' => hash {
        field bin_spec_expression => '(X,Y)=1:512:2';
        end;
    },
    '[bin (X,Y) = 5]' => hash {
        field bin_spec_expression => '(X,Y) = 5';
        end;
    },
    '[bini detx, dety]' => hash {
        field bin_spec_expression => 'detx, dety';
        field bin_spec_datatype   => 'i';
        end;
    },
    '[bin (detx, dety)=16; /exposure]' => hash {
        field bin_spec_expression => '(detx, dety)=16; /exposure';
        end;
    },
    '[bin time=TSTART:TSTOP:0.1]' => hash {
        field bin_spec_expression => 'time=TSTART:TSTOP:0.1';
        end;
    },
    '[bin pha, time=8000.:8100.:0.1]' => hash {
        field bin_spec_expression => 'pha, time=8000.:8100.:0.1';
        end;
    },
    '[bin @binFilter.txt]' => hash {
        field bin_spec_expression => '@binFilter.txt';
        end;
    },
);


for my $spec ( keys %Test ) {

    my $check = $Test{$spec};
    my $object;

    subtest $spec => sub {
        ok( $spec =~ $Astro::FITS::CFITSIO::FileName::Regexp::binSpec, 'matches' );

        my %match = %+;

        is( \%match, $check, 'contents' )
          or do { require Data::Dump; note Data::Dump::pp( \%match ) };
    };
}


done_testing;

1;
