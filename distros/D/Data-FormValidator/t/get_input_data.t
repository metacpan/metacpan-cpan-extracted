#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;

eval { require CGI;CGI->VERSION(4.35); };
plan skip_all => 'CGI 4.35 or higher not found' if $@;

{
  my $results = Data::FormValidator->check( {}, {} );
  is_deeply( $results->get_input_data, {},
    'get_input_data works for empty hashref' );
}

my $q = CGI->new( { key => 'value' } );
my $results = Data::FormValidator->check( $q, {} );

is_deeply( $results->get_input_data, $q,
  'get_input_data works for CGI object' );

{
  my $href = $results->get_input_data( as_hashref => 1 );
  is_deeply(
    $href,
    { key => 'value' },
    'get_input_data( as_hashref => 1 ) works for CGI object'
  );
}
done_testing;
