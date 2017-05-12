#!./perl
use strict;
use Test;
BEGIN { plan tests => 1 }

use Clone::Any;

use Benchmark 'cmpthese';

my $struct = {
  map { $_ => [ 
    map { bless { 'foo' => 'Foozle', 'bar' => 'Bazzle' }, 'Example' } 0 .. 99 
  ] } 'a' .. 'z'
};

my %sources = @Clone::Any::SOURCES;
my %tests;
my $counter = 0;
foreach my $type ( keys %sources ) {
  my $func_name = "clone_" . ( ++ $counter );
  eval {
    Clone::Any->import( $func_name, $type, $sources{$type} );
    no strict 'refs';
    my $func = \&{$func_name};
    $tests{$type} = sub { &$func( $struct ) };
  };
}

cmpthese( 10, \%tests);

ok(1); 
