BEGIN
{
	$| = 1;
	
	use Test::More;

	plan tests => 3 + 1; 

	use_ok( 'Class::Maker', qw(class) );
	use_ok( 'Class::Maker::Exception', qw(:try) );
	use_ok( 'Data::Dumper' );
}

use strict; use warnings;

#######

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

ok(1);

