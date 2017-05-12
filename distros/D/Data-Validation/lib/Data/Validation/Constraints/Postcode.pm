package Data::Validation::Constraints::Postcode;

use namespace::autoclean;

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Moo;

extends q(Data::Validation::Constraints);

EXCEPTION_CLASS->add_exception( 'ValidPostcode', {
   parents => [ 'InvalidParameter' ],
   error   => 'Parameter [_1] is not a valid postcode' } );

my @patterns = ( 'AN NAA',  'ANN NAA',  'AAN NAA', 'AANN NAA',
                 'ANA NAA', 'AANA NAA', 'AAA NAA', );

for (@patterns) { s{ A }{[A-Z]}gmx; s{ N }{\\d}gmx; s{ [ ] }{\\s+}gmx; }

my $pattern = join '|', @patterns;

sub validate {
   my ($self, $v) = @_; return $v =~ m{ \A (?:$pattern) \z }mox ? TRUE : FALSE;
}

1;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
