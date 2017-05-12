use Readonly ;
use Tie::IxHash ;

Readonly my $SCALAR => '' ; 
Readonly my $ARRAY => 'ARRAY' ;

tie my %requirement, Tie::IxHash =>
	(
	UUID => {TYPE =>$SCALAR, DEFAULT => undef},
	TYPE => {TYPE =>$SCALAR, DEFAULT => 'requirement', ACCEPTED_VALUES => ['use case', 'requirement']},
	ABSTRACTION_LEVEL => {TYPE =>$SCALAR, DEFAULT => 'system', ACCEPTED_VALUES => ['architecture', 'system', 'module', 'none'], OPTIONAL => 1},

	ORIGINS => {TYPE =>$ARRAY, DEFAULT => []} ,
	CREATORS => {TYPE =>$ARRAY, DEFAULT => []},

	CATEGORIES => {TYPE =>$ARRAY, DEFAULT => []},
	NAME => {TYPE =>$SCALAR, DEFAULT =>''} ,

	DESCRIPTION => {TYPE =>$SCALAR, DEFAULT => ''},

	LONG_DESCRIPTION => {TYPE =>$SCALAR, DEFAULT => ''},
	RATIONALE => {TYPE =>$SCALAR, DEFAULT => ''},
	FIT_CRITERIA => {TYPE =>$SCALAR, DEFAULT => ''},

	SATISFACTION => {TYPE =>$SCALAR, DEFAULT => 'undef'}, 
	DISSATISFACTION => {TYPE =>$SCALAR, DEFAULT => 'undef'},

	DOCUMENTATION_LINKS =>{TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	RELATED_REQUIREMENTS =>{TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	SUB_REQUIREMENTS => {TYPE =>$ARRAY, DEFAULT => []},

	REVIEWED => {TYPE =>$SCALAR, DEFAULT => 0},
	IMPLEMENTATION_STATE => {TYPE =>$SCALAR, DEFAULT => undef},
	IMPLEMENTATION_PRIORITY => {TYPE =>$SCALAR, DEFAULT => undef},
	) ;
		
tie my %use_case, Tie::IxHash =>
	(
	UUID => {TYPE =>$SCALAR, DEFAULT => undef},
	TYPE => {TYPE =>$SCALAR, DEFAULT => 'requirement', ACCEPTED_VALUES => ['use case', 'requirement']},
	ABSTRACTION_LEVEL => {TYPE =>$SCALAR, DEFAULT => 'system', ACCEPTED_VALUES => ['architecture', 'system', 'module', 'none'], OPTIONAL => 1},
	
	ORIGINS => {TYPE =>$ARRAY, DEFAULT => []} ,
	CREATORS => {TYPE =>$ARRAY, DEFAULT => []},

	NAME => {TYPE =>$SCALAR, DEFAULT =>''} ,

	DESCRIPTION => {TYPE =>$SCALAR, DEFAULT => ''},
	
	PRECONDITIONS => {TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	ACTORS_INTERESTS => {TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	DEFINITION => {TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},

	SATISFACTION => {TYPE =>$SCALAR, DEFAULT => 'undef'}, 
	DISSATISFACTION => {TYPE =>$SCALAR, DEFAULT => 'undef'},

	DOCUMENTATION_LINKS =>{TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	RELATED_REQUIREMENTS =>{TYPE =>$ARRAY, DEFAULT => [], OPTIONAL => 1},
	SUB_REQUIREMENTS => {TYPE =>$ARRAY, DEFAULT => []},

	REVIEWED => {TYPE =>$SCALAR, DEFAULT => 0},
	IMPLEMENTATION_STATE => {TYPE =>$SCALAR, DEFAULT => undef},
	IMPLEMENTATION_PRIORITY => {TYPE =>$SCALAR, DEFAULT => undef},
	) ;
	
tie my %data, Tie::IxHash =>	(REQUIREMENT => \%requirement, USE_CASE => \%use_case) ;

my ($package) = caller() ;

unless(defined $package)
	{
	use Data::TreeDumper  ;
	use Data::TreeDumper::Utils qw ( no_sort_filter ) ;
	
	print DumpTree \%data, 'Templates', DISPLAY_ADDRESS => 0, USE_ASCII => 1 , NO_NO_ELEMENTS => 1, FILTER => \&no_sort_filter ;

	}

{
VERSION => 2.0, 
TEMPLATE=> \%data,
} ;
