use Test::More qw(no_plan);

use strict;

use warnings;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

use Class::Maker qw(class);

BEGIN
  {
	$Class::Maker::explicit = 1;
  }

ok(1); # If we made it this far, we're ok.

#########################

package AlphaOne;

	Class::Maker::class
	{
		version => '0.01',

		public =>
		{
			string => [qw( email lastlog registered )],
		},

		  default => 
		    {
			lastlog => 'NULL',

		        registered => 'NULL',
		    },
	};


package AlphaTwo;

	Class::Maker::class
	{
		version => '0.01',
	
	isa => [qw( AlphaOne )],

		public =>
		{
			string => [qw( telephone )],
		},

		  default => 
		    {
		        lastlog => 'active',

			telephone => '00110033',
		    },
	};

package main;

	ln "# We have something to dump\n";

	$Class::Maker::Reflection::DEEP = 1;
	

#$Class::Maker::DEBUG = 1;


ln dump my $ao = AlphaOne->new();
ln dump my $at = AlphaTwo->new();

ok( $at->lastlog eq 'active' );
ok( $at->registered eq 'NULL' );
ok( $at->telephone eq '00110033' );
