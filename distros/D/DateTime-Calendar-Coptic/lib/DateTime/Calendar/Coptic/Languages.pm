package DateTime::Calendar::Coptic::Languages;
use base ( "DateTime::Languages" );

BEGIN
{
use strict;
use warnings;
use vars qw ( $VERSION );

	$VERSION = "0.05";


	foreach my $set ( [ 'ar', 'ara' => 'Arabic' ],
			  [ 'cop'                       => 'Coptic' ]
		)
	{
	    my $module = pop @$set;
	    @DateTime::Languages::ISOMap{ @$set } = ($module) x @$set;
	}

	# print "Module: $DateTime::Languages::ISOMap{cop}\n";
	# print DateTime::Languages->iso_codes, "\n";

}


sub class_base
{
	"DateTime::Calendar::Coptic::Languages";
}

1;
__END__
