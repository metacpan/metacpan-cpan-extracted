package My::Model;
our $VERSION = '0.01';

use Moose;

with qw/DBIx::Class::Wrapper/;

has  'colour' => ( is => 'rw' , isa => 'Str' , default => 'green' , required => 1 );

1;
