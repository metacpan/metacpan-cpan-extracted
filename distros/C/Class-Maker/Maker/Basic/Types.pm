package Class::Maker::Type;

sub new
{
	my $this = ref( $_[0] ) || $_[0];

return bless { tieobj => 'Tie::HASH' }, $this;
}

package Class::Maker::Basic::Types;

{
	package Class::Maker::Basic::Types::int;

	sub get
	{
	}

	sub set
	{
	}
}

{
	package Class::Maker::Basic::Types::string;

	sub get
	{
	}

	sub set
	{
	}
}

1;
