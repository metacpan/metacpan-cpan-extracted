package Dwarf::SQLBuilder;
use Dwarf::Pragma;
use Dwarf::SQLBuilder::Query;

sub new_query {
	my $self = shift;
	return Dwarf::SQLBuilder::Query->new->new_query(@_);
}

1;
