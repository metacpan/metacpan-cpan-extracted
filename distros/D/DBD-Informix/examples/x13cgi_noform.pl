#!/usr/bin/perl -w
#
# @(#)$Id: x13cgi_noform.pl,v 100.1 2002/02/08 22:50:16 jleffler Exp $
#
# Slightly more sophisticated post-processing example CGI script
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
	my $st_text = 'SELECT * FROM Customer ORDER BY Lname, Fname, Company, Customer_num';
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
		$query->h1({ align=>'center' }, 'Customer Report' ),
		"\n<TABLE>\n",
		$query->TR( { '-valign'=>'top' }, 
			$query->th( { '-align'=>'left' }, [
				'Name',
				'Company',
				'Address',
				'Phone'
			] )
		);

	# fetch records from the database
	while ( $sth->fetch() ) {
		# Convert NULLS into empty strings (Perl-ish aka obscure!)
		map { $$_ = "" unless defined $$_ } @cols;
		my ($name) = "$lname, $fname";
		my ($addr) = "$address1" . (($address2 eq "") ? "" : ", $address2") .
						", $city $state $zipcode";
		# print values as table cells
		print
			$query->TR( { '-valign'=>'top' },
				$query->td( [
					$name,
					$company,
					$addr,
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

	print "\n<HR>\n";

	sub ordinal
	{
		my($val) = @_;
		my($lst) = $val % 10;
		my(@suffix) = ("th", "st", "nd", "rd");
		$lst = 0 if ($lst > 3 || ($val % 100 >= 11 && $val % 100 <= 13));
		return "${val}$suffix[$lst]";
	}

	my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	$year += 1900;
	my $month = (qw(January February March April May June July August September October November December))[$mon];
	my $weekday = (qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday))[$wday];
	my $daynum = ordinal($day);
	print CGI::center("Data extracted at: $weekday, $daynum $month $year at $hour:$min:$sec UTC\n");

	print "\n<HR>\n";

	# finish the html page
	print $query->end_html();

}

1; # notify Perl that the script loaded successfully
