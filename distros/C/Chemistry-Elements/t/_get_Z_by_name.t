#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_get_Z_by_name';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work
foreach my $name ( qw( Hydrogen Ydrogenhai ) )
	{
	my $Z =  _get_Z_by_name( $name );
	is( $Z, 1, "Z for $name is right" );
	}

foreach my $name ( qw( Oldgai Gold ) )
	{
	my $Z =  _get_Z_by_name( $name );
	is( $Z, 79, "Z for $name is right" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that shouldn't work
foreach my $name ( qw( Foo Bar Bax ), undef, 0, '',  )
	{
	no warnings 'uninitialized';
	my $Z =  _get_Z_by_name( $name );
	is( "$Z", "", "Z for $name is undefined" );
	}

