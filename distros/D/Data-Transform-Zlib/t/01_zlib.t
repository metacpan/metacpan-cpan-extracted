use Test::More tests => 10;
BEGIN { use_ok('Data::Transform::Zlib') };
use Data::Transform::Line;
use Data::Transform::Stackable;

my $original = Data::Transform::Zlib->new();
my $clone = $original->clone();

foreach my $filter ( $original, $clone ) {

  isa_ok( $filter, "Data::Transform" );

  my $teststring = "All the little fishes";
  my $compressed = $filter->put( [ $teststring, Data::Transform::Meta::EOF->new() ] );
  is (@$compressed, 3, "sending a string plus EOF gets the right amount of packets");
  pop @$compressed; # the EOF packet doesn't go over the wire normally
  my $answer = $filter->get( $compressed );
  is( @$answer, 1, 'decoding those gets the correct number of packets');
  is( $answer->[0], $teststring, 'the decoded string equals the original' );

}

my $stack = Data::Transform::Stackable->new( Filters =>
	[ 
		Data::Transform::Zlib->new(),
		Data::Transform::Line->new(),
	],
);

my @input = ('testing one two three', 'second test', 'third test', Data::Transform::Meta::EOF->new);

my $out = $stack->put( \@input );
my $back = $stack->get( $out );

is_deeply( \@input, $back, 'input equals output');
