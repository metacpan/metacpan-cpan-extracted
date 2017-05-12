#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::FormValidator;

# For RT#45177
{
  my $results = Data::FormValidator->check(
    { nine_is_ok => 9 },
    {
      required                => ['nine_is_ok'],
      constraint_methods      => { 'nine_is_ok' => qr/^(9)$/ },
      untaint_all_constraints => 1,
    } );
  is( $results->valid('nine_is_ok'),
    9, "nine should be valid for 9 with capturing parens (untainted)" );
}
{
  my $results = Data::FormValidator->check(
    { nine_is_ok => 9 },
    {
      required                => ['nine_is_ok'],
      constraint_methods      => { 'nine_is_ok' => qr/^9$/ },
      untaint_all_constraints => 1,
    } );
  is( $results->valid('nine_is_ok'),
    9, "nine should be valid for 9 without capturing parens (untainted)" );
}
{
  my $results = Data::FormValidator->check(
    { zero_is_ok => 0 },
    {
      required                => ['zero_is_ok'],
      constraint_methods      => { 'zero_is_ok' => qr/^0$/ },
      untaint_all_constraints => 1,
    } );
  is( $results->valid('zero_is_ok'),
    0, "zero should be valid without capturing parens (untainted)" );
}
{
  my $results = Data::FormValidator->check(
    { zero_is_ok => 0 },
    {
      required                => ['zero_is_ok'],
      constraint_methods      => { 'zero_is_ok' => qr/^(0)$/ },
      untaint_all_constraints => 1,
    } );
  is( $results->valid('zero_is_ok'),
    0, "zero should be valid with capturing parens (untainted)" );
}
{
  my $results = Data::FormValidator->check(
    { nine_is_ok => 9 },
    {
      required           => ['nine_is_ok'],
      constraint_methods => { 'nine_is_ok' => qr/^(9)$/ },
    } );
  is( $results->valid('nine_is_ok'),
    9, "nine should be valid for 9 with capturing parens" );
}
{
  my $results = Data::FormValidator->check(
    { nine_is_ok => 9 },
    {
      required           => ['nine_is_ok'],
      constraint_methods => { 'nine_is_ok' => qr/^9$/ },
    } );
  is( $results->valid('nine_is_ok'),
    9, "nine should be valid for 9 without capturing parens" );
}
{
  my $results = Data::FormValidator->check(
    { zero_is_ok => 0 },
    {
      required           => ['zero_is_ok'],
      constraint_methods => { 'zero_is_ok' => qr/^0$/ },
    } );
  is( $results->valid('zero_is_ok'),
    0, "zero should be valid without capturing parens" );
}
{
  my $results = Data::FormValidator->check(
    { zero_is_ok => 0 },
    {
      required           => ['zero_is_ok'],
      constraint_methods => { 'zero_is_ok' => qr/^(0)$/ },
    } );
  is( $results->valid('zero_is_ok'),
    0, "zero should be valid with capturing parens" );
}
