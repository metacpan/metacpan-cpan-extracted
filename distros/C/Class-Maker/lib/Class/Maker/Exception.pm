
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Class::Maker::Exception;
		
our $VERSION = "0.06";  # our $VERSION = '0.0.2';

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

			my %h;
			
			@h{ qw( package file line ) } = caller( $Error::Depth );
			
			foreach ( qw( package file line ) )
			{				
				$this->$_( $h{$_} ) unless $this->$_();
			}
			
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

=head1 BUGS

Not critical: The "text" attribute is not working. Reading/Writing to it somehow goes into nirvana.
I suppose "Error" has same clue about it. Would suggest to inherit from Class::Maker::Exception and add 
and new "info_text" attribute, which will work.
 
=head1 BASE CLASSES

=head2 Class::Maker::Exception 

Has following structure (and inheritable attributes).

	class
	{					
		isa => [qw( Error )],
		
		public =>
		{
			string => [qw( text package file )],
			
			integer => [qw( line )],
		},
	};

=head1 AUTHOR

Murat Uenalan

=head1 SEE ALSO

L<Error>

=cut

