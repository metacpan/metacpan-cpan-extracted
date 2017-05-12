# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };

use Data::Type qw(:all);

use Error qw(:try);

use strict;

use warnings;

ok(1); # If we made it this far, we're ok.

#########################
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

	$Data::Type::DEBUG = 1;

	print toc();

	#Data::Type::println VARCHAR( 20 )->to_text;

	try
	{
		verify( 'one two three', Type::Proxy::VARCHAR( 20 ), Facet::Proxy::match( qw/one/ ) );
	}
	catch Type::Exception with
	{
		my $e = shift;

		print "-" x 100, "\n";

		Data::Type::printfln "Exception '%s' caught", ref $e;

		Data::Type::printfln "Expected '%s' %s at %s line %s", $e->value, $e->type->info, $e->was_file, $e->was_line;
	};

	$Data::Type::DEBUG = 0;

	Data::Type::println "=" x 100;

	foreach my $type ( URI, EMAIL, IP( 'V4' ), VARCHAR(80), YESNO )
	{
		Data::Type::println "\n" x 2, "Describing ", $type->info;

		foreach my $entry ( Data::Type::testplan( $type ) )
		{
			Data::Type::printfln "\texpecting it %s %s ", $entry->[1] ? 'is' : 'is NOT', Data::Type::strlimit( $entry->[0]->info() );
		}
	}

	print "\n", CREDITCARD()->usage, "\n";

	print "\n", DK::YESNO()->info, "\n";	
