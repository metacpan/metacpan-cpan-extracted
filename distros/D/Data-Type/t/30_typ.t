use Test;
BEGIN { plan tests => 14 }

use strict;

use Data::Type qw(:all +DB);
use Data::Type::Tied qw(:all);

use Data::Dumper;

	Data::Type::println "# Testing tie to Data::Type::Tied\n";

	$Data::Type::Tied::behaviour->{warnings} = 0;
	
	try
	{
		typ STD::EMAIL, \( my $email, my $email1 );

		my $cp = $email = 'murat.uenalan@gmx.de';
		
		untyp \$email;

		ok(1);
	}
	catch Data::Type::Exception with
	{
		print Dumper \@_ and ok(0);;		
	};

	try
	{
		typ STD::EMAIL, \( my $email, my $email1 );

		$email = 'fakeemail%anywhere.de';	# Error
		
		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ STD::URI, \( my $uri );

		$uri = 'http://test.de';

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		typ STD::URI, \( my $uri );

		$uri = 'xxx://test.de';	# Error

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};
		
	try
	{
		typ DB::VARCHAR(10), \( my $var );

		$var = join '', (0..9);

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		typ DB::VARCHAR(10), \( my $var );

		$var = join '', (0..10); # Error

		print "# Hmmm a ".length($var)." sized string should not pass VARCHAR(10)\n";

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ STD::IP( 'V4' ), \( my $ip );

		$ip = '255.255.255.0';

		$ip = '127.0.0.1';

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		typ STD::IP( 'V4' ), \( my $ip );

		$ip = '127.0.0.1.x'; # Error

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
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

		typ STD::IP( 'V4' ), \( $watched->addr );

		$watched->addr( '124.187.0.12' );

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		my $watched = Watched->new();

		typ STD::IP( 'V4' ), \( $watched->addr );

		$watched->addr( 'XxXxX' ); # Error

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};
	
	try
	{
		typ DB::ENUM( qw(Murat mo muri) ), \( my $alias );

		$alias = 'Murat';

		$alias = 'mo';

		$alias = 'muri';

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		typ DB::ENUM( qw(Murat mo muri) ), \( my $alias );

		$alias = 'idiot'; # Error ;)

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};

	try
	{
		typ DB::SET( qw(Murat mo muri) ), \( my $alias );

		$alias = [ qw(Murat mo)];

		ok(1);
	}
	catch Data::Type::Exception ::with
	{
		print Dumper \@_ and ok(0);;
	};

	try
	{
		typ DB::SET( qw(Murat mo muri) ), \( my $alias );

		$alias = [ 'john' ]; # Error ;)

		print Dumper \@_ and ok(0);;
	}
	catch Data::Type::Exception ::with
	{
		ok(1);
	};

