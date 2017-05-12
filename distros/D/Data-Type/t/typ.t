use Test;
BEGIN { plan tests => 14 }

use strict;
use Data::Type qw(:all);
use Error qw(:try);

	Data::Type::println "# Testing tie to Data::Type::Typed\n";

	$Data::Type::Typed::BEHAVIOUR->{warnings} = 0;
	
	try
	{
		typ EMAIL, \( my $email, my $email1 );

		my $cp = $email = 'murat.uenalan@gmx.de';
		
		untyp \$email;

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ EMAIL, \( my $email, my $email1 );

		$email = 'fakeemail%anywhere.de';	# Error
		
		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ URI, \( my $uri );

		$uri = 'http://test.de';

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ URI, \( my $uri );

		$uri = 'xxx://test.de';	# Error

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};
		
	try
	{
		typ VARCHAR(10), \( my $var );

		$var = join '', (0..9);

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ VARCHAR(10), \( my $var );

		$var = join '', (0..10); # Error

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ IP( 'V4' ), \( my $ip );

		$ip = '255.255.255.0';

		$ip = '127.0.0.1';

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ IP( 'V4' ), \( my $ip );

		$ip = '127.0.0.1.x'; # Error

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};

Class::Maker::class 'Watched',
{
	public =>
	{
		ipaddr => [qw( addr )],
	}
};

	try
	{
		my $watched = Watched->new();

		typ IP( 'V4' ), \( $watched->addr );

		$watched->addr( '124.187.0.12' );

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		my $watched = Watched->new();

		typ IP( 'V4' ), \( $watched->addr );

		$watched->addr( 'XxXxX' ); # Error

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};
	
	sub MYSQL::SET  { SET( @_ ) }

	sub MYSQL::ENUM { ENUM( @_ ) }

	try
	{
		typ MYSQL::ENUM( qw(Murat mo muri) ), \( my $alias );

		$alias = 'Murat';

		$alias = 'mo';

		$alias = 'muri';

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ MYSQL::ENUM( qw(Murat mo muri) ), \( my $alias );

		$alias = 'idiot'; # Error ;)

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ MYSQL::SET( qw(Murat mo muri) ), \( my $alias );

		$alias = [ qw(Murat mo)];

		ok(1);
	}
	catch Type::Exception ::with
	{
		ok(0);
	};

	try
	{
		typ MYSQL::SET( qw(Murat mo muri) ), \( my $alias );

		$alias = [ 'john' ]; # Error ;)

		ok(0);
	}
	catch Type::Exception ::with
	{
		ok(1);
	};

