#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;

eval { require CGI;CGI->VERSION(4.35); };
plan skip_all => 'CGI 4.35 or higher not found' if $@;

# test profile
my $input_profile = {
  dependency_groups => {
    password => [qw/pass1 pass2/],
  },
};
my $input_hashref = { pass1 => 'foo' };

my ( $valids, $missings, $invalids, $unknowns );
my $result;
my @fields = (qw/pass1 pass2/);
my $validator = Data::FormValidator->new( { default => $input_profile } );

foreach my $fields ( [qw/pass1 pass2/], [qw/pass2 pass1/] )
{
  my ( $good, $bad ) = @$fields;
  $input_hashref = { $good => 'foo' };

  ##
  ## validate()

  eval {
    ( $valids, $missings, $invalids, $unknowns ) =
      $validator->validate( $input_hashref, 'default' );
  };
  ok( !$@, "no eval problems" );

  my %missings = map { $_ => 1 } @$missings;
  is( $valids->{$good}, $input_hashref->{$good}, "[$good] valid" );
  ok( $missings{$bad}, "missing [$bad]" );

  ##
  ## check()

  my $q = CGI->new("$good=foo");
  foreach my $input ( $input_hashref, $q )
  {
    eval { $result = $validator->check( $input, 'default' ); };

    ok( !$@, "no eval problems" );
    isa_ok( $result, "Data::FormValidator::Results", "returned object" );

    ok( $result->has_missing,     "has_missing returned true" );
    ok( $result->missing($bad),   "missing($bad) returned true" );
    ok( !$result->missing($good), "missing($good) returned false" );
    ok( $result->valid($good),    "valid($good) returned true" );
    ok( !$result->valid($bad),    "valid($bad) returned true" );
  }
}
done_testing;
