package Class::Maker::Basic::Handler::Attributes;

use Class::Maker::Basic::Constructor; #qw(defaults);

our $name;

sub new
{
	return \&Class::Maker::Basic::Constructor::new;
}

sub simple_new
{
	return \&Class::Maker::Basic::Constructor::simple_new;
}

sub debug_verbose
{
	my $name = $name;

	return sub
	{
		warn "$name: it works..." if $DEBUG;
	}
}

	# create an "lvalue" attribute handler, which also accepts
	#
	# $this->member = 'syntax' instead normal $this->member( 'syntax' );

sub default
{
	my $name = $name;

	return sub : lvalue
	{
		my $this = shift;

	@_ ? $this->{$name} = shift : $this->{$name};
	}
}

sub array
{
	my $name = $name;

	return sub
	{
		my $this = shift;

			$this->{$name} = [] unless exists $this->{$name};

			@{ $this->{$name} } = () if @_;

			foreach ( @_ )
			{
				push @{ $this->{$name} }, ref($_) eq 'ARRAY' ? @{ $_ } : $_;
			}

	return wantarray ? @{$this->{$name}} : $this->{$name};
	}
}

sub hash
{
	my $name = $name;

	return sub
	{
			my $this = shift;

			unless( exists $this->{$name} )
			{
				$this->{$name} = {};
			}

			foreach my $href ( @_ )
			{
				if( ref($href) eq 'HASH' )
				{
					foreach my $key ( keys %{ $href } )
					{
						$this->{$name}->{$key} = $href->{$key};
					}
				}
			}

	return wantarray ? %{ $this->{$name} } : $this->{$name};
	}
}

1;
