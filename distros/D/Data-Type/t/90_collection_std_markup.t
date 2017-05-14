use Test;
BEGIN { plan tests => 7; $| = 0 }

use strict; use warnings;

use Data::Dumper;
use Data::Type qw(:all);

   my $markup;

	try
	{
		valid( '<foo id="me">Hello World</foo>', STD::XML() );

		ok(1);
	}
	catch Data::Type::Exception with
	{
		ok(0);

		print Dumper shift;
	};

$markup = <<ENDE;
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="grouping.xslt"?>
<PROJECTS>
	<PROROW>
		<id>1</id>
		<name>Customer 1</name>
		<project_name>Project 1</project_name>
	</PROROW>
	<PROROW>
		<id>2</id>
		<name>Customer 1</name>
		<project_name>Project 2</project_name>
	</PROROW>
	<PROROW>
		<id>3</id>
		<name>Customer 2</name>
		<project_name>Project 1</project_name>
	</PROROW>
</PROJECTS>
ENDE

	try
	{
		valid( 'aaa01001001110110101' , STD::XML() );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

	try
	{
		valid( '<bla>101<llll>' , STD::XML() );

		ok(0);
	}
	catch Data::Type::Exception with
	{
		ok(1);
	};

   print "# STD::HTML\n";

my @ok_chunks =
(
	'<p>fine chunk</p>',
);

my @nok_chunks =
(
	'<pr>bad chunk</p>',
	'<prasd><<<>>bad chunk</p>', 
	<<'END_HERE',
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <P ALIGN=LEFT ALIGN=RIGHT>This is my paragraph</P>
    </BODY>
</HTML>
END_HERE

);
	foreach ( @ok_chunks )
	{
	    try
	    {
		valid( $_, STD::HTML( 'fluff', 'helper' ) );
		
		ok(1);
	    }
	    catch Data::Type::Exception with
	    {
		ok(0);
		
		print Dumper shift;
	    };
	}

	foreach ( @nok_chunks )
	{
	    try
	    {
		valid( $_, STD::HTML( 'fluff', 'helper' ) );
		
		ok(0);
	    }
	    catch Data::Type::Exception with
	    {
		ok(1);
		
		print Dumper shift;
	    };
	}

