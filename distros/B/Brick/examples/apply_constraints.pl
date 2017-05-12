#!/usr/bin/perl


# THIS IS AN INTERFACE TESTING SCRATCHPAD
# I just want to see how things will look if I do things different ways
use Beancounter;


my $bean = Beancounter->new();






my @Ordered = (
   #[  name          method           args  ],
	[ required  => sub { .... }    => $hash ],
	[ optional  => optional_fields => $hash ],

	[ inside    => in_number       => $hash ],

	[ outside   => ex_number       => $hash ],
	);



$bean->lint( \@Ordered );

my $results = $bean->apply( 
	\%input,
	\@Ordered,
	);
	
$bean->explain( \@Ordered );
	
my $results = $bean->apply( \@Ordered, \%input )
	
	
$results = [
	#[ name    result    message ]
	
	
	
	
	];