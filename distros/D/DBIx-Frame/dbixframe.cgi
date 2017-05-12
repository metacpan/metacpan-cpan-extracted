#!/usr/local/bin/perl -Tw
use vars qw( $DBHOST $DBTYPE $DATABASE $DBUSER $DBPASS $DEBUG $CLASS $DB $HTML 
             $OPTIONS $TITLE @ACTIONS $HTMLHEAD $HTMLFOOT $HTMLBODY $VERSION 
	     $ROOTCLASS $STYLESHEET );
$VERSION = "1.5"; 	

=head1 NAME

dbixframe.cgi - Administer a DBIx::Frame database

=head1 SYNOPSIS

Unfortunately, no URL is available for public use.  You can see the man
pages for DBIx::Frame::CGI for some details, otherwise you probably just
want to try it out.

=head1 DESCRIPTION

dbixframe.cgi is a basic script, meant to be customized to administer an
individual DBIx::Frame database.  Entries for all tables can be added,
deleted, or modified with this package.  

=head1 REQUIREMENTS

B<DBIx::Frame::CGI>, whatever database package you're using.

=head1 SEE ALSO

B<DBIx::Frame::CGI>

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@ks.uiuc.edu>.

=head1 HOMEPAGE

B<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/>

=head1 LICENSE

This code is distributed under the University of Illinois Open Source
License.  See
C<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/license.html>
for details.

=head1 COPYRIGHT

Copyright 2000-2004 by the University of Illinois Board of Trustees and
Tim Skirvin <tskirvin@ks.uiuc.edu>.

=cut

###############################################################################
### Configuration + Private Data ##############################################
###############################################################################

## Load shared configurations and/or private data using 'do' commands, as
## seen below.  Note that several 'do's can be run if necessary.  

# do '/FULL/PATH/TO/CODE/TO/RUN';	

## This is the perl class that you will be using in this script.  

$CLASS   = "";				# Database class

## This is the root class of the above class.  Essentially a hack to let
## there be multiple modules using the same database.

$ROOTCLASS = $CLASS;               	# Class of the database class

## Modify and uncomment this to use user code instead of just system-wide 
## modules.  Note that this path must be set up as a standard Perl tree;
## I'd personally recommend just installing things system-wide unless you're
## a developer.

# use lib '/PATH/TO/USER/CODE';

## Document title - set this as appropriate.

$TITLE   = "DBIx::Frame Adminstration - Generic";		

## Set these options to modify the behaviour of the HTML creation code.

$OPTIONS = { 					
	'admin'    => 1, 	# Offer 'edit' and 'delete' functions?
	'nodetail' => 1, 	# Don't offer 'view'?
	'nomenu'   => 0,	# Don't include the bottom menu?
	'nocount'  => 0,	# Don't use 'next 25 entries' buttons
	'count'    => 25,	# How many entries should we offer at a time?
	'useropts' => [],	# User options to use in 'list' menu
	   };

## Database Information
## You may want to set these with a common config file, using 'do FILE'.
## Also, defaults may already be set within the class; only set these if
## you want to override the defaults.

# $DBHOST   = "";		# System that hosts the database
# $DBTYPE   = "";		# The type of database that we're working on
# $DATABASE = "";		# Name of the database we're connecting to
# $DBUSER   = "";		# Username to connect to the database
# $DBPASS   = "";		# Password to connect to the database

## This variable records how much debugging information you want in the
## HTML footers.  It works similarly to Unix permissions, by OR-ing the 
## appropriate options:
## 
##    	1	Print SQL queries
##   	2	Print CGI parameters
##      4	Print environment variables
##
## ie, '6' would print CGI and environment variables, and '5' would print 
## environment variables and SQL queries.  '0' will print nothing.

$DEBUG   = 0;					

## Modify this to change what default actions are available to manipulate
##  the available databases - choose from 'list', 'create', and 'search'

@ACTIONS = qw( create list search );
				
## These are references to code that will output the headers, body, and 
## footers for the messages.  If you want to change these, you can either 
## modify the code (which is below) or create a new set of functions and 
## change the below code references appropriately.

$HTMLHEAD = \&html_head;
$HTMLFOOT = \&html_foot;
$HTMLBODY = \&html_body; 

## Do we want to use a specific stylesheet?  This position is relative to
## wherever the script is being run.

$STYLESHEET = "stylesheet.css";

###############################################################################
### main() ####################################################################
###############################################################################

use CGI;
use DBIx::Frame::CGI;
use strict;

# Load the appropriate class module
{ local $@; eval "use $CLASS";  die "$@\n" if $@; }

$0 =~ s%.*/%%g;		# Lose the annoying path information
my $cgi = new CGI || die "Couldn't open CGI";
$DB = $ROOTCLASS->connect( $DATABASE, $DBUSER, $DBPASS, $DBHOST, $DBTYPE )
	or Error("Couldn't connect to $DBHOST: $DBI::errstr\n");
my $error = $DBI::errstr;	# Avoid a warning, otherwise unnecessary

my $params = {};
foreach ($cgi->param) { $$params{$_} = $cgi->param($_); }

if (scalar @ACTIONS) { @DBIx::Frame::ACTIONS = @ACTIONS }

( print $cgi->header(), &$HTMLHEAD($TITLE, 
			-style => {-src=>$STYLESHEET}), "\n" ) && $HTML++;
print &$HTMLBODY($DB, $params) || Error("There was an error in this script");
print &$HTMLFOOT($DEBUG);
exit(0);

###############################################################################
### Subroutines ###############################################################
###############################################################################

## Error ( PROBLEM [, PROBLEM [...]] )
# Prints an error message based on PROBLEM and exits.

sub Error {
  print CGI->header(), &$HTMLHEAD("Error in '$0'", 
		-style => {-src=>$STYLESHEET}) unless $HTML;

  print "This script failed for the following reasons: <p>\n<ul>\n";
  foreach (@_) { next unless $_; print "<li>", canon($_), "<br>\n"; }
  print "</ul>\n";

  print &$HTMLFOOT($DEBUG);
  exit 0;
}

## canon ( ITEM )
# Returns a printable version of whatever it's passed.  Used by Error().

sub canon {
  my $item = shift;
  if    ( ref($item) eq "ARRAY" )   { join(' ', @$item) }
  elsif ( ref($item) eq "HASH" )    { join(' ', %$item) }
  elsif ( ref($item) eq "" )        { $item }
  else                              { $item }
}

## html_head ( TITLE [, OPTIONS] )
# Prints off a basic HTML header, with debugging information.  Extra
# options are passed through to start_html.

sub html_head { 
  my $title = shift || $TITLE || "";
  use CGI;   my $cgi = new CGI;
  $cgi->start_html( -title => $title, @_ );
}

## html_body ( DB, PARAMS [, OPTIONS] )
# Prints off the HTML body.
sub html_body {
  my ($DB, $params, $options) = @_;
  return "" unless ref $params;
  $DB->make_html( $$params{'table'} || "", $$params{'action'} || "", 
  		  $params, $options || $OPTIONS );
}

## html_foot ( DEBUG [, OPTIONS] )
# Prints off a basic HTML footer, with debugging information.

sub html_foot { 
  my $debug = shift || $DEBUG;
  use CGI;   my $cgi = new CGI;
  my @return = debuginfo($debug);
  push @return, $cgi->end_html(@_);
  join("\n", @return, "");
}

## debuginfo ( LEVEL ) 
# Takes care of printing debugging information, as described above

sub debuginfo {
  my $debug = shift || 0;

  my @return;
  if ($debug) { 
    push @return, "<hr />", "<h2> Debugging Information </h2>";

    if ($debug & 1) {
      push @return, "SQL Queries: <p>\n<ul>";
      foreach ($DB->queries) { push @return, " <li>$_" }
      push @return, "</ul>";
    }

    if ($debug & 2) {
      push @return,  "Parameters: <p>\n<ul>\n";
      foreach ($cgi->param) { push @return,  " <li>$_: ", $cgi->param($_); }
      push @return,  "</ul>";
    }

    if ($debug & 4) {
      push @return,  "Environment Variables: <p>\n<ul>";
      foreach (sort keys %ENV) { push @return, " <li>$_: $ENV{$_}"; }
      push @return,  "</ul>";
    }
    push @return, "<hr />";
  }

  wantarray ? @return : join("\n", @return);
}

###############################################################################
### Version History ###########################################################
###############################################################################
# v1.0a 	Thu Jul 12 14:06:12 CDT 2001
### Release candidate.  Internal documentation written, it seems modular.
# v1.1 		Fri Apr  5 09:24:12 CST 2002
### Separated out html_body() as well as html_head() and html_foot().  This
### should let everything be modular except the sub-functions and the
### configuration.
# v1.2 		Fri Oct 11 10:29:52 CDT 2002
### Fixed a bug in Error() - didn't print the CGI->header() in there before.
# v1.3		Tue Oct 21 13:35:53 CDT 2003 
### Renamed DBI::Frame to DBIx::Frame, so updated everything accordingly.
# v1.4		Tue May 11 13:00:14 CDT 2004 
### Cleaned up with TCB::System.
# v1.5		Mon May 17 14:00:19 CDT 2004 
### Forked from DBIx::Frame into TCB::Publications; later forked back into
### DBIx::Frame.  Generally, documentation was added.
