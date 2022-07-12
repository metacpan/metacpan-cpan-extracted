package MyTest::Exception;
use Moo;
use Types::Standard qw( Str );

use overload '""' => 'as_string';

has error => (is => 'ro', isa => Str);

sub as_string { $_[0]->error }

use namespace::autoclean;
1;
