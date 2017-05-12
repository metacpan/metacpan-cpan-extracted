#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib"; # include project lib
use DBI();
use CGI::OptimalQuery::SaveSearchTool();

# connect to your database
$DEMO::dbh ||= DBI->connect("dbi:SQLite:dbname=db/dat.db","","", { RaiseError => 1, PrintError => 1 });


CGI::OptimalQuery::SaveSearchTool::execute_saved_search_alerts(
  # default is shown
  # error_handler => sub { print STDERR @_; },

  # if debug is true, no email is sent, emails will be logged to the error_handler
  debug => 1,

  # database handle
  dbh => $DEMO::dbh,

  base_url => "http://x.sr.unh.edu/OptimalQueryDemo",

  email_from => 'noreply@sr.unh.edu',

  # define a handler which is called for each possible alert
  # alerts aren't actually sent until the very end where they are batched
  # and one email is sent for each email address containing one or more alerts
  handler => sub {
    # $o contains all the fields defined in the oq_saved_search rec
    my ($o) = @_;

    # you must set the email address for the search search owner id: $$o{USER_ID} 
    $$o{email_to} = 'pmc2@sr.unh.edu';

    # configure your application ENV
    # local $APP::q = new CGI();
    # local $APP::usr_id = $$o{USER_ID};
    # local %APP::data = ();

    # helper function to execute a perl module handler (will dynamically load module string and execute handler function)
    #if ($$o{URI} =~ /(\w+)\.pm$/) {
    #  CGI::OptimalQuery::SaveSearchTool::execute_handler("App::Applet::$1");
    #}
      
    # helper function to execute a perl script (will auto compile and cache a function)
    if ($$o{URI} =~ /(\w+\.pl)$/) {
      CGI::OptimalQuery::SaveSearchTool::execute_script("$Bin/cgi-bin/$1");
    }
  }
);
