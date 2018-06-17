package Data::Format::Error::ValueProvideException 0.2;

use 5.008;
use warnings;

use Data::Format::Error;
use base qw(Data::Format::Error);

sub new
{
    my $self = shift;
    $self->SUPER::new(
        -text => qq/Value must be provided/
    );
}
1;