use Test;
BEGIN { plan tests => 12; $| = 0 }

use strict; use warnings;

use Data::Type qw(:all);
use IO::Extended qw(:all);

	try
	{
		valid( '1' , STD::DEFINED() );

			# NUM

		valid( '0' , STD::NUM( 20 ) );

		valid( '234' , STD::NUM( 20 ) );

			# BOOL

		valid( '1' , STD::BOOL( 'true' ) );

			# INT

		valid( '100' , STD::INT );

			# REAL

		valid( '1.1' , STD::REAL );

			# GENDER

		valid( 'male' , STD::GENDER );

			# REF

		my $bla = 'blalbl';

		valid( bless( \$bla, 'SomeThing' ) , STD::REF );

		valid( bless( \$bla, 'SomeThing' ) , STD::REF( qw(SomeThing) ) );

		valid( bless( \$bla, 'SomeThing' ) , STD::REF( qw(SomeThing Else) ) );

		valid( [ 'bla' ] , STD::REF( 'ARRAY' ) );

		valid( 'yes' , STD::YESNO );

		valid( 'no' , STD::YESNO );

		valid( "yes\n" , STD::YESNO );

		valid( "no\n" , STD::YESNO );

		valid( '01001001110110101' , STD::BINARY );

		valid( '0F 0C 0A' , STD::HEX() );

		valid( '::ffff:192.168.0.1', STD::IP( 'v6' ) );

		valid( 'Type.pm', STD::POD );

		ok(1);
	}
	catch Data::Type::Exception with
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
		valid( $_, STD::DATE ) and print "# tested DATE against $_\n" for @dates;

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);

		use Data::Dumper;

		print Dumper shift;
	};

	try
	{
		my $bla = 'blalbl';

		valid( bless( \$bla, 'SomeThing' ) , STD::REF( 'Never' ) );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( 'bla' , STD::REF );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( 'aaa01001001110110101' , STD::BINARY );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( 'gg0F 0C 0A' , STD::HEX );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( '192.168.0.1', STD::IP( 'v6' ) );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	ok( dvalid( 'cn=John Doe, o=Acme Inc., c=US', STD::X500::DN ) );

	ok( not dvalid( 'xxx', STD::X500::DN ) );

	ok( dvalid( '0F 0C 0A' , STD::HEX ) );

	ok( not dvalid( 'gg0F 0C 0A' , STD::HEX ) );

	ok( not dvalid( 'MANIFEST', STD::POD ) );
