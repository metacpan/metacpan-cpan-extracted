#! perl
use Test2::V0;

use CXC::Number::Grid;
use Data::Dumper;

use experimental 'signatures';

subtest 'not' => sub {
    my $grid = CXC::Number::Grid->new(
        edges   => [ -1, 0, 1 ],
        include => [ 1,  0 ],
    );

    my $not_grid = !$grid;

    is( $grid->include,     [ 1, 0 ], 'original include' );
    is( $not_grid->include, [ 0, 1 ], '! include' );
};

subtest 'or' => sub {

    subtest
      'no bitwise' => \&test_or,
      sub ( $A, $B ) {
        no feature 'bitwise';
        $A | $B;
      };

    subtest
      'with bitwise' => \&test_or,
      sub ( $A, $B ) {
        use feature 'bitwise';
        $A | $B;
      };
};


subtest 'and' => sub {

    subtest
      'no bitwise' => \&test_and,
      sub ( $A, $B ) {
        no feature 'bitwise';
        $A & $B;
      };

    subtest
      'with bitwise' => \&test_and,
      sub ( $A, $B ) {
        use feature 'bitwise';
        $A & $B;
      };
};


sub test_or ( $code ) {
    my $ctx = context;

    my @A_e = ( 0, 2, 4, 8, 12, 16 );
    my @A_i = ( 0, 1, 0, 1, 0 );

    my @B_e = ( 0, 3, 6, 9, 10, 11, 16 );
    my @B_i = ( 1, 0, 1, 0, 1,  0 );

    my $A = CXC::Number::Grid->new(
        edges   => \@A_e,
        include => \@A_i,
    );

    my $B = CXC::Number::Grid->new(
        edges   => \@B_e,
        include => \@B_i,
    );

    my $AB = $code->( $A, $B );

    is(
        $AB,
        object {
            call edges => [ 0, 3, 4, 6, 9, 10, 11, 12, 16 ];
            call include => [ 1, 1, 0, 1, 1, 1, 1, 0 ];
        },
        'raw'
    ) or note $AB->to_string;

    is(
        $AB->combine_bins,
        object {
            call edges => [ 0, 4, 6, 12, 16 ];
            call include => [ 1, 0, 1, 0 ];
        },
        'combined'
    ) or note $AB->combine_bins->to_string;

    $ctx->release;
}

sub test_and ( $code ) {
    my $ctx = context;

    my @A_e = ( 0, 2, 4, 8, 10, 16, 18 );
    my @A_i = ( 0, 1, 0, 1, 0,  1 );

    my @B_e = ( 1, 3, 6, 9, 10, 11, 16 );
    my @B_i = ( 1, 0, 1, 0, 1,  0 );

    my $A = CXC::Number::Grid->new(
        edges   => \@A_e,
        include => \@A_i,
    );

    my $B = CXC::Number::Grid->new(
        edges   => \@B_e,
        include => \@B_i,
    );

    my $AB = $code->( $A, $B );

    is(
        $AB,
        object {
            call edges => [ 0, 1, 2, 3, 4, 6, 8, 9, 10, 11, 16, 18 ];
            call include => [ 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0 ];
        },
        'raw'
    ) or note $AB->to_string;

    is(
        $AB->combine_bins,
        object {
            call edges => [ 0, 2, 3, 8, 9, 18 ];
            call include => [ 0, 1, 0, 1, 0 ];
        },
        'combined'
    ) or note $AB->combine_bins->to_string;

    $ctx->release;
}


done_testing;
