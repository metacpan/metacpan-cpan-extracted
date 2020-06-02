package CLI::Driver::TestHelp;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has attrArrayReq => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{ [] },
);

has attrOptional => (
    is => 'rw',
    isa => 'Str'
);

has attrFlag => (
    is => 'rw',
    isa => 'Bool'
);

################################
###### PRIVATE_ATTRIBUTES ######
################################


############################
###### PUBLIC METHODS ######
############################

method test14_method(
    Str :$argRequired!,
    Str :$argOptional,
    Str :$noHelp,
    Bool :$argFlag
) {
   return "Done"; 
}

                     
#############################
###### PRIVATE METHODS ######
#############################

1;
