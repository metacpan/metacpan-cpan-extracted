#!/usr/bin/perl -w
#
# @(#)$Id: x12cgi_noform.pl,v 100.1 2002/02/08 22:50:15 jleffler Exp $
#
# Simple example CGI script using DBI and DBD::Informix
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

# load standard Perl modules
use strict;
use DBI;
use Apache;

# check whether the script is running with mod_perl
if ( exists( $ENV{ 'MOD_PERL' } ) ) {
	# use the CGI class for mod_perl
	use CGI::Apache;
}
else {
	# use the generic CGI class
	use CGI;
}

use CGI::Carp;

# Run the rest of the script in a block so there are no globals.
# Globals are shared across scripts in mod_perl.
{

	# the environment variables were set in the Apache configuration
	# file rather than here

	# instantiate a CGI object
	my $query = undef;
	if ( exists( $ENV{MOD_PERL} ) ) {
		# instantiate a CGI object for mod_perl
		$query = new CGI::Apache;
	}
	else {
		# instantiate a generic CGI object
		$query = new CGI;
	}

	#  output the http header and html heading
	print
		$query->header(),
		$query->start_html( { '-title'=>'Customer Report' } );

	# connect to the database, instantiating a database handler
	# and activating an automatic exit and notification on errors
	my $dbh=DBI->connect('dbi:Informix:stores', '', '',
		{ 'PrintError'=>1, 'RaiseError'=>1 }
	) or die "Could not connect, stopped\n";

	# prepare the select statement
	my $st_text = 'SELECT * FROM customer';
	my $sth = $dbh->prepare( $st_text ) or
			die "Could not prepare $st_text; stopped";

	# open the cursor
	$sth->execute() or die "Failed to open cursor for SELECT statment\n";

	# bind columns to variables
	my (
		$customer_num, $fname, $lname, $company,
		$address1, $address2, $city, $state, $zipcode, $phone
	);
    my @cols = ( \$customer_num, \$fname, \$lname, \$company,
		\$address1, \$address2, \$city, \$state, \$zipcode, \$phone );
	$sth->bind_columns(undef, @cols);

	# chop blanks from char columns
	$sth->{ ChopBlanks } = 1;

	# Start a table with a row of table header rows.
	# Encode the <table> tag manually rather than calling
	# $query->table() to avoid printing the entire table at once
	print
		$query->h1( 'Customer Report' ),
		"\n<TABLE>\n",
		$query->TR( { '-valign'=>'top' }, 
			$query->th( { '-align'=>'left' }, [
				'Number',
				'Last Name',
				'First Name',
				'Company'
			] ),
			$query->th( { '-align'=>'left', '-colspan'=>'2' },
				'Address'
			),
			$query->th( { '-align'=>'left' }, [
				'City',
				'State',
				'Zipcode',
				'Phone'
			] )
		);

	# fetch records from the database
	while ( $sth->fetch() ) {
		# Convert NULLS into non-breaking spaces (Perl-ish aka obscure!)
		map { $$_ = "&nbsp;" unless defined $$_ } @cols;
		# print values as table cells
		print
			$query->TR( { '-valign'=>'top' },
				$query->td( [
					$customer_num,
					$lname,
					$fname,
					$company,
					$address1,
					$address2,
					$city,
					$state,
					$zipcode,
					$phone
				] )
			);
	}

	# close the table
	print "\n</TABLE>\n";

	# This free statement is not strictly necessary in DBD::Informix
	# 0.60 as cursors are auto-finished when the last row is fetched.
	# It is needed in earlier versions; it does no damage in later ones.
	$sth->finish();

	# disconnect from the server
	$dbh->disconnect();

	# finish the html page
	print $query->end_html();

}

1; # notify Perl that the script loaded successfully
