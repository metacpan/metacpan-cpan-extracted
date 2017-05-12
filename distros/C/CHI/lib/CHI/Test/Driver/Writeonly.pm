package CHI::Test::Driver::Writeonly;
$CHI::Test::Driver::Writeonly::VERSION = '0.60';
use Carp;
use strict;
use warnings;
use Moo;
extends 'CHI::Driver::Memory';

sub fetch {
    my ( $self, $key ) = @_;

    croak "write-only cache";
}

1;
