package Data::Validation::Constraints::Path;

use namespace::autoclean;

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Moo;

extends q(Data::Validation::Constraints);

EXCEPTION_CLASS->add_exception( 'ValidPath', {
   parents => [ 'InvalidParameter' ],
   error   => 'Parameter [_1] is not a valid pathname' } );

sub validate {
   my ($self, $val) = @_; return $val !~ m{ [;&*{} ] }mx ? TRUE : FALSE;
}

1;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
