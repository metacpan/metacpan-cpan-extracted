#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;

eval { require CGI;CGI->VERSION(4.35); };
plan skip_all => 'CGI 4.35 or higher not found' if $@;

# Test that constrants can refer to fields that are not mentioned
# in 'required' or 'optional'

my $profile = {
  required    => [qw(foo)],
  optional    => [qw(bar)],
  constraints => {
    foo => {
      constraint => sub {
        if ( defined $_[0] && defined $_[1] )
        {
          return $_[0] eq $_[1];
        }
        else
        {
          return;
        }
      },
      params => [qw(foo baz)],
    },
  },
};
my $input = {
  foo => 'stuff',
  bar => 'other stuff',
  baz => 'stuff',
};

my $results = Data::FormValidator->check( $input, $profile );
ok( !$results->has_invalid(), 'no_invalids' );
ok( $results->valid('foo'),   'foo valid' );

{
  # with CGI object as input.
  my $q = CGI->new($input);
  my $results;
  eval { $results = Data::FormValidator->check( $q, $profile ); };
  is( $@, '', 'survived eval' );
  ok( !$results->has_invalid(), 'no_invalids' );
  ok( $results->valid('foo'),   'foo valid' );

}

done_testing;
