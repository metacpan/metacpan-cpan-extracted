package Fake::Librarian;

use strict;
use warnings;

use Data::FlexSerializer;

my $serializer = Data::FlexSerializer->new(
    detect_compression  => 1,
    detect_sereal       => 1,
    output_format       => 'sereal',
);

# -----------------------------------------------------------------------------
# Object methods

sub new {
	my $self = shift;

	# create an attributes hash
	my $atts = {
		'count'	=> 0
	};

	# create the object
	bless $atts, $self;
	return $atts;
}

sub search { 
	shift;
    my @guids = map {s!.*/(.*?).dat$!$1!; $_} glob('t/data/*.dat');
    return \@guids;
}

sub extract { 
	shift;
    my $guid = shift;
    my $data = $serializer->deserialize_from_file( "t/data/$guid.dat" );
    return $data;
}

sub can { 1 }

DESTROY { }

END { }

1;
