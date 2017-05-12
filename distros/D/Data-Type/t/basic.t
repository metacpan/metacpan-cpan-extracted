use Test;
BEGIN { plan tests => 7; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use Error qw(:try);
use IO::Extended qw(:all);

	try
	{
		verify( '1' , DEFINED() );

			# NUM

		verify( '0' , NUM( 20 ) );

		verify( '234' , NUM( 20 ) );

			# BOOL

		verify( '1' , BOOL( 'true' ) );

			# INT

		verify( '100' , INT );

			# REAL

		verify( '1.1' , REAL );

			# GENDER

		verify( 'male' , GENDER );

			# REF

		my $bla = 'blalbl';
			
		verify( bless( \$bla, 'SomeThing' ) , REF );

		verify( bless( \$bla, 'SomeThing' ) , REF( qw(SomeThing) ) );

		verify( bless( \$bla, 'SomeThing' ) , REF( qw(SomeThing Else) ) );

		verify( [ 'bla' ] , REF( 'ARRAY' ) );

		verify( 'yes' , YESNO );

		verify( 'no' , YESNO );

		verify( "yes\n" , YESNO );

		verify( "no\n" , YESNO );

		verify( '01001001110110101' , BINARY );

		verify( '0F 0C 0A' , HEX() );
		
		verify( '::ffff:192.168.0.1', IP( 'v6' ) );

		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
		
		use Data::Dumper;
		
		print Dumper shift;
	};

	# Date::Parse 2.23 example parse dates 
my $dates = <<ENDE;
1995:01:24T09:08:17.1823213
1995-01-24T09:08:17.1823213
Wed, 16 Jun 94 07:29:35 CST
Thu, 13 Oct 94 10:13:13 -0700
Wed, 9 Nov 1994 09:50:32 -0500 (EST)
21 dec 17:05
21-dec 17:05
21/dec 17:05
21/dec/93 17:05
1999 10:02:18 "GMT"
16 Nov 94 22:28:20 PST
ENDE

	my @dates = split /\n/, $dates;

	try
	{
		verify( $_, DATE( 'DATEPARSE' ) ) for @dates;
		
		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
		
		use Data::Dumper;
		
		print Dumper shift;
	};

	try
	{			
		my $bla = 'blalbl';

		verify( bless( \$bla, 'SomeThing' ) , REF( 'Never' ) );

		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		verify( 'bla' , REF );
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		verify( 'aaa01001001110110101' , BINARY );
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		verify( 'gg0F 0C 0A' , HEX );
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};

	try
	{
		verify( '192.168.0.1', IP( 'v6' ) );
		
		ok(0);
	}
	catch Type::Exception with
	{
		ok(1);
	};
