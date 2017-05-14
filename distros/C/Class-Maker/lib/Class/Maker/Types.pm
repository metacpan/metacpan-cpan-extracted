package Class::Maker::Type;

our $VERSION = "0.06";

sub new
{
	my $this = ref( $_[0] ) || $_[0];

return bless { tieobj => 'Tie::HASH' }, $this;
}

package Class::Maker::Types;

{
	package Class::Maker::Types::int;

	sub get
	{
	}

	sub set
	{
	}
}

{
	package Class::Maker::Types::string;

	sub get
	{
	}

	sub set
	{
	}
}

1;
