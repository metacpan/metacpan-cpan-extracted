package CLI::Driver::Test;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has env => (
    is => 'rw',
    isa => 'Str|Undef',
    lazy => 1,
    builder => '_build_env',
);

################################
###### PRIVATE_ATTRIBUTES ######
################################


############################
###### PUBLIC METHODS ######
############################

method test1_method {
   return "hello world"; 
}

method test2_method (Str :$myarg!) {
    return "test2: $myarg";    
}

method test3_method (Str :$myarg!,
                     Str :$softargX) {

    if (!$softargX) {
        if ($ENV{SOFTARGX}) {
        # ok 
        }
        else {
            confess;    
        }
    }     
    
    return $softargX;
}

method test4_method (Str :$myarg!,
                     Str :$softargX,
                     Str :$optionalargZ) {
                         
    if (!$softargX) {
        if ($ENV{SOFTARGX}) {
        # ok 
        }
        else {
            confess;    
        }
    }    
    
    return $optionalargZ;
}


method test5_method (Str :$myarg!,
                     Str :$softargX,
                     Str :$optionalargZ,
                     Bool :$dry_run) {
                         
    if (!$softargX) {
        if ($ENV{SOFTARGX}) {
        # ok 
        }
        else {
            confess;    
        }
    }    
   
    return $dry_run;     
}
                     
#############################
###### PRIVATE METHODS ######
#############################

method _build_env {

    if ($ENV{ENV}) {
        return $ENV{ENV};
    }
}

1;
