our $VERSION = '0.001';

package Basket;

	Class::Maker::class
	{
		version => $VERSION,

		isa => [qw(Array)], # Set::Bag)],

		public =>
		{
			getset => [qw( owner maximum )],
		},
	};

package Commerce::Basket;

	Class::Maker::class
	{
		version => '0.001',

		isa => [qw(Basket)],

		public =>
		{
			getset => [qw( name )],
		},
	};

sub _preinit
{
	my $this = shift;

		$this->name( 'Shopping basket' );
}

sub _postinit
{
	my $this = shift;

		$this->{ref($this).'::POST_INIT_CALLED'} = __LINE__;
}

sub calc
{
	my $this = shift;

		my $sum;

		foreach my $key ( $this->get )
		{
			$sum += $key->price();
		}

return $sum;
}

package Commerce::Item;

	Class::Maker::class
	{
		public =>
		{
			getset => [qw( price name desc )],
		},
	};

sub _preinit
{
	my $this = shift;

		$this->name( $expect );

		$this->{ref($this).'::PRE_INIT_CALLED'} = __LINE__;
}

sub _postinit
{
	my $this = shift;

		$this->{ref($this).'::POST_INIT_CALLED'} = __LINE__;
}

1;
