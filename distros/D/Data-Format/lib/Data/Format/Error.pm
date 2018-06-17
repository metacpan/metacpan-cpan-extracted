package Data::Format::Error 0.2;

use 5.008;
use strict;
use warnings;

use Error;
use base qw(Error);

sub new
{
    my $self = shift;
    my %args = @_;

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;

    $self->SUPER::new(-text => $args{'-text'});
}
1;