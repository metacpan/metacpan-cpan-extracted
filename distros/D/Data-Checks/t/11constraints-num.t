#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::test", qw( test_constraint );

use Data::Checks qw( Num NumGT NumGE NumLE NumLT NumRange NumEq );

use constant {
   NAN => 0+"NaN",
};

# Num
test_constraint Num => Num,
   [
      'plain integer'      => 1234,
      'plain float'        => 5.67,
      'stringified number' => "89",
      'object with numify' => ClassWithNumOverload->new,
   ],
   [
      'object with stringifty' => ClassWithStrOverload->new,
      'not-a-number'           => NAN,
      '"NaN"'                  => NAN . "",
      '"nan"'                  => "nan",
   ];

# Num bounded
{
   my $checker_gt = t::test::make_checkdata( NumGT(0), "Value" );

   ok(  t::test::check_value( $checker_gt,  123 ), 'NumGT accepts plain integer' );
   ok( !t::test::check_value( $checker_gt,  0   ), 'NumGT rejects bound' );
   ok( !t::test::check_value( $checker_gt, -123 ), 'NumGT rejects negative integer' );

   my $checker_ge = t::test::make_checkdata( NumGE(0), "Value" );

   ok(  t::test::check_value( $checker_ge,  123 ), 'NumGE accepts plain integer' );
   ok(  t::test::check_value( $checker_ge,  0   ), 'NumGE accepts bound' );
   ok( !t::test::check_value( $checker_ge, -123 ), 'NumGE rejects negative integer' );

   my $checker_le = t::test::make_checkdata( NumLE(100), "Value" );

   ok(  t::test::check_value( $checker_le, 25  ), 'NumLE accepts plain integer' );
   ok(  t::test::check_value( $checker_le, 100 ), 'NumLE accepts bound' );
   ok( !t::test::check_value( $checker_le, 200 ),   'NumLE rejects too large' );

   my $checker_lt = t::test::make_checkdata( NumLT(100), "Value" );

   ok(  t::test::check_value( $checker_lt, 25  ), 'NumLT accepts plain integer' );
   ok( !t::test::check_value( $checker_lt, 100 ), 'NumLT rejects bound' );
   ok( !t::test::check_value( $checker_lt, 200 ),   'NumLT rejects too large' );
}

# Num range
{
   my $checker = t::test::make_checkdata( NumRange(10, 20), "Value" );

   ok( !t::test::check_value( $checker,   0 ), 'NumRange rejects below lower bound' );
   ok(  t::test::check_value( $checker,  10 ), 'NumRange accepts lower bound' );
   ok(  t::test::check_value( $checker,  15 ), 'NumRange accepts midway' );
   ok( !t::test::check_value( $checker,  25 ), 'NumRange rejects upper bound' );
   ok( !t::test::check_value( $checker,  40 ), 'NumRange rejects above upper bound' );
}

# Num eq set
{
   # Stack discipline test
   my @vals = ( 2, 4, NumEq(1, 3, 5), 6, 8 );
   is( scalar @vals, 5, '5 values in the array' );
   ok( ref $vals[2], 'constraint is some kind of ref' );
   my $checker = t::test::make_checkdata( $vals[2], "Value" );

   ok(  t::test::check_value( $checker, 1 ), 'NumEq accepts a value' );
   ok(  t::test::check_value( $checker, 5 ), 'NumEq accepts a value' );
   ok( !t::test::check_value( $checker, 2 ), 'NumEq rejects a value not in the list' );

   my $checker_10 = t::test::make_checkdata( NumEq(10), "Value" );

   ok(  t::test::check_value( $checker_10, 10 ), 'NumEq singleton accepts the value' );
   ok( !t::test::check_value( $checker_10, 20 ), 'NumEq singleton rejects a different value' );

   my $checker_zero = t::test::make_checkdata( NumEq(0), "Value" );

   ok(  t::test::check_value( $checker_zero, 0     ), 'NumEq zero accepts zero' );
   ok( !t::test::check_value( $checker_zero, undef ), 'NumEq zero rejects undef' );
}

# Debug inspection
is( Data::Checks::Debug::inspect_constraint( Num ), "Num",
   'debug inspect Num' );
is( Data::Checks::Debug::inspect_constraint( NumGT(10) ), "NumGT(10)",
   'debug inspect NumGT(10)' );
is( Data::Checks::Debug::inspect_constraint( NumGE(10) ), "NumGE(10)",
   'debug inspect NumGE(10)' );
is( Data::Checks::Debug::inspect_constraint( NumLE(10) ), "NumLE(10)",
   'debug inspect NumLE(10)' );
is( Data::Checks::Debug::inspect_constraint( NumLT(10) ), "NumLT(10)",
   'debug inspect NumLT(10)' );
is( Data::Checks::Debug::inspect_constraint( NumRange(10, 20) ), "NumRange(10, 20)",
   'debug inspect NumRange(10, 20)' );
is( Data::Checks::Debug::inspect_constraint( NumEq(10) ), "NumEq(10)",
   'debug inspect NumEq(10)' );
is( Data::Checks::Debug::inspect_constraint( NumEq(10, 20) ), "NumEq(10, 20)",
   'debug inspect NumEq(10, 20)' );

done_testing;
