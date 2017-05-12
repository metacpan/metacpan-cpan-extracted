
package DBIx::Romani::Query::SQL::TTT::Keyword;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $keyword;

	if ( ref($args) eq 'HASH' )
	{
		$keyword = $args->{keyword};
	}
	else
	{
		$keyword = $args;
	}

	my $self = {
		keyword => $keyword,
	};

	bless  $self, $class;
	return $self;
}

sub get_keyword { return shift->{keyword}; }

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_ttt_keyword( $self, @_ );
}

sub clone
{
	my $self = shift;

	return DBIx::Romani::Query::SQL::TTT::Keyword->new({ keyword => $self->get_keyword() });
}

1;

