package Data::Format::Error::ValueNumericException 0.2;

use 5.008;
use warnings;

use Data::Format::Error;
use base qw(Data::Format::Error);

sub new
{
    my $self = shift;
    $self->SUPER::new(
        -text => qq/Value must be an numeric value/
    );
}
1;