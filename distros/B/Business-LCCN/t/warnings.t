#!perl

use strict;
use warnings;
use Test::More;

my @error_tests = ( { input => undef,                  expect => 'undef' },
                    { input => '',                     expect => 'empty' },
                    { input => ' ',                    expect => 'number' },
                    { input => '1',                    expect => 'number' },
                    { input => 'a',                    expect => 'number' },
                    { input => '123',                  expect => 'parsed' },
                    { input => 'abcd89-456',           expect => 'parsed' },
                    { input => '001 85000002',,        expect => 'MARC' },
                    { input => '010 85000002',         expect => 'MARC' },
                    { input => '010    _a   85000002', expect => 'MARC' },
                    { input => '$a 85000002',          expect => 'MARC' },
                    { input => '###85000002',          expect => '#' },
                    { input => '_a   85000002',        expect => 'MARC' },
);

plan tests => 2 * @error_tests + 1;

use_ok('Business::LCCN') || BAIL_OUT('Could not load Business::LCCN');

foreach my $test_set (@error_tests) {
    my ( $lccn, $warning );

    my $input_printable
        = ( defined $test_set->{input} ? $test_set->{input} : '[undef]' );

    {
        local $SIG{__WARN__} = sub { $warning = shift };
        $lccn = Business::LCCN->new( $test_set->{input} );
    }

    if ($lccn) {
        fail(
            qq{Given LCCN input "$input_printable", should not get back a valid LCCN object (got back "$lccn")}
        );
    } else {
        like(
            $warning,
            qr/\Q$test_set->{expect}/,
            qq{Given LCCN input "$input_printable", failure warning should mention "$test_set->{expect}"},
        ) || diag(qq{Failure warning was "$warning"});
    }

    {
        my $got_warning = 0;
        local $SIG{__WARN__} = sub { $got_warning = 1 };
        $lccn
            = Business::LCCN->new( $test_set->{input}, { no_warnings => 1 } );
        ok( !$got_warning,
            qq{No unwanted warnings (LCCN input "$input_printable")} );
    }

}

# Local Variables:
# mode: perltidy
# End:
