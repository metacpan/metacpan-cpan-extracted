#!/usr/bin/perl

# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };

use Data::Type qw(:all +DB +Bio +Perl +Perl6);

use Data::Type::Query;

use strict;

use warnings;

ok(1); # If we made it this far, we're ok.

#########################
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

	$Data::Type::debug = 0;

print "Supported languages are ", join( ', ', Data::Type::l18n_list() ), "\n";

print "Current language is '", Data::Type->current_locale, "'\n";

my $query = Data::Type::Query->new;

foreach my $what ( $query->tables )
{
    print "\n\n$what\n";

    my $sth = $query->dbh->prepare( "SELECT * FROM $what" ) || die "$DBI::err";
    
    $sth->execute or die "$DBI::errstr";
    
    while( my $href = $sth->fetchrow_hashref )
    {
	#print Data::Dumper->Dump( [ $href  ] );
    }
}

#	print catalog(), "\n", toc();

print "\n\nLISTING ALL DEPENDENCIES:\n\n";

print Data::Dumper->Dump( [ Data::Type::Query->depends() ] );

   {
       local $Error::Depth += 2;

       $Error::Debug = 1;

    	try
    	{
	    valid( 'on e two three', DB::VARCHAR( 20 ) );

	    valid( 'on e two three', Data::Type::Facet::match( qw/one/ ) );
    	}
    	catch Error with
    	{
    		return;

    		my $e = shift;

    		print "-" x 100, "\n";

    		Data::Type::printfln "Exception '%s' caught", ref $e;

    		Data::Type::printfln "Expected '%s' %s at %s line %s", $e->value, $e->type->info, $e->file, $e->line;
    	};
   }

   {
       $Error::Debug = 1;

    	try
    	{
    		valid( 'test|test.de', STD::EMAIL );
    	}
    	catch Error with
    	{
           print "stacktrace: ", $_[0]->stacktrace, "\n";

    		print Data::Dumper->Dump( [ \@_ ] );

    		return;
    	};

       $Error::Debug = 0;
   }


	$Data::Type::debug = 0;

	Data::Type::println "=" x 100;

	foreach my $type ( STD::URI, STD::EMAIL, STD::IP( 'V4' ), DB::VARCHAR(80), STD::YESNO, STD::DOMAIN )
	{
		Data::Type::println "\n" x 2, "Describing ", $type->info;

		foreach my $entry ( Data::Type::summary( '', $type ) )
		{
			Data::Type::printfln "\texpecting it %s %s ", $entry->expected ? 'is' : 'is NOT', Data::Type::strlimit( $entry->object->info() );
		}
	}

	Data::Type::println "Now summary for DOMAIN given C<www.test.com>";
	
	foreach my $entry ( Data::Type::summary( 'www.test.com', STD::DOMAIN ) )
	{
		Data::Type::printfln "\texpecting it %s %s ", $entry->expected ? 'is' : 'is NOT', Data::Type::strlimit( $entry->object->info() );
	}

	print "\n", STD::CREDITCARD()->usage, "\n";

	print "\n", STD::YESNO::DE()->info, "\n";

print join( "\n", STD::ZIP()->info, STD::ZIP()->usage, STD::ZIP()->doc ), "\n";

# Test whether pkgname is sufficient for summary()
	Data::Type::println "Now summary via pkg for Data::Type::Object::bio_codon";

        my $type = 'Data::Type::Object::bio_codon';

	Data::Type::println "\n" x 2, "Describing ", $type->info;

	foreach my $entry ( Data::Type::summary( '', $type ) )
        {
	    Data::Type::printfln "\texpecting it %s %s ", $entry->expected ? 'is' : 'is NOT', Data::Type::strlimit( $entry->object->info() );
	  }


	Data::Type::println "TESTING TYPS";

#$Data::Type::debug = 1;

dvalid "bbbbbbb", BIO::DNA or warn "no dna";

print Data::Dumper->Dump( [ \@Data::Type::err ] );

dvalid "ACTTTTT", BIO::DNA and warn "dna detected";

$_ = "XXXKKKKLLLL";

warn "ALIENS DETECETD" unless is BIO::DNA;

is BIO::DNA or warn "not DNA";

	# Thanks to sudoer(at)users.sf.net for this test

	try 
        { 
	    valid('mike_web.oakley.com', STD::EMAIL);
		
	    warn "Problem make_web.oakley.com is valid ??????";  
	} 
        catch Error with  
        { 
 	     warn "correct warning about make_web.oakley.com";  

             print STDERR Data::Dumper->Dump( [ \@_ ] );
        };

package Bob;

	Data::Type::try { Data::Type::valid('mike_web.oakley.com', STD::EMAIL ) } catch Error Data::Type::with { print STDERR Data::Dumper->Dump( [ \@_ ] ) };

__END__
