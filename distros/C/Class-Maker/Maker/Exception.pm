package Class::Maker::Exception;
		
our $VERSION = '0.0.1';

use Error qw(:try);

use Exporter;

	Class::Maker::class
	{					
		isa => [qw( Error )],
		
		public =>
		{
			string => [qw( text package file )],
			
			integer => [qw( line )],
		},
	};

	sub _postinit
	{
		my $this = shift;

			local $Error::Depth = $Error::Depth + 1;

			@$this{ qw(package file line) } = caller( $Error::Depth );
			
	return $this;
	}

1;

__END__

=head1 NAME

Class::Maker::Exception - exceptions tuned for Class::Maker

=head1 SYNOPSIS

	use Class::Maker qw(class);
	
	use Class::Maker::Exception qw(:try);
		
	{
	package Exception::Child;
	
		Class::Maker::class
		{
			isa => [qw( Class::Maker::Exception )],
	
			public =>
			{
				string => [qw( email )],
			},
		};
	
	package Exception::ChildChild;
	
		Class::Maker::class
		{
			isa => [qw( Exception::Child )],
	
			public =>
			{
				string => [qw( name )],
			},
		};
	}
	
	sub do_some_stuff
	{
		Exception::ChildChild->throw( email => 'bla@bla.de', name => 'johnny' );
	
	return;
	}
	
		try
		{
			do_some_stuff();
	
		}
		catch Exception::ChildChild with
		{
			foreach my $e (@_)
			{
				print Dumper $e;
			}
		};

=head1 DESCRIPTION

This is mainly a wrapper to "Error" from CPAN. Because it has a very odd inheritance mechanism, 
this wrapper is needed as a workarround.

=cut

