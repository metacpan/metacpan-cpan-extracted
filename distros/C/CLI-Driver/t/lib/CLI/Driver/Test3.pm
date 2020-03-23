package CLI::Driver::Test3;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has reqattr => (
    is => 'rw',
    isa => 'Str',
    required => 1
    );

has optattr => (
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

method test11_method (Str :$reqarg!,
					  Str :$optarg ) {
					  	
	confess unless $self->optattr; # req for this test only	
	confess unless $optarg;	 # req for this test only
}

method test12_method (Str :$reqarg!,
					  Str :$optarg ) {

	confess if $optarg;	 # not req for this test
}

#############################
###### PRIVATE METHODS ######
#############################

1;
