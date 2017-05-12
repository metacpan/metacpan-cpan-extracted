use Test::Simple tests => 3;

use lib '../blib/lib','../blib/arch';

use Algorithm::BitVector;

# Test 1 (Data generation with intVal option):

my $b = Algorithm::BitVector->new( intVal => 15 );
ok ( int($b) == 15, 'BitVector generation with intVal option works' );

# Test 2 (Data generation with size option):

$b = Algorithm::BitVector->new( size => 16 );
ok ( "$b" eq "0000000000000000", 'BitVector generation with size option works' );

# Test 4 (Data generation with textstring option):

$b = Algorithm::BitVector->new( textstring => "hello" );
$text = $b->get_text_from_bitvector();
ok ( $text eq "hello", 'BitVector generation with textstring option works' );


