
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use Class::Maker qw(:all);

use Data::Dump qw(dump);

sub _install_method
{
    no strict 'refs';

    my $attributes_handler_package = shift;

    my $pkg = shift;

    my $type = shift;
    
    my $name = shift;
    
    $Class::Maker::Fast::Handler::Attributes::name = $explicit ? "${pkg}::$name" : $name;
   
    no strict 'refs';
    
    if( *{ "$attributes_handler_package::${type}" }{CODE} )
    {
	return *{ "${pkg}::$name" } = $attributes_handler_package->$type;
    }
    
    return *{ "${pkg}::$name" } = $attributes_handler_package->default;
}

{
package Class::Maker::Fast::Handler::Attributes;

{ 
	package Class::Maker::Fast::Handler::Attributes::default;

	sub get : method
	{
		my $this = shift;

		my $name = shift;
		
	return $this->{$name};
	}

	sub set : method
	{
		my $this = shift;

		my $name = shift;
		
	return $this->{$name} = shift;
	}

		# when setting the value via the constructor
		
	sub init : method
	{	
	}
	
	sub reset : method
	{
		# do reset to default value from instantiation
	}
}

sub default
{
	my $name = $name;

	return sub : lvalue
	{
		my $this = shift;

		my $name = $name;
	
		$this->{$name} = shift if @_;

		$this->{$name};
	};
}

}

class "Dummy",
{
    public => 
    {
	scalar => [qw(one two)],
    }
};


my $pkg = 'Dummy';
my $name = 'one';

_install_method( 'Class::Maker::Fast::Handler::Attributes', 'Dummy', 'scalar', 'one' );

=pod
=head1 
*{ "${pkg}::$name" } = sub : lvalue
{
    my $this = shift;

    $this->{$_[0]} = $_[1];

$this->{$_[0]};
};
=cut

my $dummy = Dummy->new();

print $dummy->one( "One" );
$dummy->two( "Two" );

print dump $dummy;
