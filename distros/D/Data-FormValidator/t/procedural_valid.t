#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator qw(:validators :matchers);

#Check that the valid_* routines are nominally working.
my $invalid = "fake value";

#For CC Exp test
my @time = localtime(time);

my %tests = (
  valid_american_phone    => "555-555-5555",
  valid_cc_exp            => "10/" . sprintf( "%.2d", ( $time[5] - 99 ) ),
  valid_cc_type           => "MasterCard",
  valid_email             => 'foo@domain.com',
  valid_ip_address        => "64.58.79.230",
  valid_phone             => "123-456-7890",
  valid_postcode          => "T2N 0E6",
  valid_province          => "NB",
  valid_state             => "CA",
  valid_state_or_province => "QC",
  valid_zip               => "94112",
  valid_zip_or_postcode   => "50112",
);

my $i = 1;

foreach my $function ( keys(%tests) )
{
  my $rv;
  my $val       = $tests{$function};
  my $is_valid  = "\$rv = $function('$val');";
  my $not_valid = "\$rv = $function('$invalid');";

  eval $is_valid;
  ok( not $@ and $rv == 1 )
    or diag $@;

  #diag sprintf("%-25s using %-16s", $function, "(valid value)");
  $i++;

  eval $not_valid;
  ok( not $@ and not $rv )
    or diag sprintf( "%-25s using %-16s", $function, "(invalid value)" );
  $i++;
}

#Test cc_number separately since it takes multiple parameters
{
  my $rv;
  my $num = '4111111111111111';

  eval "\$rv = match_cc_number('$num', 'v')";
  ok( not $@ and ( $rv eq $num ) )
    or diag sprintf( "%-25s using %-16s", "match_cc_number", "valid value. " );

  eval "\$rv = valid_cc_number('$invalid', 'm')";
  ok( not $@ and not $rv )
    or diag sprintf
    ( "%-25s using %-16s", "valid_cc_number", "(invalid value)" );
}

$i++;
$i++;

#Test fake validation routine
{
  my $rv;
  eval "\$rv = valid_foobar('$invalid', 'm')";

  ok($@)
    or diag sprintf( "%-25s", "Fake Valid Routine" );
}

ok(
  !valid_email('pretty_b;ue_eyes16@cpan.org'),
  'semi-colons in e-mail aren\'t valid'
);
ok( !valid_email('Ollie 102@cpan.org'), 'spaces in e-mail aren\'t valid' );

ok(
  !valid_email('mark@summersualt.com\0mark@summersault.com'),
  "including a null in an e-mail is not valid."
);

my $address_1 = 'mark';
isnt( $address_1, valid_email($address_1),
  "'$address_1' is not a valid e-mail" );

my $address_2 = 'Mark Stosberg <mark@summersault.com>';
ok( !valid_email($address_2), "'$address_2' is not a valid e-mail" );

my $address_3 = 'mark@summersault.com';
ok( valid_email($address_3), "'$address_3' is a valid e-mail" );

my $address_6 = 'Mark.Stosberg@summersault.com';
ok( valid_email($address_6), "'$address_6' is a valid e-mail" );

my $address_7 = 'Mark_Stosberg@summersault.com';
ok( valid_email($address_7), "'$address_7' is a valid e-mail" );

my $addr_8 = "Mark_O'Doul\@summersault.com";
ok( valid_email($addr_8), "'$addr_8' is a valid e-mail" );
