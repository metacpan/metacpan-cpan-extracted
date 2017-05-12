package Data::Validation::Constraints::Password;

use namespace::autoclean;

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Moo;

extends q(Data::Validation::Constraints);

EXCEPTION_CLASS->add_exception( 'ValidPassword', {
   parents => [ 'InvalidParameter' ],
   error   => 'Parameter [_1] is not a valid password',
   explain => 'Must be longer than {min_length} characters long, contain '
            . 'non alpha characters and must not be wholely numeric' } );

sub validate {
   my ($self, $val) = @_; my $min_length = $self->min_length || 6;

   length $val < $min_length and return FALSE;
   $val =~ m{ \A \d+ \z }mx and return FALSE;
   $val =~ tr{A-Z}{a-z}; $val =~ tr{a-z}{}d;
   return length $val > 0 ? TRUE : FALSE;
}

1;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
