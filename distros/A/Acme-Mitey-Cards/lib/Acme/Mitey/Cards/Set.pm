package Acme::Mitey::Cards::Set;

our $VERSION   = '0.008';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );

use Carp qw( croak );
use List::Util ();

has cards => (
	is       => lazy,
	isa      => 'CardArray',
);

sub _build_cards {
	my $self = shift;

	return [];
}

sub to_string {
	my $self = shift;

	return join " ", map $_->to_string, @{ $self->cards };
}

sub count {
	my $self = shift;

	scalar @{ $self->cards };
}

sub take {
	my ( $self, $n ) = ( shift, @_ );

	croak "Not enough cards" if $n > $self->count;

	my @taken = splice( @{ $self->cards }, 0, $n );
	return __PACKAGE__->new( cards => \@taken );
}

sub shuffle {
	my $self = shift;

	@{ $self->cards } = List::Util::shuffle( @{ $self->cards } );

	return $self;
}

1;
