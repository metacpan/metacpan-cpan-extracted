package Data::LUID::Generator::Code;

use strict;
use warnings;

use Moose;

has code => qw/is ro isa CodeRef required 1/;

sub next {
    my $self = shift;
    return $self->code->();
}

1;
