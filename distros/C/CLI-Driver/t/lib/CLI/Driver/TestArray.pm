package CLI::Driver::TestArray;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has attributeArrayReq => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{ [] },
);

has attributeArrayOpt => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{ [] },
);

################################
###### PRIVATE_ATTRIBUTES ######
################################


############################
###### PUBLIC METHODS ######
############################

method test13_method1(
    ArrayRef[Str] :$methodArrayReq,
    ArrayRef[Str] :$methodArrayOpt = []
) {
   return (
    $self->attributeArrayReq,
    $self->attributeArrayOpt,
    $methodArrayReq,
    $methodArrayOpt
   ); 
}

                     
#############################
###### PRIVATE METHODS ######
#############################

1;
