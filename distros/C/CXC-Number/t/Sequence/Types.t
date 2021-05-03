#! perl

use strict;
use warnings;

use Test2::V0;

use Data::Dumper;

use Math::BigFloat;

local $Data::Dumper::Indent = 0;

use CXC::Number::Sequence::Types -types;

for my $tpars (
    [ ( BigNum         ) => q/x/ ],
    [ ( BigInt         ) => q/x/ ],
    [ ( BigPositiveNum ) => q/x/ ],
    [ ( BigPositiveNum ) => 0 ],
    [ ( BigPositiveNum ) => -1 ],
    [ ( BigPositiveInt ) => q/x/ ],
    [ ( BigPositiveInt ) => 0 ],
    [ ( BigPositiveInt ) => -1 ],
    [ ( BigPositiveInt ) => 1.1 ],
  )
{

    my ( $type, $exp ) = @$tpars;

    like( dies { $type->assert_coerce( $exp ) },
          qr/.*/,
          "bad $type: $exp" );

}

for my $tpars (
    [ ( BigNum         ) => 1.1 ],
    [ ( BigNum         ) => 0 ],
    [ ( BigNum         ) => -1.1 ],
    [ ( BigInt         ) => 2 ],
    [ ( BigInt         ) => 0 ],
    [ ( BigInt         ) => -2 ],
    [ ( BigPositiveNum ) => 1.1 ],
    [ ( BigPositiveInt ) => 1 ],
  )
{

    my ( $type, $exp ) = @$tpars;
    my ( $ex, $got );

    ok( lives { $got = $type->assert_coerce( $exp ) },
        "good $type: $exp" )
      or diag $@;
    my $class = "$type" =~ /Num/ ? 'Math::BigFloat' : 'Math::BigInt';
    isa_ok( $got, $class );
}

for (
    [ [ 0, 0 ]   => [ 0, 0 ] ],
    [ [ 0, 0.3 ] => [ 0, 0.3 ] ],
    [ 2 => [ 2, 0.5 ] ] )
{

    my ( $in, $exp ) = @$_;

    my $ins = Dumper( $in );
    my $got;
    ok( lives { $got = Alignment->assert_coerce( $in ) },
        "coerce: $ins" )
      or diag $@;
    $exp = [ map { Math::BigFloat->new( $_ ) } @$exp ];
    is( $got, $exp, "value: $ins" );
}

subtest 'Sequence' => sub {

    ok( lives { Sequence->assert_coerce( [0, 1 ] ) }, "two edges" )
      or diag $@;

    ok( lives { Sequence->assert_coerce( [0, 1, 2 ] ) }, "three edges" )
      or diag $@;

    isa_ok( dies { Sequence->assert_coerce( [ 0 ] ) },
            [ "Error::TypeTiny::Assertion" ],
            "one edge" );

    isa_ok( dies { Sequence->assert_coerce( [ 10, 9, 8 ] ) },
            [ "Error::TypeTiny::Assertion" ],
            "decreasing" );

    isa_ok( dies { Sequence->assert_coerce( [ 10, 8, 9 ] ) },
            [ "Error::TypeTiny::Assertion" ],
            "out of order" );
};

subtest 'Spacing' => sub {

    ok( lives { Spacing->assert_coerce( 1 ) }, "w0 > 0" )
      or diag $@;

    ok( lives { Spacing->assert_coerce( -1 ) }, "w0 < 0" )
      or diag $@;

    isa_ok( dies { Spacing->assert_coerce( 0 ) },
            [ "Error::TypeTiny::Assertion" ],
            "zero" );
};

subtest 'Ratio' => sub {

    ok( lives { Ratio->assert_coerce( 0.5 ) }, "positive, < 1" )
      or diag $@;

    ok( lives { Ratio->assert_coerce( 1.5 ) }, "positive, > 1" )
      or diag $@;

    isa_ok( dies { Ratio->assert_coerce( 0 ) },
            [ "Error::TypeTiny::Assertion" ],
            "zero" );

    isa_ok( dies { Ratio->assert_coerce( -1 ) },
            [ "Error::TypeTiny::Assertion" ],
            "negative" );

    isa_ok( dies { Ratio->assert_coerce( 1 ) },
            [ "Error::TypeTiny::Assertion" ],
            "1" );

};

done_testing;
