# t/profile.pl 

use Data::Sorting 'sorted_array';

my @text_chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, ' ', ',', '.', '-' );
my @text_100 = map { join '', @text_chars[ map int(rand(@text_chars)), 1 .. int(rand(100)) ] } 1..100;

foreach ( 1 .. 500 ) {
  # sorted_array( @text_100 )
    sorted_array( @text_100, '-compare' => 'natural' )
  # sorted_array( @text_100, '-extract' => 'self' )
}
