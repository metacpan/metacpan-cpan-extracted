package Acme::Mitey::Cards::Suit;

our $VERSION   = '0.015';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -all );
use Acme::Mitey::Cards::Types qw( :types );

has name => (
	is       => ro,
	isa      => NonEmptyStr,
	required => true,
);

has abbreviation => (
	is       => lazy,
	isa      => Str,
	builder  => sub { uc substr( shift->name, 0, 1 ) },
);

has colour => (
	is       => ro,
	isa      => Str,
	required => true,
);

{
	my ( $hearts, $diamonds, $spades, $clubs );

	signature_for $_ => ( pos => [] )
		for qw( hearts diamonds spades clubs );


	sub hearts {
		$hearts ||= Acme::Mitey::Cards::Suit->new( name => 'Hearts', colour => 'red' );
	}

	sub diamonds {
		$diamonds ||= Acme::Mitey::Cards::Suit->new( name => 'Diamonds', colour => 'red' );
	}

	sub spades {
		$spades ||= Acme::Mitey::Cards::Suit->new( name => 'Spades', colour => 'black' );
	}

	sub clubs {
		$clubs ||= Acme::Mitey::Cards::Suit->new( name => 'Clubs', colour => 'black' );
	}
}

signature_for standard_suits => (
	pos => [],
);

sub standard_suits {
	my $class = shift;

	return (
		$class->spades,
		$class->hearts,
		$class->diamonds,
		$class->clubs,
	);
}

1;
