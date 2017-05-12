package Data::Validation::Constraints::Email;

use namespace::autoclean;

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Email::Valid;
use Moo;

extends q(Data::Validation::Constraints);

EXCEPTION_CLASS->add_exception( 'ValidEmail', {
   parents => [ 'InvalidParameter' ],
   error   => 'Parameter [_1] is not a valid email address' } );

sub validate {
   return Email::Valid->address( $_[ 1 ] ) ? TRUE : FALSE;
}

1;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
