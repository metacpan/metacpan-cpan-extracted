##############################################################################
# DBI web interface                      Version 0.20                        #
# Copyright 1999-2000 James Furness      furn@base6.com                      #
# Created 01/05/99                       Last Modified 13/05/00              #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1999-2000 James Furness <furn@base6.com>. All Rights Reserved.   #
#                                                                            #
# This module is free software; it may be used freely and redistributed      #
# for free providing this copyright header remains part of the module. You   #
# may not charge for the redistribution of this module. Selling this code    #
# without James Furness' written permission is expressly forbidden.          #
#                                                                            #
# This module may not be modified without first notifying James Furness      #
# <furn@base6.com> (This is to enable me to track modifications). In all     #
# cases this copyright header should remain fully intact in all              #
# modifications.                                                             #
#                                                                            #
# This code is provided on an "As Is" basis, without warranty, expressed or  #
# implied. The author disclaims all warranties with regard to this software, #
# including all implied warranties of merchantability and fitness, in no     #
# event shall the author, James Furness be liable for any special, indirect  #
# or consequential damages or any damages whatsoever including but not       #
# limited to loss of use, data or profits. By using this module you agree to #
# indemnify James Furness from any liability that might arise from it's use. #
# Should this code prove defective, you assume the cost of any and all       #
# necessary repairs, servicing, correction and any other costs arising       #
# directly or indrectly from it's use.                                       #
#                                                                            #
# This copyright notice must remain fully intact at all times.               #
# Use of this program or its output constitutes acceptance of these terms.   #
#                                                                            #
# Parts of this module are based upon mysql-lib.pl by Ron Crisco.            #
##############################################################################

package DBIx::glueHTML;

=pod

=head1 NAME

DBIx::glueHTML - Class for creating a CGI interface to a database

=head1 SYNOPSIS

 use CGI;
 use DBI;
 use DBIx::glueHTML;

 $cgi			= new CGI;
 $dbh			= DBI->connect("DBI:mysql:[DATABASE]:[HOSTNAME]","[USERNAME]","[PASSWORD]") );
 $DBinterface	= new DBIx::glueHTML ($cgi, $dbh, "[INFOTABLE NAME]");

 # Below here is only executed if a glueHTML action was not taken, so print a menu

 print $cgi->header;
 print "<A HREF=" . $cgi->url . "?glueHTML-table=[TABLENAME]&glueHTML-action=add>Add</A>\n<BR>";
 print "<A HREF=" . $cgi->url . "?glueHTML-table=[TABLENAME]&glueHTML-action=search>Search</A>\n";

=head1 DESCRIPTION

The C<DBIx::glueHTML> class allows a CGI interface to a database.
It enables a CGI interface to a database to be created, supporting record addition,
modification, deletion and searching. It provides a user friendly interface with
descriptions of fields provided. The field descriptions along with information on
whether the field is visible, hidden or excluded are extracted from a table, allowing
easy modification and addition of fields and tables without having to edit code.

=head2 Features

=over 4

=item Simple database administration

Forms are created automatically on demand, SQL statements are generated as needed and processed.
The module contains enough autonomy to potentially run with only wrapper perl code placed around
it.

=item Full form configuration

Forms can be modified to add descriptions and extra information to fields, making it easy to change 
output without having to edit code.

=item Control

Extensive callback procedures and configuration options allow output, password protection and logging 
to be configured as desired.

=item Full HTML customisation

HTML output and table formats can be customised easily by the user.

=back

=cut

$| = 1;	# Flush all buffers
require 5.004; # Require at least perl 5.004

use strict;
use vars qw($VERSION);
use CGI;
use DBI;

$VERSION = '0.20';

# ------------------------------------------------------------------------
# Class constructors/destructors
# ------------------------------------------------------------------------
=pod

=head1 METHODS

=head2 Main Methods

=over 4

=item B<$DBinterface = new DBIx::glueHTML (>I<CGI> I<DBI> I<Infotable Name> I<[Suppress paramcheck]>B<);>

Constructs a new C<DBIx::glueHTML> object. You must pass a reference
to a CGI object which will be used to get the script's parameters and a
database handle (Returned from a C<DBI-E<gt>connect> function) which will
be used to communicate with the database. The third parameter defines the
name of the I<info table> which is used to determine hidden/excluded fields,
field names and descriptions as described below in B<INFOTABLE FORMAT>. After 
initialisation, the CGI object is checked for a 'glueHTML-action' parameter. 
If this is present, control is taken from the script and the specified action 
is performed on the specified table. This parameter is set when an action which 
requires further processing is in progress.

The final parameter, suppress paramcheck, is optional and when set to 1 will 
cause the script NOT to perform the parameter check. You MUST then call the
check_params function in your code or forms will not work. Overriding 
the script in this way is not recommended unless necessary for error handler 
or security check handler setting.

=cut
sub new
{
    my $proto                   = shift;
    my $class                   = ref($proto) || $proto;
    my $cgipkg                  = shift;
    my $dbihdl                  = shift;
    my $infotbl                 = shift;
    my $suppresscheck           = shift || 0;

    my $self                    = bless {}, $class;

    $self->{CGI}                = $cgipkg;  # CGI package
    $self->{DBH}                = $dbihdl;  # DBI database handle
    $self->{ITABLE}             = $infotbl; # Info Table name
    $self->{ERRHDL}             = undef;    # Error handler
    $self->{LOGFILE}            = undef;    # Log file
    $self->{LOGCALLBACK}        = undef;    # Logging callback function
    $self->{PRINTHEADER}        = undef;    # HTML header
    $self->{STARTTABLE}         = undef;    # HTML format
    $self->{STARTTABLEROW}      = undef;    # HTML format
    $self->{PRINTTABLECELL}     = undef;    # HTML format
    $self->{PRINTTABLEHEADERCELL}= undef;   # HTML format
    $self->{PRINTENDTABLEROW}   = undef;    # HTML format
    $self->{PRINTEDITTABLEROW}  = undef;    # HTML format
    $self->{ENDTABLE}           = undef;    # HTML format
    $self->{PRINTFOOTER}        = undef;    # HTML footer
    $self->{PRINTCONTENTTYPE}   = 1;        # Print content type or let printheader() handle things
    $self->{USEGMTTIME}         = 1;        # Use GMT time or local time
    $self->{TIMEMOD}            = 0;        # Add or subtract time
    $self->{ACCESSCALLBACK}     = undef;    # Security check callback
    $self->{FORMFIELDCALLBACK}  = undef;    # Form field change/hide callback

    if ($suppresscheck != 1) {
        $self->check_params;
    }

    return $self;
}

sub DESTROY { }

##########################################################################
# ------------------------------------------------------------------------
# User-called functions
# ------------------------------------------------------------------------

=pod

=back

=head2 Optional Methods

Optional methods which can be called to directly jump to a script function, 
for example to directly initiate a delete or modify on a record.

=over 4

=cut

=item B<check_params> B<();>

  # Check form parameters
  $DBinterface->check_params;

Causes the glueHTML-action parameter to be rechecked. If it contains 
the value 'add','modify','delete' or 'search', the respective function 
will be called ('exec_add','exec_modify','exec_delete' or 'exec_search').
this function is essential to the correct functioning of the interfaces 
with two and three part forms, and is called automatically when a 
glueHTML object is created, unless the 'suppress paramcheck' parameter 
is set to 1.

=cut

sub check_params {
   my $self    = shift;

   if ($self->{CGI}->param("glueHTML-action") eq "add") {
      $self->exec_add;
      exit;
   } elsif ($self->{CGI}->param("glueHTML-action") eq "modify") {
      $self->exec_modify;
      exit;
   } elsif ($self->{CGI}->param("glueHTML-action") eq "delete") {
      $self->exec_delete;
      exit;
   } elsif ($self->{CGI}->param("glueHTML-action") eq "search") {
      $self->exec_search;
      exit;
  }
}

=item B<exec_search> B<();>

  # Now set the 'glueHTML-table' parameter so the script knows 
  # what table to deal with
  $cgi->param(-name=>'glueHTML-table',-value=>'mytable');

  # Now call the function 
  $DBinterface->exec_search;

Searches the table named in the CGI parameter 'glueHTML-table'. 
The user will be presented with a blank form with the fields of the table. 
They press submit to search the table (Wildcards can be used). They are then 
returned a table with a modify and delete button and the fields for each 
record found.

=cut

sub exec_search {
   my $self    = shift;
   my $table   = $self->{CGI}->param("glueHTML-table");
   my ($tablename, $name, $label, $lookup, $extrahash, $hidden, $exclude, 
                                    $additionalwhere) = $self->_getTableInfoHash($table);

   # Check access privs
   $self->_checkAccess;

   if ($self->{CGI}->param('post')) {
      my ($i, $j, %types, %params, $pri, $cursor, $sql, @row, $val, $numcols, 
                                 @fielddesc, @fieldtypes, @primary_keys, $content);
      
      $self->_printHeader("Search Results", "");
      
      $numcols = 0;
      
      # Now look up primary key fields and field types...
      my ($desc_cursor) = $self->_execSql ("describe $table");
      while (@fielddesc = $desc_cursor->fetchrow) {
         $numcols++;
         
         # Stuff the paramaters into a hash before we delete them
         $params{$fielddesc[0]} = $self->{CGI}->param($fielddesc[0]);
         $types{$fielddesc[0]} = $fielddesc[1];
         if ($fielddesc[3] eq "PRI") {
            push @primary_keys, $fielddesc[0];
         }
      }
      $desc_cursor->finish;
      $numcols += 2;	# Add Modify and Delete cols
      
      # now we execute the SQL, and return a list of matches
      $cursor = $self->_execSql($self->_selectSql($table, $additionalwhere));
      
      # delete the current params so they don't get incorporated in the forms
      $self->{CGI}->delete_all;
      $self->_startTable($numcols, "Search Results");
      
      # now print header row
      $self->_printStartTableRow();
      $self->_printTableHeaderCell("Modify");
      $self->_printTableHeaderCell("Delete");
      for ($i=0; $i < $cursor->{NUM_OF_FIELDS}; $i++) {
         $self->_printTableHeaderCell("$cursor->{NAME}->[$i]");
      }
      $self->_printEndTableRow();
      
      while (@row = $cursor->fetchrow_array) {
         $self->_printStartTableRow();
         
         # now print the Modify Form
         print $self->{CGI}->startform;
         $content = "";
         # Print the primary keys
         for ($i=0; $i < $cursor->{NUM_OF_FIELDS}; $i++) {
            foreach $pri (@primary_keys) {
               if ($pri eq $cursor->{NAME}->[$i]) {
                  print "<INPUT TYPE=\"hidden\" NAME=\"$cursor->{NAME}->[$i]\" VALUE=\"$row[$i]\">";
               }
            }
         }
         # Print state tracking elements
         print $self->{CGI}->hidden(-name => 'glueHTML-action', value => 'modify');
         print $self->{CGI}->hidden(-name => 'glueHTML-table', value => $table);
         $self->_printHidden; # Print any hidden elements necessary
         $self->_printTableCell ($self->{CGI}->submit('Modify'));
         print $self->{CGI}->endform;

         # now print the Delete Form
         print $self->{CGI}->startform;
         $content = "";
         # Print the primary keys
         for ($i=0; $i < $cursor->{NUM_OF_FIELDS}; $i++) {
             foreach $pri (@primary_keys) {
                 if ($pri eq $cursor->{NAME}->[$i]) {
                     print "<INPUT TYPE=\"hidden\" NAME=\"$cursor->{NAME}->[$i]\" VALUE=\"$row[$i]\">";
                 }
             }
         }
         # Print state tracking elements
         print $self->{CGI}->hidden(-name => 'glueHTML-action', value => 'delete');
         print $self->{CGI}->hidden(-name => 'glueHTML-table', value => $table);
         $self->_printHidden; # Print any hidden elements necessary
         $self->_printTableCell ($self->{CGI}->submit('Delete'));
         print $self->{CGI}->endform;

         # now print the fields
         for ($i=0; $i < $cursor->{NUM_OF_FIELDS}; $i++) {
            my $pos = 0;
            $val = $row[$i];
            $val =~ s/&/&amp;/g;
            $val =~ s/</&lt;/g;
            $val =~ s/>/&gt;/g;
            
            # Don't print the whole of the text fields
            if ($types{$cursor->{NAME}->[$i]} =~ "text") {
               my ($search) = "";
               
               if ($search = $params{$cursor->{NAME}->[$i]}) {
                  $search =~ s/&/&amp;/g;
                  $search =~ s/</&lt;/g;
                  $search =~ s/>/&gt;/g;
                  
                  # Make wildcards work in highlight
                  $search =~ s/_/(.)/g;
                  $search =~ s/%/(.*)/g;
                  
                  # This chunk borrowed from plan_search.pl by Richard Smith :p
                  
                  # Find our search string in the field
                  $pos = index(lc($val), lc($search));
                  
                  # Grab the string for 100 characters before it
                  $pos = $pos - 100;
                  if ($pos < 0) {
                     $pos = 0;
                  }
               }
               my ($subtext) = substr($val, $pos, 300);
               
               # Change the search string to bold in the part of the string we're showing
               if ($search ne "") { $subtext =~ s/($search)/<b>$1<\/b>/gi; }
               
               if (length($val) > 300) { # Show truncation marks if too long
                  if ($pos < 1) {
                     $val = $subtext . "...";
                  } else {
                     $val = "..." . $subtext . "...";
                  }
               } else {
                  $val = $subtext;
               }
            }
            $self->_printTableCell ("$val &nbsp;");
         }
         $self->_printEndTableRow();
      }
      $self->_endTable();
      $self->_printFooter;
      exit;
	} else {
      # give them the form
      $self->_form($table,"search","Search $tablename","Search $tablename","nodefaults","");
      exit;
	}
}

=item B<exec_modify> B<();>

  # Assume $cgi->param has been set to indicate the primary keys
  # for the table being modified, i.e 'Primary Key Name' = 'Primary
  # Key Value'

  # Now set the 'glueHTML-table' parameter so the script knows 
  # what table to deal with
  $cgi->param(-name=>'glueHTML-table',-value=>'mytable');

  # Now call the function 
  $DBinterface->exec_modify;

Modifies a record from the table named in the CGI parameter 'glueHTML-table' 
where the CGI parameters which have the same name as a table column. For example 
for a table called 'data' with an 'ID' column containing the primary keys for 
that table, set the 'glueHTML-table' parameter to 'data' and set the 'ID' 
parameter to the ID number of the record you want to modify. The user will then 
be presented with a form containing the data in the table for them to modify. 
They then press submit to commit the data

=cut
sub exec_modify {
   my $self    = shift;
   
   # Check access privs
   $self->_checkAccess;

   # Execute the modify if the user already has the form else give the user the form
   if ($self->{CGI}->param('post')) {
       $self->_modifyRecord($self->{CGI}->param("glueHTML-table"));
   } else {
       $self->_form($self->{CGI}->param("glueHTML-table"),"modify","Modify Record","Modify Record","","fill_from_table");
   }
}

=item B<exec_add> B<();>

  # Now set the 'glueHTML-table' parameter so the script knows 
  # what table to deal with
  $cgi->param(-name=>'glueHTML-table',-value=>'mytable');

  # Now call the function 
  $DBinterface->exec_add;

Adds a record to the table named in the CGI parameter 'glueHTML-table'. 
The user will be presented with a empty form containing just the defaults for 
the values of that table (Defined in the SQL). They then press submit to commit 
the data to the table.

=cut
sub exec_add {
   my $self    = shift;

   # Check access privs
   $self->_checkAccess;

   if ($self->{CGI}->param('post')) {
      $self->_insertRecord($self->{CGI}->param("glueHTML-table"));
   } else {
      $self->_form($self->{CGI}->param("glueHTML-table"),"add","Add Record","Add Record","","");
   }
}

=item B<exec_delete> B<();>

  # Assume $cgi->param has been set to indicate the primary keys
  # for the table being modified, i.e 'Primary Key Name' = 'Primary
  # Key Value'

  # Now set the 'glueHTML-table' parameter so the script knows 
  # what table to deal with
  $cgi->param(-name=>'glueHTML-table',-value=>'mytable');

  # Now call the function 
  $DBinterface->exec_delete;

Deletes a record from the table named in the CGI parameter 'glueHTML-table' 
where the CGI parameters which have the same name as a table column. For example 
for a table called 'data' with an 'ID' column containing the primary keys for 
that table, set the 'glueHTML-table' parameter to 'data' and set the 'ID' 
parameter to the ID number of the record you want to delete.

This function will output a confirmation page requiring users to confirm the delete 
or press their browser's back button to cancel. To skip confirmation, set the 'confirm'
parameter to 'Y'.

=cut
sub exec_delete {
   my $self    = shift;

   # Check access privs
   $self->_checkAccess;

   # Delete the record
   $self->_deleteRecord($self->{CGI}->param("glueHTML-table"));
}

# ------------------------------------------------------------------------
# General support functions
# ------------------------------------------------------------------------
=pod

=back

=head2 Optional Customisation Methods

Optional methods which can be called to alter the behaviour of the script
or enable features such as logging.

=over 4

=cut

=item B<set_logcallback> B<(>I<Callback function address>B<);>

  sub log_callback {
      my $description = shift;
      my $sql         = shift;

      open (LOG,">>$logfile")
      print LOG "$description (Executing $sql)";
      close(LOG);
  }
  $DBinterface = new DBIx::glueHTML ($cgi, $dbh, $table, 1);
  $DBinterface->set_logcallback(\&log_callback);
  $DBinterface->check_params();

Enables logging of SQL changes to the database via the user
defined routine. The first parameter passed is a description,
such as 'Record added to mytable' and the second parameter is
the SQL statement which was used.

NOTE: check_params() MUST be called or glueHTML will not function correctly.

=cut
sub set_logcallback {
#   $self                  &callback;
    $_[0]->{LOGCALLBACK} = $_[1];
}

=item B<set_logfile> B<(>I<Logfile name>B<);>
  $DBinterface = new DBIx::glueHTML ($cgi, $dbh, $table, 1);
  $DBinterface->set_logfile("/usr/local/logs/mydb-log");
  $DBinterface->check_params();

Enables logging of SQL changes to the database automatically
without providing a callback. The script will open the file
specified, with no locking (Althoughthis might be added in 
future). The file must be writeable to the CGI, on UNIX you 
normally need to I<chmod 666 mydb-log>. However this may 
differ depending on your system and what operating system 
you have.

NOTE: check_params() MUST be called or glueHTML will not function correctly.

=cut
sub set_logfile {
#   $self              $logfile;
    $_[0]->{LOGFILE} = $_[1];
}

# Internal function to log output if logging is enabled
sub _logEvent {
    my $self    = shift;
    my $cmd     = shift;
    my $sql     = shift;
    my $logfile = undef;

    # If we have a callback, use it
    if (defined $self->{LOGCALLBACK}) {
        &{$self->{LOGCALLBACK}} ($cmd, $sql);
        return;

    # Else output to a logfile ourselves
    } elsif (defined $self->{LOGFILE}) {
        $logfile = $self->{LOGFILE};

    # Else forget logging
    } else {
        return;

    }

    # Get and format the time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	if ($sec < 10) { $sec = "0$sec"; }
	if ($min < 10) { $min = "0$min"; }
	if ($hour < 10) { $hour = "0$hour"; }
	if ($mon < 10) { $mon = "0$mon"; }
	if ($mday < 10) { $mday = "0$mday"; }
    my (@months) = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    my ($cur_date) = "[" . $mday . "/" . $months[$mon] . "/" . $year . ":" . $hour . ":" . $min . ":" . $sec . " +0000]";

    # Open the logfile for append
	if (! open(LOG,">>$logfile")) {
        # Send warnings to the browser and STDERR on failure
        warn ("Unable to open logfile $logfile for append ($!)");
        print "<B>WARNING</B>: Unable to open logfile $logfile for append ($!)";
		return;
	}

    # Print to the logfile
    print LOG "$cur_date $cmd" . ($sql ne "" ? " SQL: '$sql'" : "") . "\n";

    # Close the logfile
    close (LOG);
}

=item B<set_errhandler> B<(>I<Error handler function address>B<);>

  sub errorhandler {
      my $errstr  = shift;

      print "<h1>Fatal Error</h1>";
      print $errstr;

      exit;
  }
  $DBinterface = new DBIx::glueHTML ($cgi, $dbh, $table, 1);
  $DBinterface->set_errorhandler(\&errorhandler);
  $DBinterface->check_params();

Transfers error handling in the script from the I<die()> procedure
to the subroutine passed as the argument. The errorhandling routine
should not return, and should terminate the program after the error
has been output.

NOTE: check_params() MUST be called or glueHTML will not function correctly.

=cut
sub set_errhandler {
#   $self             &errorhandler;
    $_[0]->{ERRHDL} = $_[1];
}

=item B<set_accesscallback> B<(>I<Callback function address>B<);>

  sub checkaccess {
      if ($cgi->param("password") eq "letmein") { # Example security check
         return; # Valid password - return to allow function to continue
      } else {
         die ("Incorrect password"); # Incorrect - die to stop execution
      }
  }
  $DBinterface = new DBIx::glueHTML ($cgi, $dbh, $table, 1);
  $DBinterface->set_accesscallback(\&checkaccess);
  $DBinterface->check_params();

Enables a security check function to approve or deny access. The function is 
called before changes to the database are made. The function should return to
allow an action to complete or die to terminate the program and prevent access.

NOTE: check_params() MUST be called or glueHTML will not function correctly.

=cut
sub set_accesscallback {
    my $self     = shift;
    my $callback = shift;

    $self->{ACCESSCALLBACK} = $callback;
}

# Internal function to call the user defined security check
sub _checkAccess {
    my $self     = shift;
    my $callback = $self->{ACCESSCALLBACK};

    if (ref($callback) eq 'CODE') {
    	&$callback(); # nicer to perl 5.003 users
    }
}

=item B<set_fieldvaluecallback> B<(>I<Callback function address>B<);>

  sub setfieldvalue {
      my $table  = shift; # Database table name
      my $mode   = shift; # "add"/"modify"/"search"
      my $field  = shift; # Field name
      my $value  = shift; # Field value in database or form
      my $default= shift; # Field default value

      # Additions to the News table
      if ($table eq "news" && $mode eq "add") {
          # If it's the UserID field
          if ($field eq "UserID") {
              # Hide the field and set it to the current user's ID
              return ($userID, 1);
          } 

      # Modifications to 
      } else if ($table eq "something" && $mode eq "modify") {
          # Something field
          if ($field eq "something") {
              # Do Something
          } else if () {
              # Do Something else
          }
      }

      # Etc....

      ($val, $forcehidden) = &{$self->{FORMFIELDCALLBACK}}($table, $mode, $field, $value, $default);

      # Default behaviour - CALLBACK MUST RETURN THIS FOR UNRECOGNISED TABLES/MODES
      return (undef, 0);
  }
  $DBinterface = new DBIx::glueHTML ($cgi, $dbh, $table, 1);
  $DBinterface->set_fieldvaluecallback(\&setfieldvalue);
  $DBinterface->check_params();

Enables the script to override data in any input form printed by the script. The 
callback is passed the database table, the mode (add/modify), the current value 
and the default value. The callback can then change the value of the field, and/or 
choose to force the field to be hidden. For example a user ID field can be defaulted
to the currently logged on user's ID and hidden to prevent changing.

The callback should return an array consisting of the value to be replaced or undef
if the value is not to be changed, and 1 to hide the field or 0 to allow the field 
to remain visible. If no changes are to be made, (undef, 0) must be returned.

NOTE: check_params() MUST be called or glueHTML will not function correctly.

=cut
sub set_fieldvaluecallback {
    my $self     = shift;
    my $callback = shift;

    $self->{FORMFIELDCALLBACK} = $callback;
}

# Internal function to output errors and exit the program
sub _die {
    my $self    = shift;
    my $errstr  = shift;

    if (defined $self->{ERRHDL}) {
        &{$self->{ERRHDL}} ($errstr);
    }

    # Call die whether or not the user defined error handler has been called
    #  - the error is fatal and we should not get here if the user defined
    #  handler operates correctly anyway.
    die $errstr;
}

=item B<set_timezone> B<(>I<UseGMT (1/0)>B<,> I<Time change (hours)>B<);>

  $DBinterface->set_timezone(1, 0);  # Set time to GMT +0000
  $DBinterface->set_timezone(0, -5); # Set time to server time -0500
  $DBinterface->set_timezone(1, -8); # Set time to GMT -0800
  $DBinterface->set_timezone(0, 2);  # Set time to server time +0200

Changes the time zone used for timestamps inserted into database records. The
first parameter specifies whether to use GMT time or to use the server time, 
i.e the computer running this script's internal clock. The second parameter
allows time to be added or subtracted in hours.

=cut
sub set_timezone {
#   $self                 $usegmttime;
    $_[0]->{USEGMTTIME} = $_[1];
#   $self                 $timemod;
    $_[0]->{TIMEMOD}    = $_[2];
}

# ------------------------------------------------------------------------
# HTML formatting functions
# ------------------------------------------------------------------------
=pod

=back

=head2 Optional HTML Customisation Methods

=over 4

=item Future Additions

In a later version, callbacks to add user defined form parameters to 
allow state keeping such as password protection etc.

=item B<set_printheader> B<(>I<Callback function address>B<,> I<Print content type header (1/0)>B<);>

  sub printheader {
      my $title    = shift;
      my $headtext = shift;

      print $cgi->header;

      print $cgi->start_html(-title=>"$headtext");

      if ($headtext ne "") {
          print $cgi->h3($headtext);
      }
  }
  $DBinterface->set_printheader(\&printheader, 1);

Transfers the header HTML outputting function to a user defined function 
to allow HTML customisation. (This is printed at the top of every page 
outputed by this module)

The first parameter is a function reference, the second parameter is 1 to 
allow this module to print the HTTP Content-Type header automatically, 0 
to suppress this.

=cut
sub set_printheader {
#   $self                         &printheader;
    $_[0]->{PRINTHEADER}        = $_[1];
#   $self                         $printcontenttype    
    $_[0]->{PRINTCONTENTTYPE}   = $_[2] || 0;
}

# Internal function to start the output in the user's desired style
sub _printHeader {
    my $self     = shift;
    my $title    = shift;
    my $headtext = shift;
    my ($package, $filename, $line) = caller();

    if ($self->{PRINTCONTENTTYPE} == 1) {
        print $self->{CGI}->header;
    }

    if (defined $self->{PRINTHEADER}) {
        &{$self->{PRINTHEADER}} ($title, $headtext);
    } else {
        # Just incase it got missed
        if ($self->{PRINTCONTENTTYPE} != 1) {
            print $self->{CGI}->header;
        }
        print $self->{CGI}->start_html(-title=>"$title",
                                       -bgcolor=>"#FFFFFF",
                                       -text=>"#000077"
                                      );
        if ($headtext ne "") {
            print $self->{CGI}->h3($headtext);
        }
    }

    print "\n<!-- DBIx::glueHTML.pm V$VERSION. Page generated by $package [$filename:$line] -->\n\n";
}

=item B<set_printfooter> B<(>I<Callback function address>B<);>

  sub printfooter {
      print $cgi->end_html;
  }
  $DBinterface->set_printfooter(\&printfooter);

Transfers the footer HTML outputting function to a user defined function 
to allow HTML customisation. (This is printed at the bottom of every 
page outputed by this module)

=cut
sub set_printfooter {
#   $self                  &printfooter;
    $_[0]->{PRINTFOOTER} = $_[1];
}

# Internal function to end the output in the user's desired style
sub _printFooter {
    my $self     = shift;

    if (defined $self->{PRINTFOOTER}) {
        &{$self->{PRINTFOOTER}};
    } else {
        print "</BODY></HTML>";
    }
}

=item B<set_starttable> B<(>I<Callback function address>B<);>

  sub starttable {
    my $colwidth     = shift;
    my $title        = shift;
    my $instructions = shift;
    
    print "<CENTER><BLOCKQUOTE>" . 
          "<TABLE BORDER=0 CELLSPACING=5 CELLPADDING=5>\n" . 
          "<TR><TD COLSPAN=\"$colwidth\" BGCOLOR=\"#FFEEBB\"><H3><FONT COLOR=\"#000000\">" .
          "$title</FONT></H3><FONT SIZE=\"1\">$instructions</FONT></TD></TR>\n\n";
  }
  $DBinterface->set_starttable(\&starttable);

Transfers the table beginning HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to begin all tables)

=cut
sub set_starttable {
#   $self               &startTable;
    $_[0]->{STARTTABLE} = $_[1];
}

# Internal function to create a table in the user's desired style
sub _startTable
{
    my $self         = shift;
    my $colwidth     = shift;
    my $title        = shift;
    my $instructions = shift;

    if (defined $self->{STARTTABLE}) {
        &{$self->{STARTTABLE}}($colwidth, $title, $instructions);
    } else {
        print "<CENTER><BLOCKQUOTE>" . 
              "<TABLE BORDER=0 CELLSPACING=5 CELLPADDING=5>\n" . 
              "<TR><TD COLSPAN=\"$colwidth\" BGCOLOR=\"#FFEEBB\"><H3><FONT COLOR=\"#000000\">" .
              "$title</FONT></H3><FONT SIZE=\"1\">$instructions</FONT></TD></TR>\n\n";
    }
}

=item B<set_starttablerow> B<(>I<Callback function address>B<);>

  sub starttablerow {
    print "<TR>";
  }
  $DBinterface->set_starttablerow(\&starttablerow);

Transfers the table row beginning HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to generate <TR> row beginnings, and is not 
used in printedittablerow-outputted rows)

=cut
sub set_starttablerow {
#   $self                   &startTableRow;
    $_[0]->{STARTTABLEROW} = $_[1];
}

# Internal function to print the start of a table row
sub _printStartTableRow
{
    my $self     = shift;

    if (defined $self->{STARTTABLEROW}) {
        &{$self->{STARTTABLEROW}};
    } else {
        print "<TR>";
    }
}

=item B<set_printtablecell> B<(>I<Callback function address>B<);>

  sub printtablecell {
    my $content  = shift;

    print "<TD BGCOLOR=\"#FFFFEE\">";
    print $content;
    print "</TD>";
  }
  $DBinterface->set_printtablecell(\&printtablecell);

Transfers the table cell printing HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to generate <TD></TD> cells, and is not 
used in printedittablerow-outputted rows)

=cut
sub set_printtablecell {
#   $self                     &printTableCell;
    $_[0]->{PRINTTABLECELL} = $_[1];
}

# Internal function to print a table cell
sub _printTableCell
{
    my $self     = shift;
    my $content  = shift;

    if (defined $self->{PRINTTABLECELL}) {
        &{$self->{PRINTTABLECELL}}($content);
    } else {
        print "<TD BGCOLOR=\"#FFFFEE\">";
        print $content;
        print "</TD>";
    }
}

=item B<set_printtableheadercell> B<(>I<Callback function address>B<);>

  sub printtableheadercell {
    my $content  = shift;

    print "<TD BGCOLOR=\"#EEEEDD\" ALIGN=CENTER><STRONG>";
    print $content;
    print "</STRONG></TD>";
  }
  $DBinterface->set_printtableheadercell(\&printtableheadercell);

Transfers the table header cell printing HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to generate <TD></TD> header cells (Usually bold), 
and is not used in printedittablerow-outputted rows)

=cut
sub set_printtableheadercell {
#   $self                     &printTableHeaderCell;
    $_[0]->{PRINTTABLEHEADERCELL} = $_[1];
}

# Internal function to print a table header cell
sub _printTableHeaderCell
{
    my $self     = shift;
    my $content  = shift;

    if (defined $self->{PRINTTABLEHEADERCELL}) {
        &{$self->{PRINTTABLEHEADERCELL}}($content);
    } else {
        print "<TD BGCOLOR=\"#EEEEDD\" ALIGN=CENTER><STRONG>";
        print $content;
        print "</STRONG></TD>";
    }
}

=item B<set_printendtablerow> B<(>I<Callback function address>B<);>

  sub printendtablerow {
    print "</TR>";
  }
  $DBinterface->set_printendtablerow(\&printendtablerow);

Transfers the table row ending HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to generate </TR> row endings, and is not 
used in printedittablerow-outputted rows)

=cut
sub set_printendtablerow {
#   $self                     &printEndTableRow;
    $_[0]->{PRINTENDTABLEROW} = $_[1];
}

# Internal function to print the end of a table row
sub _printEndTableRow
{
    my $self     = shift;

    if (defined $self->{PRINTENDTABLEROW}) {
        &{$self->{PRINTENDTABLEROW}};
    } else {
        print "</TR>";
    }
}

=item B<set_printedittablerow> B<(>I<Callback function address>B<);>

  sub printedittablerow {
    my $name     = shift;
    my $form     = shift;
    my $label    = shift;

    print "<TR><TD BGCOLOR=\"#EEEEDD\" VALIGN=TOP><B><FONT COLOR=\"#111199\">";
    print $name;
    print "</FONT></B></TD>\n";
	print "<TD BGCOLOR=\"#FFFFEE\">";
    print $form;
    print "<BR><I><FONT SIZE=\"-1\">";
    print $label;
    print "</FONT></I></TD></TR>";
  }
  $DBinterface->set_printedittablerow(\&printedittablerow);

Transfers the edit table's row HTML outputting function to a user defined function 
to allow HTML customisation. (This prints a whole row without calling printendtablerow
or printstarttablerow, and is used in add/modify forms)

=cut
sub set_printedittablerow {
#   $self                     &printEndTableRow;
    $_[0]->{PRINTEDITTABLEROW} = $_[1];
}

# Internal function to print add/modify table rows in the user's desired style
sub _printEditTableRow
{
    my $self     = shift;
    my $name     = shift;
    my $form     = shift;
    my $label    = shift;

    if (defined $self->{PRINTEDITTABLEROW}) {
        &{$self->{PRINTEDITTABLEROW}}($name, $form, $label);
    } else {
        print "<TR><TD BGCOLOR=\"#EEEEDD\" VALIGN=TOP><B><FONT COLOR=\"#111199\">";
        print $name;
        print "</FONT></B></TD>\n";
    	print "<TD BGCOLOR=\"#FFFFEE\">";
        print $form;
        print "<BR><I><FONT SIZE=\"-1\">";
        print $label;
        print "</FONT></I></TD></TR>";
    }
}

=item B<set_endtable> B<(>I<Callback function address>B<);>

  sub endtable {
    print "</TABLE>";
    print "</CENTER></BLOCKQUOTE><HR>";
  }
  $DBinterface->set_endtable(\&endtable);

Transfers the table ending HTML outputting function to a user defined function 
to allow HTML customisation. (This is used to end all tables)

=cut
sub set_endtable {
#   $self                     &endTable;
    $_[0]->{ENDTABLE} = $_[1];
}

# Internal function to end a table in the user's desired style
sub _endTable
{
    my $self    = shift;

    if (defined $self->{ENDTABLE}) {
        &{$self->{ENDTABLE}};
    } else {
        print "</TABLE>";
        print "</CENTER></BLOCKQUOTE><HR>";
    }
}

# internal function to print extra form parameters into a query string
sub _printHiddenQstring {
   my $self    = shift;
   my $isFirst = shift;

   return "";
}

# internal function to print extra form parameters as form elements
sub _printHidden {
   my $self    = shift;
}

# internal function to print a link to repeat the last action
sub _repeatLink {
   my $self    = shift;
   
   return $self->{CGI}->url . "?glueHTML-action=" . $self->{CGI}->param("glueHTML-action")
                            . "&glueHTML-table=" . $self->{CGI}->param("glueHTML-table")
                            . $self->_printHiddenQstring (0);
}

# internal function to print a back link
sub _backLink {
   my $self    = shift;
   
   return $self->{CGI}->url . $self->_printHiddenQstring (1);
}

# Internal function to generate forms
sub _form {
   my $self            = shift;
   my $table           = shift;
   my $action          = shift;
   my $page_title      = shift;
   my $page_heading    = shift;
   my $nodefaults      = shift;
   my $fill_from_table = shift;
   my $instructions;

   if ($action eq "search") {
       $instructions   = "<UL type=\"square\"><LI>Use the % character to match any number of characters (Even none).\n<LI>Use the _ character to match any one character.\n<LI>A % is automatically appended to all strings.\n<LI>You can enter just a normal wildcard character with no special meaning by typing a \\ before it, i.e \\% or \\_.<LI>Leave this form blank to show EVERYTHING.</UL>";
       $instructions  .= "<P>" . $self->{CGI}->submit('Search');
   }
   
   $self->_printHeader($page_title, "");
   print $self->{CGI}->startform;
   $self->_startTable (2, $page_heading, $instructions);
   
   # Output the actual form...
   $self->_createForm($table,$nodefaults,$fill_from_table,$action);
   
   # Mode and action variables
   print $self->{CGI}->hidden(-name => 'post', -value => 'true');
   print $self->{CGI}->hidden(-name => 'glueHTML-action', -value => $action);
   print $self->{CGI}->hidden(-name => 'glueHTML-table', -value => $table);
   $self->_printHidden; # Print any hidden elements necessary
   
   print "\n\n<TR><TD COLSPAN=\"2\"><P></TD></TR>";
   print "<TR><TD></TD><TD>";
   print $self->{CGI}->submit($action eq "search" ? 'Search' : 'Submit');
   print "&nbsp;&nbsp;&nbsp;&nbsp;";
   print $self->{CGI}->reset('Reset');
   print "</TD></TR>";
   print $self->{CGI}->endform;
   $self->_endTable;
   $self->_printFooter;
}

# Internal function to allow the calling script a final chance to change field values and/or force fields hidden
sub _setFormFieldValue {
   my $self            = shift;
   my $table           = shift;
   my $mode            = $self->{CGI}->param("glueHTML-action");
   my $field           = shift;
   my $value           = shift;
   my $default         = shift;

   # Default return values
   my $val             = undef;
   my $forcehidden     = 0;

   # Replace the default values
   if (defined $self->{FORMFIELDCALLBACK}) {
        ($val, $forcehidden) = &{$self->{FORMFIELDCALLBACK}}($table, $mode, $field, $value, $default);
   }

   if ($val == undef) {
       $val             = $value || $default;
   }

   # Return
   return ($val, $forcehidden);
}

# Internal function to generate the actual form content
sub _createForm {
   my $self            = shift;
   my $table           = shift;
   my $nodefaults      = shift;
   my $fill_from_table = shift;
   my $action          = shift;

   my (@fielddesc, @fields, @fieldtypes, @fielddefaults, @primary_keys, $fill_cursor, $field);
   my ($tablename, $names, $label, $lookup, $extrahash, $hidden, $exclude, 
                                    $additionalwhere) = $self->_getTableInfoHash($table);
   
   # Get table column info
   my ($desc_cursor) = $self->_execSql ("describe $table");
   while (@fielddesc = $desc_cursor->fetchrow) {
      push @fields, $fielddesc[0];
      push @fieldtypes, $fielddesc[1];
      push @fielddefaults, $fielddesc[4];
      if ($fielddesc[3] eq "PRI") {
         push @primary_keys, $fielddesc[0];
      }
   }
   $desc_cursor->finish;
   
   # Get primary keys and print them out to allow primary key changes without losing what record 
   # we're editing
   while ($field = shift @primary_keys) {
       my $name = "primary_key_" . $field;
       my $val = $self->{CGI}->param("$field");
       $val =~ s/\\/\\\\/g;
       $val =~ s/'/\\'/g;
       print $self->{CGI}->hidden(-name => $name, value => $val);
   }
  
   # Get table values if we're filling from an existing table
   my ($field_values);
   if ($fill_from_table ne "") {
          $fill_cursor = $self->_execSql ($self->_selectSql($table));

          if (! ($field_values = $fill_cursor->fetchrow_hashref)) {
                  $self->_die("Database error $DBI::errstr while loading form values");
          }
   }
   
   fieldloop: while ($field = shift @fields) {
      my ($default) = shift @fielddefaults;
      my ($type) = shift @fieldtypes;
      my ($val, $max, $size);
      my ($itemname, $itemform, $itemlabel, $forcehidden);
      
      my $item;
      foreach $item (@$exclude) {
         if ($field eq $item) {
            next fieldloop;
         }
      }
      
      if ($default eq "NULL" || $nodefaults ne "") {
         $default = "";
      }
      
      # Allow the calling script to set the default value and/or force the field hidden
      ($val, $forcehidden) = $self->_setFormFieldValue($table, $field, ($fill_from_table ne "" ? $field_values->{$field} : $self->{CGI}->param("$field")), $default);

      # Force the field hidden if _setFormFieldValue sets the forcehidden flag
      if ($forcehidden == 1) {
          push (@$hidden, $field);
      }

      ($max) = $type =~ /\((.*)\)/;
      $size =  $max < 50 ? $max : 50;
      
      if ((substr($type, 0, 10) eq 'timestamp(') && ($val eq "") && ($nodefaults eq "")) {
         $val = $self->_currentTime;
      }
      
      # Process hidden fields - Don't hide on searches to allow people to search by all fields
      if ($action ne "search") {
          foreach $item (@$hidden) {
             if ($field eq $item) {
                print $self->{CGI}->hidden(-name=>$field,value=>$val);
                next fieldloop;
             }
          }
      }
      
      if ($$names{$field} eq "") {
         $itemname =  "$field:";
      } else {
         $itemname =  $$names{$field};
      }
      
      if ( $$lookup{$field} ne "" ) {
         # make a select list based on the SQL the caller sent us
         if ($nodefaults ne "") {
            $itemform = $self->_createSelectList($field,$$lookup{$field},"","allowblank");
         } else {
            $itemform = $self->_createSelectList($field,$$lookup{$field},$val);
         }
      
      } elsif ($type =~ "mediumtext") {
            $itemform = $self->{CGI}->textarea(-'name'=>$field,
                                                'default'=>$val,
                                                'rows'=>10,
                                                'columns'=>70);
      
      } elsif ($type =~ "text") {
            $itemform = $self->{CGI}->textarea(-'name'=>$field,
                                                'default'=>$val,
                                                'rows'=>5,
                                                'columns'=>50);
      
      } elsif (substr($type, 0, 5) eq 'enum(') {
         # TODO: Too mysql specific?
         my $args = substr($type, 5, -1);
         my @list = split(/,/, $args);
         $itemform = "<select name=$field>";
         
         if ($nodefaults ne "" && $val eq "") {
            $itemform .= "<option selected>\n";
         }
         
	 my $option;
         while ($option = shift @list) {
            if ($option =~ /^'(.*)'$/) {
               $option = $1;
            }
            
            if ($option eq "$val") {
               $itemform .= "<option selected>";
            } else {
               $itemform .= "<option>";
            }
            
            $itemform .= "$option\n";
         }
         
         $itemform .= "</select>\n";
      
      } elsif ($$extrahash{$field} eq "encryptpassword") {
         $itemform = $self->{CGI}->password_field(-'name' => $field,
                                                   'value' => '',
                                                   'size' => $size,
                                                   'maxlength' => $max);
      } else {
         $itemform = $self->{CGI}->textfield(-'name' => $field,
                                              'value' => $val,
                                              'size' => $size,
                                              'maxlength' => $max);
      }
      
      if ( $$label{$field} ne "" ) {
         $itemlabel = $$label{$field};
      } else {
         $itemlabel = "";
      }

      # Now print the HTML
      $self->_printEditTableRow ($itemname, $itemform, $itemlabel);
   }
   
   if ($fill_from_table ne "") {
       $fill_cursor->finish;
   }
}

# Internal function to generate select lists based on SQL statements
sub _createSelectList {
    my $self            = shift;
    my $field           = shift;
    my $sql             = shift;
    my $default         = shift;
    my $allowblank      = shift;

    my (@row);

	my ($cursor) = $self->_execSql ("$sql");

    my ($rettext) = "";

	$rettext .= "<select name=$field>";
	if ($allowblank ne "") {
		$rettext .= "<option>\n";
	}

	while (@row = $cursor->fetchrow) {

		if ($row[0] eq "$default") {
			# if their query returns 2 columns, use the first as the value
			if ($row[1] ne "") {
				$rettext .= "<option selected value=$row[0]>";
			} else {
				$rettext .= "<option selected>";
			}
		} else {
			# if their query returns 2 columns, use the first as the value
			if ($row[1] ne "") {
				$rettext .= "<option value=$row[0]>";
			} else {
				$rettext .= "<option>";
			}
		}

		# if their query returns 2 columns, use the second as the label
		if ($row[1] ne "") {
			$rettext .= "$row[1]\n";
		} else {
			$rettext .= "$row[0]\n";
		}

	}

	$rettext .= "</select>\n";

    return $rettext;
}

sub _currentTime {
	my $self            = shift;
    my $timemod         = $self->{TIMEMOD} != 0 ? $self->{TIMEMOD} * 60 * 60 : 0;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

	if ($self->{USEGMTTIME} == 0) {
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $timemod);
	} else {
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time + $timemod);
	}

	$sec = $sec < 10 ? "0$sec" : $sec;
	$min = $min < 10 ? "0$min" : $min;
	$hour = $hour < 10 ? "0$hour" : $hour;
	$mon++;
	$mon = $mon < 10 ? "0$mon" : $mon;
	$mday = $mday < 10 ? "0$mday" : $mday;
	$year = $year + 1900;

	return("$year$mon$mday$hour$min$sec");
}

# ------------------------------------------------------------------------
# SQL formatting and output functions
# ------------------------------------------------------------------------

# Internal function to execute SQL commands
sub _execSql {
    my $self    = shift;
    my $cmd     = shift;
    my $sthdl;

    $sthdl     = $self->{DBH}->prepare($cmd)  || $self->_die("Database error preparing $cmd: " . $sthdl->errstr);
    $sthdl->execute                           || $self->_die("Database error executing $cmd: " . $sthdl->errstr);

    return $sthdl;
}

# Internal function to quote and escape SQL entries
sub _sqlQuote {
    my $self    = shift;
    my $str     = shift;

    # Use DBI's quote method which ensures correct quoting for whatever database system is being used
    return $self->{DBH}->quote($str);
}

# Internal function to return a hash of all data from the info table
sub _getTableInfoHash {
#    my ($package, $filename, $line) = caller();
#    print $line;
    my $self    = shift;
    my $table   = shift;
    my $itable  = $self->{ITABLE};

    my $sql     = "select TableName, NameHash, LabelHash, LookupHash, ExtraHash, Hidden, Exclude, AdditionalWhere from $itable where TableID = '$table'";

    my $cursor = $self->_execSql ($sql);
    
    my ($entry, $table_name, %namehash, %labelhash, %lookuphash, %extrahash, @hidden, @exclude, $additionalwhere);

    # Don't die on fail - simply return an empty hash and default everything
    # TODO: Protect against undefined tables for this
    if ($entry = $cursor->fetchrow_hashref) {
        my ($hashInfo, $pair, @pairs);

        # Load table name
        $table_name  = $entry->{"TableName"};

        # Load name hash
        $hashInfo    = $entry->{"NameHash"};
        @pairs       = split(/&/, $hashInfo);
        foreach $pair (@pairs) {
            my ($name, $value) = split(/=/, $pair);
            $namehash{$name}   = $value;
        }

        # Load label hash
        $hashInfo    = $entry->{"LabelHash"};
        @pairs       = split(/&/, $hashInfo);
        foreach $pair (@pairs) {
            my ($name, $value) = split(/=/, $pair);
            $labelhash{$name}  = $value;
        }

        # Load lookup hash
        $hashInfo    = $entry->{"LookupHash"};
        @pairs       = split(/&/, $hashInfo);
        foreach $pair (@pairs) {
            my ($name, $value) = split(/=/, $pair);
            $lookuphash{$name} = $value;
        }

        # Load extra hash
        $hashInfo    = $entry->{"ExtraHash"};
        @pairs       = split(/&/, $hashInfo);
        foreach $pair (@pairs) {
            my ($name, $value) = split(/=/, $pair);
            $extrahash{$name}  = $value;
        }

        # Load hidden array
        $hashInfo    = $entry->{"Hidden"};
        @hidden      = split(/&/, $hashInfo);

        # Load exclude array
        $hashInfo    = $entry->{"Exclude"};
        @exclude     = split(/&/, $hashInfo);

        # Load table name
        $additionalwhere = $entry->{"AdditionalWhere"};
    }

    $cursor->finish;
    return ($table_name, \%namehash, \%labelhash, \%lookuphash, \%extrahash, \@hidden, \@exclude, $additionalwhere);
}

# Internal function to return a hash of just the extra data from the info table
sub _getTableExtraHash {
    my $self    = shift;
    my $table   = shift;

    my $cursor = $self->_execSql ('select ExtraHash from ' . $self->{ITABLE} . ' where TableID = ' . $self->_sqlQuote($table));
    my ($entry, %hash);

    # Don't die on fail - simply return an empty hash and default everything
    # TODO: Protect against undefined tables for this
    if ($entry = $cursor->fetchrow_hashref) {
        my $hashInfo    = $entry->{"ExtraHash"};

        my @pairs       = split(/&/, $hashInfo);
        my $pair;

        foreach $pair (@pairs) {
            my ($name, $value) = split(/=/, $pair);

            $hash{$name} = $value;
        }
    }

    $cursor->finish;
    return \%hash;
}

# Internal function to execute a SQL modify
sub _modifyRecord {
    my $self    = shift;
    my $table   = shift;

    # Run the SQL
    my $sql = $self->_updateSql ($table);
    my $cursor = $self->_execSql ($sql);
    $cursor->finish;

    # Tell the people what we did
    $self->_printHeader('Modification Successful', 'Record modified successfully.');
    print "<UL>";
    print "<LI><A HREF=\"" . $self->_backLink . "\">Main Menu</A>";
    print "</UL>";
    $self->_printFooter;

    # Log it, if logging is enabled
    $self->_logEvent("Record modified from $table", $sql);
}

# Internal function to execute a SQL delete
sub _deleteRecord {
    my $self    = shift;
    my $table   = shift;

    # Require confirmation of the delete
	if ($self->{CGI}->param('confirm')) {
        # Run the SQL
        my $sql = $self->_deleteSql($table);
        my $cursor = $self->_execSql ($sql);
        $cursor->finish;

        # Tell the people what we did
        $self->_printHeader('Deletion Successful', 'Record deleted successfully.');
        print "<UL>";
        print "<LI><A HREF=\"" . $self->_backLink . "\">Main Menu</A>";
        print "</UL>";
        $self->_printFooter;

        # Log it, if logging is enabled
        $self->_logEvent("Record deleted from $table", $sql);
	} else {
        # Ask them to confirm their action
        $self->_printHeader('Confirm Delete', 'Confirm Delete');
        print $self->{CGI}->b('Press back to cancel. Press Confirm to delete.');
        print $self->{CGI}->startform;
        $self->_printHidden; # Print any hidden elements necessary

        # Print all the form params as hidden fields
        my @form = $self->{CGI}->param;
        my $name;
		while ($name = shift @form) {
            print $self->{CGI}->hidden (-name=>$name, -value=>$self->{CGI}->param ($name) );
		}

        print $self->{CGI}->hidden(-name=>'confirm',-value =>'true');
        print $self->{CGI}->submit('Confirm');
        print "&nbsp;&nbsp;&nbsp;";
        print '<A HREF="' . $self->_backLink . '">Cancel</A>';
        print $self->{CGI}->endform;
        $self->_printFooter;
	}
}

# Internal function to execute a SQL insert
sub _insertRecord {
    my $self    = shift;
    my $table   = shift;

    # Run the SQL
    my $sql = $self->_insertSql ($table);
    my $cursor = $self->_execSql ($sql);
    $cursor->finish;

    # Tell the people what we did
    $self->_printHeader('Addition Successful', 'Record added successfully.');
    print "<UL>";
    print "<LI><A HREF=\"" . $self->_repeatLink . "\">Add Another</A>";
    print "<LI><A HREF=\"" . $self->_backLink . "\">Main Menu</A>";
    print "</UL>";
    $self->_printFooter;

    # Log it, if logging is enabled
    $self->_logEvent("Record added to $table", $sql);
}

# _insertSql - internal function to generate insert statements for $table, inserting all values in
# $self->{CGI}->param which match the table column names.
sub _insertSql {
    my $self            = shift;
    my $table           = shift;

    # Use a DESCRIBE statement to get the field default values
    my $desc_cursor = $self->_execSql ("describe $table");
    my (@fields, @fielddefaults, @fieldextra, @fielddesc);
    my $fieldextra2 = $self->_getTableExtraHash($table); # Get extra info from the infotable
    while (@fielddesc = $desc_cursor->fetchrow) {
		push @fields, $fielddesc[0];
		push @fielddefaults, $fielddesc[4];
		push @fieldextra, $fielddesc[5];
	}
    $desc_cursor->finish;

    my $first_time = 1;
    my ($field, $default, $extra);

    # Start the SQL statement
    my $sql = "insert into $table values (";

    # Step through the fields and add a section to the statement for each
    while ($field   = shift @fields) {
        $default    = shift @fielddefaults;
        $extra      = shift @fieldextra;

        # Convert NULL fields to "" unless they are auto incrementing in which case
        # leave them as NULL to allow the auto increment to function
        $default    = $default eq "NULL" ? "" : $default;
		if ($extra eq "auto_increment") {
			$default = "NULL";
		}

        # Get the value if we have a CGI-specified value, else use the default
        my $val     = $self->{CGI}->param("$field") || $default;

        # Add commas between statements
        if ($first_time != 1) {
			$sql .= ', ';
		}

        # Encrypt passwords if required, then add the value to the statement
        if ($$fieldextra2{$field} eq "encryptpassword") {
            $sql .= "PASSWORD(" . $self->_sqlQuote($val) . ")";
		} else {
            $sql .= $self->_sqlQuote($val);
		}

		$first_time = 0;
	}

    # Close the SQL statement
	$sql .= ")";

    return ($sql);
}

# _selectSql - internal function to generate select statements for $table, selecting all fields
# with a where clause based on the values in $self->{CGI}->param that match the table's column names.
# The second parameter is appended to the statement, if it is present, which can be used for
# order by clauses etc.
sub _selectSql {
    my $self            = shift;
    my $table           = shift;
    my $additional      = shift;

    # Use a DESCRIBE statement to get the field default values
    my $desc_cursor = $self->_execSql ("describe $table");
    my (@fields, @fielddesc);
    while (@fielddesc = $desc_cursor->fetchrow) {
		push @fields, $fielddesc[0];
	}
    $desc_cursor->finish;

    my $first_time = 1;
    my $field;

    # Start the SQL statement
    my $sql = "select * from $table ";

    # Step through the fields and add a section to the statement for each
	while ($field = shift @fields) {
        my $val = $self->{CGI}->param("$field");
		next if (!$val);

        if ($first_time == 1) {
			$sql .= 'where ';
			$first_time = 0;
		} else {
			$sql .= 'and ';
		}

        # TODO: might want to do type check here - does it matter?
        # Add the SQL like statement and append a % to the value to allow part searching
        $sql .= "$field like " . $self->_sqlQuote($val . "%") . " ";
	}

    # Add any additional data
    $sql .= $additional;

	return($sql);
}

# _updateSql - internal function to generate update statements for $table, inserting all values in
# $self->{CGI}->param which match the table column names.
sub _updateSql {
    my $self            = shift;
    my $table           = shift;

    # Use a DESCRIBE statement to get the primary keys and field names
    my $desc_cursor = $self->_execSql ("describe $table");
    my (@fields, @primary_keys, @fielddesc);
    my $fieldextra2 = $self->_getTableExtraHash($table); # Get extra info from the infotable
    while (@fielddesc = $desc_cursor->fetchrow) {
        # Skip if this is a password and no change has been requested
        next if ( ($$fieldextra2{$fielddesc[0]} eq "encryptpassword") && ($self->{CGI}->param($fielddesc[0]) eq "") );

        push @fields, $fielddesc[0];
        if ($fielddesc[3] eq "PRI") {
            push @primary_keys, $fielddesc[0];
        }
	}
    $desc_cursor->finish;

    my $first_time = 1;
    my $field;

    # Start the SQL statement
    my $sql = "update $table ";

    # Step through the fields and add a section to the statement for each
	while ($field = shift @fields) {
        my $val =   $self->{CGI}->param("$field");
           $val =   $val eq "NULL" ? "" : $val;

        if ($first_time == 1) {
			$sql .= 'set ';
			$first_time = 0;
		} else {
			$sql .= ', ';
		}

        # Encrypt passwords if required, then add the value to the statement
        if ($$fieldextra2{$field} eq "encryptpassword") {
            $sql .= $field . "=" . "PASSWORD(" . $self->_sqlQuote($val) . ") ";
		} else {
            $sql .= $field . "=" . $self->_sqlQuote($val) . " ";
        }
	}

	$first_time = 1;
	while ($field = shift @primary_keys) {
        my $val = $self->{CGI}->param("primary_key_$field");

		if ( $first_time) {
			$sql .= 'where ';
			$first_time = 0;
		} else {
			$sql .= 'and ';
		}

        $sql .= "$field = " . $self->_sqlQuote($val) . " ";
	}
    if ($first_time == 1) { # this is very bad - table has no primary keys...
        $self->_die("_updateSql failed - $table has no primary key set");
	}

	return($sql);
}

# _deleteSql - internal function to generate delete statements for $table, with a where clause
# based on where $self->{CGI}->param which match $table's primary key names.
sub _deleteSql {
    my $self            = shift;
    my $table           = shift;

    # Use a DESCRIBE statement to get the primary keys
    my $desc_cursor = $self->_execSql ("describe $table");
    my (@primary_keys, @fielddesc);
    my $fieldextra2 = $self->_getTableExtraHash($table); # Get extra info from the infotable
    while (@fielddesc = $desc_cursor->fetchrow) {
        if ($fielddesc[3] eq "PRI") {
            push @primary_keys, $fielddesc[0];
        }
	}
    $desc_cursor->finish;

    my $first_time = 1;
    my $field;

    # Start the SQL statement
    my $sql = "delete from $table ";

    while ($field = shift @primary_keys) {
        my $val = $self->{CGI}->param("$field");

		if ( $first_time) {
			$sql .= 'where ';
			$first_time = 0;
		} else {
			$sql .= 'and ';
		}

        $sql .= "$field = " . $self->_sqlQuote($val) . " ";
	}

	return($sql);
}

1;

__END__

=pod

=back

=head1 INFOTABLE FORMAT

The correct SQL structure for the infotable is shown below, in MySQL format. If another database is 
being used, an equivalent SQL structure should work correctly providing the field names remain the 
same. User defined fields can be safely appended to the table and will be ignored by glueHTML.

  CREATE TABLE [infotable name] (
    TableID varchar(200) DEFAULT '' NOT NULL,         # SQL name of table
    TableName tinytext DEFAULT '' NOT NULL,           # User friendly name of table
    NameHash text DEFAULT '' NOT NULL,                # 'name=value&name2=value2' style entry for names of fields
    LabelHash text DEFAULT '' NOT NULL,               # 'name=value&name2=value2' style entry for labels of fields
    LookupHash text DEFAULT '' NOT NULL,              # 'name=select Thing from Table&name2=select Somethingelse from Table' style entry for value lookup
    ExtraHash text DEFAULT '' NOT NULL,               # 'name=extra_info&name2=extrainfo' style entry containing extra information. Currently recognised values
                                                      #        include 'encryptpassword' which causes SQL statements to encrypt this field with the mysql 'PASSWORD'
                                                      #        function.
    Hidden text DEFAULT '' NOT NULL,                  # 'name&name2' style entry for hidden columns
    Exclude text DEFAULT '' NOT NULL,                 # 'name&name2' style entry for excluded columns
    AdditionalWhere text DEFAULT '' NOT NULL,         # Additional SQL 'where' clause for search modes, e.g to exclude items from searches
    # Add any user defined fields here
    PRIMARY KEY (TableID)
  );

A description of each field follows:

=over 4

=item TableID

The table's identifier. This should exactly match the table's name in the database. For example:

  users

=item TableName

A user friendly name for the table, shown in the output. For example:

  Registered Users

=item NameHash

A string containing user-friendly names for the fields in the table. Formatted similar to 
a HTML query string, although no form of escaping is available at the moment. For example:

  name=User Name&dob=User's Date of Birth&occupation=User's Occupation&password=User's Password

=item LabelHash

Similar to I<NameHash>, contains a description for each field that is displayed below any form 
input fields. For example:

  name=Enter the user's name&dob=Enter the user's date of birth in the format DDMMYY&occupation=Select the user's occupation&password=The user's password

=item LookupHash

Used to create dropdown lists, such as in the current example, an additional table called 
'occupations' can be created and filled with a list of possible occupations. In editing modes, a drop 
down list of all available occupations can then be created. LookupHash should contain a select 
statement to associate with a field. The select statement should return one or two fields. If it 
returns two, the first will be used as the value of the form element, the value that will be 
placed in the database and the second will be used as the value displayed to the user, i.e a select 
box will be created with the syntax:

  <option value="[FIRSTFIELD]">[SECONDFIELD]

If only one field is returned, it is used as both the value displayed and the value of the form element.

For example:

  occupation=select ID, Name from occupations order by Name

If other lookups are needed they can be joined using the usual '&' syntax.

=item ExtraHash

Used to pass additional information to glueHTML. Currently only one value is supported, 
'encryptpassword' which causes any entries in the field to be encrypted using the MySQL 
PASSWORD() function. For example:

  password=encryptpassword

=item Hidden

Used to hide fields from the user, for example primary key ID fields should be hidden. Simply a 
list of each hidden field, separated by '&'. Hidden fields are printed as 'hidden' input fields. 
For example to hide 'id' and 'secretdata':

  id&secretdata

=item Exclude

Completely removes fields from forms, formatted in the same way as I<Hidden>. For example:

  invisiblefield&invisiblefield2

=item AdditionalWhere

Additional SQL clause to be appended to the select statement used in search modes, for example:

  AND NOT name = 'Fred'

could be used to exclude 'Fred' from searches. Also, order by clauses can be appended to sort 
output.

NOTE: appending to the where clause requires the statement to begin with 'AND'.

=back

=head1 KNOWN BUGS

=over 4

=item *

Hidden and exclude arrays are nonfunctional due to array handling problems...

[TODO - Believed to be fixed, awaiting testing]

=item *

Code may be too MySQL specific and not function on other databases. This needs to be tested.

=item *

Currently may allow users to manipulate tables not defined in the infotable depending on database 
in use. This will be switchable in the next version.

=back

=head1 AUTHOR

James Furness, furn@base6.com

Parts based upon B<mysql-lib.pl> by Ron Crisco E<lt>ronsolo@ronsolo.comE<gt>.

=head1 SEE ALSO

L<CGI>
L<DBI>

=head1 COPYRIGHT

Copyright (c)1999 James Furness E<lt>furn@base6.comE<gt>. All Rights Reserved.
This module is free software; it may be used freely and redistributed
for free providing this copyright header remains part of the module. You may
not charge for the redistribution of this module. Selling this code without
James Furness' written permission is expressly forbidden.

This module may not be modified without first notifying James Furness
E<lt>furn@base6.comE<gt> (This is to enable me to track modifications). In all
cases the copyright header should remain fully intact in all
modifications.

This code is provided on an "As Is" basis, without warranty, expressed or
implied. The author disclaims all warranties with regard to this software,
including all implied warranties of merchantability and fitness, in no
event shall the author, James Furness be liable for any special, indirect
or consequential damages or any damages whatsoever including but not
limited to loss of use, data or profits. By using this module you agree to
indemnify James Furness from any liability that might arise from it's use.
Should this code prove defective, you assume the cost of any and all
necessary repairs, servicing, correction and any other costs arising
directly or indrectly from it's use.

The copyright notice must remain fully intact at all times.
Use of this program or its output constitutes acceptance of these terms.

Parts of this module are based upon mysql-lib.pl by Ron Crisco.

=head2 Acknowledgments

Thanks to Ron Crisco, Richard Smith and Stephen Heaslip without who I would
probably have not written this. Thanks to Tom Christiansen for his L<perltoot>
manpage which was useful in writing this module in addition to the L<perlmod>,
L<perlmodlib> and Tim Bunce's modules file (Available on CPAN).

=cut


