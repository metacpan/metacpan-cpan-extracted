package Mock::Data::TreeValidator::Result;
use Moose;

has 'clean' => ( is => 'rw' );
sub valid { 1 }
with 'Data::TreeValidator::Result';

1;
