package CLI::Driver::Test2;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has hard_attr => (
    is => 'rw',
    isa => 'Str',
    required => 1
    );

has soft_attr => (
    is => 'rw',
    isa => 'Str|Undef',
    lazy => 1,
    builder => '_build_soft_attr',
);

has optional_attr => (
    is => 'rw',
    isa => 'Str',
);    

has dry_run => (
    is => 'rw',
    isa => 'Bool'
);

################################
###### PRIVATE_ATTRIBUTES ######
################################


############################
###### PUBLIC METHODS ######
############################

method test6_method {
    
    return $self->hard_attr;
}

method test7_method {
   
    confess unless $self->soft_attr;
     
    return $self->soft_attr;
}

method test8_method {

    return $self->optional_attr;    
}

method test9_method {

    return $self->dry_run;
}

method test10_method (Str :$myarg!) {
    return "test10: $myarg";    
}

#############################
###### PRIVATE METHODS ######
#############################

method _build_soft_attr {

    if ($ENV{SOFTATTR}) {
        return $ENV{SOFTATTR};    
    }    
    
    return;
}

1;
