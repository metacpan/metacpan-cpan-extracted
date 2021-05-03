#! perl

use Test2::V0;

use aliased 'CXC::Number::Sequence::Linear' => 'Sequence';

use List::Util 1.29 qw( pairkeys );
use Hash::Util qw( lock_hash );

my $debug = 0;

sub test_one {

    my ( $attr, $exp ) = @_;

    # keep the keys in the order they were provided
    my @keys = pairkeys @$attr;
    my %attr = @$attr;
    lock_hash( %attr );

    return if exists $attr{debug} && $debug && !$attr{debug};

    my $ctx = context;

    my $tag = join( '; ', map {
        my $value = ! ref $attr{$_} ? $attr{$_} : '[' . join( ', ', $attr{$_}->@* ) . ']';
        $_ . ' = ' . $value } @keys ) . ';';

    subtest $tag => sub {

      SKIP: {
            my $sequence;

            ok( lives { $sequence = Sequence->new( %attr ) }, 'constructor' )
              or do {
                diag $@;
                skip "can't construct; can't continue", 1;
              };

            my $nelem = @{ $exp->{elements} };
            my $spacing  = exists $attr{spacing} ? $attr{spacing} : $exp->{spacing};

            my $min
              = exists $attr{min}      ? $attr{min}
              : exists $attr{soft_min} ? $attr{soft_min}
              :                          undef;

            ok( $sequence->min <= $min, "minimum condition valid" )
                if defined $min;


            my $max
              = exists $attr{min}      ? $attr{min}
              : exists $attr{soft_min} ? $attr{soft_min}
              :                          undef;

            ok( $sequence->max >= $max, "maximum condition valid" )
                if defined $max;

            is(
                $sequence,
                object {
                    call min       => $exp->{elements}[0];
                    call max       => $exp->{elements}[-1];
                    # call nelem     => $nelem;
                    call elements => array {
                        item float( $_ ) foreach $exp->{elements}->@*;
                        end;
                    };
                    call spacing => array {
                        prop size => $nelem - 1;
                        all_items float( $spacing );
                        etc;
                    };
                },
            );
        }
        $ctx->release;
    };

}

sub test(@) {
    my $ctx = context;
    test_one( @$_ ) foreach @_;
    $ctx->release;
}

subtest '( MIN | MAX | NELEM )' => sub {

    test

      [
        [ min => 1, max => 10, nelem =>11 ],
        {
            spacing      => 0.9,
            elements =>
              [ 1, 1.9, 2.8, 3.7, 4.6, 5.5, 6.4, 7.3, 8.2, 9.1, 10.0 ],
        },
      ],

      [
        [ min => 0.5, max => 7.7, nelem => 10 ],
        {
            spacing      => 0.8,
            elements => [ 0.5, 1.3, 2.1, 2.9, 3.7, 4.5, 5.3, 6.1, 6.9, 7.7 ],
        },
      ],
      ;

};

subtest '( MIN | MAX | SPACING )' => sub {

    test

      [
        [ min => 1, max => 10, spacing => 1 ],
        {
            elements => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
        },
      ],

      [
        [ min => 0.5, max => 8, spacing => 0.8 ],
        {
            elements => [
                0.25, 1.05, 1.85, 2.65, 3.45, 4.25,
                5.05, 5.85, 6.65, 7.45, 8.25,
            ],
        },
      ],

      [
        [ min => 1, max => 10, spacing => 1.1 ],
        {
            elements =>
              [ 0.55, 1.65, 2.75, 3.85, 4.95, 6.05, 7.15, 8.25, 9.35, 10.45 ],
        },
      ],
      ;

};

subtest '( MIN | NELEM | SPACING )' => sub {

    test

      [
        [ min => 0.5, nelem => 10, spacing => 0.8 ],
        {
            elements => [ 0.5, 1.3, 2.1, 2.9, 3.7, 4.5, 5.3, 6.1, 6.9, 7.7 ],
        },
      ],

      [
        [ min => 1, nelem => 10, spacing => 1 ],
        {
            elements => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
        },
      ],

      [
        [ min => 1, nelem => 10, spacing => 1.1 ],
        {
            elements => [ 1, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9 ],
        },
      ],
      ;

};

subtest '( MAX | NELEM | SPACING )' => sub {

    test

      [
        [ max => 10, nelem => 11, spacing => 0.9 ],
        {
            elements =>
              [ 1, 1.9, 2.8, 3.7, 4.6, 5.5, 6.4, 7.3, 8.2, 9.1, 10.0 ],
        },
      ],

      [
        [ max => 10, nelem => 10, spacing => 1 ],
        {
            elements => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
        },
      ],

      [
        [ max => 10, nelem => 10, spacing => 1.1 ],
        {
            elements => [ 0.1, 1.2, 2.3, 3.4, 4.5, 5.6, 6.7, 7.8, 8.9, 10 ],
        },
      ],
      ;

};


subtest '( CENTER | SPACING | NELEM )' => sub {

    test [
        [ center => 0, spacing => 1, nelem => 12 ],
        {
            spacing      => 1,
            elements => [
                -5.5, -4.5, -3.5, -2.5, -1.5, -0.5,
                0.5,  1.5,  2.5,  3.5,  4.5,  5.5
            ],
        },

      ],

      [
        [ center => -0.24, spacing => 1, nelem => 12 ],
        {
            spacing      => 1,
            elements => [
                -5.74, -4.74, -3.74, -2.74, -1.74, -0.74,
                0.26,  1.26,  2.26,  3.26,  4.26,  5.26
            ],
        },

      ],

      [
        [ center => 0, nelem => 11, spacing => 1.1 ],
        {
            elements =>
              [ -5.5, -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],

      [
        [ center => 0.55, nelem => 10, spacing => 1.1 ],
        {
            elements => [ -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],

      ;

};

subtest '( CENTER | RANGEW | NELEM )' => sub {

    test

      [
        [ center => 0, rangew => 10, nelem => 11 ],
        {
            spacing      => 1,
            elements => [ -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5 ],
        },
      ],

      [
        [ center => -0.24, rangew => 10, nelem => 11 ],
        {
            spacing      => 1,
            elements => [
                -5.24, -4.24, -3.24, -2.24, -1.24, -0.24,
                0.76,  1.76,  2.76,  3.76,  4.76
            ],
        },
      ],

      [
        [ center => 0, rangew => 11, nelem => 12 ],
        {
            spacing      => 1,
            elements => [
                -5.5, -4.5, -3.5, -2.5, -1.5, -0.5,
                0.5,  1.5,  2.5,  3.5,  4.5,  5.5
            ],
        },

      ],

      [
        [ center => -0.24, rangew => 11, nelem => 12 ],
        {
            spacing      => 1,
            elements => [
                -5.74, -4.74, -3.74, -2.74, -1.74, -0.74,
                0.26,  1.26,  2.26,  3.26,  4.26,  5.26
            ],
        },

      ],

      ;

};

subtest '( CENTER | RANGEW | SPACING )' => sub {

    test [
        [ center => 0, rangew => 10, spacing => 1.1 ],
        {
            elements =>
              [ -5.5, -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],

      [
        [ center => 0.55, rangew => 9, spacing => 1.1 ],
        {
            elements => [ -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],
      ;
};

subtest '( CENTER | SOFT_MIN | SOFT_MAX | NELEM )' => sub {

    test [
        [ center => 0, soft_min => -6, soft_max => 5.5, nelem => 12 ],
        do {
            my $spacing = 12 / 11;
            {
                spacing      => $spacing,
                elements => [ map { -6.0 + $_ * $spacing } 0 .. 11 ],
            },
              ;
        },

      ],

      [
        [ center => 0.55, soft_min => -4.4, soft_max => 5.5, nelem => 10 ],
        {
            spacing      => 1.1,
            elements => [ -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],

      [
        [ center => 0.55, soft_min => -4.4, soft_max => 5.5, nelem => 11 ],
        do {
            my $spacing = 0.99;
            {
                spacing      => $spacing,
                elements => [ map { -4.4 + $_ * $spacing } 0 .. 10 ],
            },
              ;
        },
      ],


      ;
};

subtest '( CENTER | SOFT_MIN | SOFT_MAX | SPACING )' => sub {

    test [
        [ center => 0, soft_min => -6, soft_max => 5.5, spacing => 1.1 ],
        {
            elements => [
                -6.05, -4.95, -3.85, -2.75, -1.65, -0.55,
                0.55,  1.65,  2.75,  3.85,  4.95,  6.05
            ],
        },
      ],

      [
        [ center => 0.55, soft_min => -4.4, soft_max => 5.5, spacing => 1.1 ],
        {
            elements => [ -4.4, -3.3, -2.2, -1.1, 0, 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
      ],
      ;

};

subtest '( MIN | SOFT_MAX | SPACING )' => sub {

    test

      [
        [ min => 1, soft_max => 10, spacing => 1 ],
        {
            elements => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
        },
      ],

      [
        [ min => 1, soft_max => 10, spacing => 1.1 ],
        {
            elements => [ 1, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9 ],
        },
      ],
      ;
};

subtest '( SOFT_MIN | MAX | SPACING )' => sub {

    test

      [
        [ soft_min => 1, max => 10, spacing => 1 ],
        {
            elements => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
        },
      ],

      [
        [ soft_min => 1, max => 10, spacing => 1.1 ],
        {
            elements => [ 0.1, 1.2, 2.3, 3.4, 4.5, 5.6, 6.7, 7.8, 8.9, 10.0 ],
        },
      ],
      ;

};

subtest '( MIN | MAX | SPACING | ALIGN )' => sub {

    test

      [
        [ min => 1, max => 10, spacing => 1.1, align => [ -0.55, 0 ] ],
        {
            elements => [ map { 0.55 + 1.1 * $_ } 0 .. 9 ],

        },
      ],

      [
        [ min => 1, max => 10, spacing => 1.1, align => [ 0.55, 0.2 ] ],
        {
            elements => [ map { 0.55 - 0.2 * 1.1 + 1.1 * $_ } 0 .. 9 ],
        },
      ],

      [
        [ min => 1, max => 10, spacing => 1.1, align => [ 22.55, 0.2 ] ],
        {
            elements => [ map { 0.55 - 0.2 * 1.1 + 1.1 * $_ } 0 .. 9 ],
        },
      ],
      ;

};

subtest '( MIN | MAX | NELEM | ALIGN )' => sub {

    test

      [
        [ min => 1, max => 10, nelem => 10, align => [ -0.55, 0 ] ],
        {
            spacing      => 1.125,
            elements => [ map { 0.575 + 1.125 * $_ } 0 .. 9 ],

        },
      ],

      [
        [ min => 1, max => 10, nelem => 10, align => [ 0.55, 0.2 ] ],
        {
            spacing      => 1.125,
            elements => [ map { 0.55 - 0.2 * 1.125 + 1.125 * $_ } 0 .. 9 ],
        },
      ],

      [
        [ min => 1, max => 10, nelem => 10, align => [ 22.55, 0.2 ] ],
        {
            spacing      => 1.125,
            elements => [ map { 0.95 + 1.125 * $_ } 0 .. 9 ],
        },
      ],
      ;


};

done_testing;
