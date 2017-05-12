#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 26;
use Data::FormValidator qw(:validators :matchers);

#Check that the match_* routines are nominally working.
my $invalid = "fake value";

#For CC Exp test
my @time = localtime(time);

my %tests = (
  match_american_phone    => "555-555-5555",
  match_cc_exp            => "10/" . sprintf( "%.2d", ( $time[5] - 99 ) ),
  match_cc_type           => "MasterCard",
  match_email             => 'foo@domain.com',
  match_ip_address        => "64.58.79.230",
  match_phone             => "123-456-7890",
  match_postcode          => "T2N 0E6",
  match_province          => "NB",
  match_state             => "CA",
  match_state_or_province => "QC",
  match_zip               => "94112",
  match_zip_or_postcode   => "50112",
);

my $i = 1;

foreach my $function ( keys(%tests) )
{
  my $rv;
  my $val       = $tests{$function};
  my $is_valid  = "\$rv = $function('$val');";
  my $not_valid = "\$rv = $function('$invalid');";

  eval $is_valid;
  ok( not $@ and ( $rv eq $val ) )
    or diag sprintf( "%-25s using %-16s", $function, "valid value. " );
  $i++;

  eval $not_valid;
  ok( not $@ and not $rv )
    or diag sprintf( "%-25s using %-16s", $function, "invalid value. " );
  $i++;
}

#Test cc_number separately since it takes multiple parameters
my $rv;
my $num = '4111111111111111';
eval "\$rv = match_cc_number('$num', 'v')";
ok( not $@ and ( $rv eq $num ) )
  or diag sprintf( "%-25s using %-16s", "match_cc_number", "valid value. " );

eval "\$rv = match_cc_number('$invalid', 'm')";
ok( not $@ and not $rv )
  or diag sprintf( "%-25s using %-16s", "match_cc_number", "invalid value. " );
