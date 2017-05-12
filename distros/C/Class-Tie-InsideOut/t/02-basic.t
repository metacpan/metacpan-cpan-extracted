#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use_ok('Tie::InsideOut', 0.05);

our %Key1;
our @Key2;

{
  my $hash_ref = { };
  tie %$hash_ref, 'Tie::InsideOut';
  ok( tied(%$hash_ref), "tied" );

  ok( !scalar(%$hash_ref), "scalar context" );

  ok( keys(%Key1) == 0, "no values defined yet");

  ok( !defined($hash_ref->{Key1}), "fetch undefined" );

  undef $@;
  eval { $hash_ref->{Key1} = 1234; };
  ok( !$@, "no errors in storing valied key" );

  ok( scalar(%$hash_ref), "scalar context" );

  ok( keys(%Key1) == 1, "first value stored");
  ok( exists $hash_ref->{Key1}, "exists" );
  ok( $hash_ref->{Key1} == 1234, "fetch" );

  undef $@;
  eval { $hash_ref->{Key2} = 9876; };
  ok( $@, "error in storing invalid key" );

  undef $@;
  eval { print STDERR $hash_ref->{Key2}; };
  ok( $@, "error in fetching invalid key" );

  # TODO - test firskey/nextkey (more than one key)

  my @keys = keys %$hash_ref;
  ok( @keys == 1 );
  ok( $keys[0] eq "Key1" );

  ok( delete $hash_ref->{Key1} == 1234, "delete" );

  @keys = keys %$hash_ref;
  ok( @keys == 0 );

}

{
  my $hash_ref = { };
  tie %$hash_ref, 'Tie::InsideOut';
  ok( tied(%$hash_ref), "tied" );

  ok( keys(%Key1) == 0, "no values defined yet");

  ok( !defined($hash_ref->{Key1}), "fetch undefined" );

  undef $@;
  eval { $hash_ref->{Key1} = 1234; };
  ok( !$@, "no errors in storing valied key" );

  ok( keys(%Key1) == 1, "first value stored");
  ok( $hash_ref->{Key1} == 1234, "fetch" );

  undef $@;
  eval { $hash_ref->{Key2} = 9876; };
  ok( $@, "error in storing invalid key" );

  undef $@;
  eval { print STDERR $hash_ref->{Key2}; };
  ok( $@, "error in fetching invalid key" );

}

