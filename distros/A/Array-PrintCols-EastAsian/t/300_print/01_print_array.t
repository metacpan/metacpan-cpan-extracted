use strict;
use warnings;
use utf8;
use Test::More;
use Capture::Tiny qw/ capture /;
use Test::Exception;
use Encode;
use Array::PrintCols::EastAsian;

my @array = qw/ GSX1300Rハヤブサ CBR1000RR YZF-R1 GSX-R1000 ZZR1400/;

subtest 'default print array' => sub {
    my $expected = encode 'utf-8',
        "GSX1300RハヤブサCBR1000RR       YZF-R1          GSX-R1000       ZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying gap option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300Rハヤブサ   CBR1000RR          YZF-R1             GSX-R1000          ZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { gap => 3 } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying column option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300RハヤブサCBR1000RR       \nYZF-R1          GSX-R1000       \nZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { column => 2 } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying width option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300RハヤブサCBR1000RR       YZF-R1          \nGSX-R1000       ZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { width => 50 } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying too small width option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300Rハヤブサ\nCBR1000RR       \nYZF-R1          \nGSX-R1000       \nZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { width => 1 } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying encode option' => sub {
    my $expected = encode 'cp932',
        "GSX1300RハヤブサCBR1000RR       YZF-R1          GSX-R1000       ZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { encode => 'cp932' } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying column and width option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300RハヤブサCBR1000RR       \nYZF-R1          GSX-R1000       \nZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { column => 4, width => 32 } );
    };
    is( $stdout, $expected );
};

subtest 'print array with specifying gap and width option' => sub {
    my $expected = encode 'utf-8',
        "GSX1300Rハヤブサ\nCBR1000RR       \nYZF-R1          \nGSX-R1000       \nZZR1400         \n";
    my ( $stdout, $strerr ) = capture {
        print_cols( \@array, { gap => 1, width => 32 } );
    };
    is( $stdout, $expected );
};

subtest 'pretty print array with specifying gap, align and encode option' => sub {
    lives_ok {
        capture {
            pretty_print_cols( \@array, { gap => 1, align => 'left', encode => 'utf-8' } );
        }
    };
};

subtest 'pretty print array with not used invalid option' => sub {
    lives_ok {
        capture {
            pretty_print_cols( \@array, { column => -1, width => -1 } );
        }
    };
};

done_testing;

