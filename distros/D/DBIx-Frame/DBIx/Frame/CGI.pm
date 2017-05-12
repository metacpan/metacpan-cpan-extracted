$VERSION = "1.01.02";
package DBIx::Frame;
our $VERSION = "1.01.02";

# -*- Perl -*- 		Wed May 26 09:08:25 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2001-2004, Tim Skirvin and UIUC Board of Trustees.
# Redistribution terms are below.
###############################################################################

=head1 NAME

DBIx::Frame::CGI - tools for web-based use of DBIx::Frame databases

=head1 SYNOPSIS

  use DBIx::Frame::CGI;

  DBIx::Frame->init('server', 'dbtype') || exit(0);
  my $DB = DBIx::Frame->new('database', 'user', 'pass')
    or die("Couldn't connect to database: ", DBIx->errstr);
  my $CGI = new CGI || die "Couldn't open CGI";

  my $params = {};
  foreach ($cgi->param) { $$params{$_} = $cgi->param($_); }
  my $action = $cgi->param('action') || "";
  my $table  = $cgi->param('table')  || "";

  print $cgi->header(), $cgi->start_html(-title => "YOUR TITLE");
  print $DB->make_html( $action, $table, $params, {} )
	or die "Couldn't run script";
  print $cgi->end_html();
  exit(0);

More functions, and detailed descriptions, are below.

=head1 DESCRIPTION

DBIx::Frame::CGI is an extension of the DBIx::Frame module to allow for web
use and administration of DBIx::Frame databases.  It provides a common set
of HTML functions for creating, modifying, viewing, and deleting entries
in the database.  These tools allow for simple administration scripts, as
well as a decent API for creating more complex user scripts. 

=cut

use strict;
use DBIx::Frame;
use HTML::FormRemove qw(RemoveFormValues);
use Exporter;
use CGI;

use vars qw(@EXPORT @EXPORT_OK @ISA @ACTIONS %ACTION );
@ACTIONS = qw( create list search );
%ACTION = ( 'edit'   => \&html_edit, 	'view'   => \&html_view,
	    'create' => \&html_create,  'search' => \&html_search,
	    'update' => \&html_update,  'delete' => \&html_delete,
	    'insert' => \&html_insert,  'list'   => \&html_list_banner,
	    ''       => \&html_actions, 'actions' => \&html_actions,
	  );

use SelfLoader;
SelfLoader->load_stubs();
1;

__DATA__        # Comment me out to test the functions without SelfLoader;

=head1 USAGE

All of these functions must be invoked on a fully created C<DBIx::Frame>
object, as discussed in its manual page.

There are four type of functions in this package - Full-Layout, HTML
Form Layout, and Actions.

=head2 Full-Layout Functions

Note that these layout functions are fairly specific - they will make fully
laid out HTML, based on the design goals of the author.  These goals may
not mesh exactly with what you want to do; if this is so, then it should
be a fairly simple matter to write new functions based on these for your
own CGI scripts.

Specifically, each of these can be overridden by adding a section to your 
.cgi files that looks like this:

  package YOUR::PACKAGE;

  sub html_menu { 
    # insert your own code here
  }

Then, when you're using your own package, it will use this version of
C<html_menu()> (or any other piece of code) instead of the system-default
code.  You can therefore use this as a template to make your own web
designs.

The defaults, though, are actually fairly decent, or at least a fair bit
of effort has been put into helping them be that way.  Suggestions are, as
always, encouraged.

=over 4

=item make_html ( TABLE, ACTION, PARAMS, OPTIONS [, OTHER] )

Returns a whole formatted HTML page, using the subfunctions from the
package, based on the input from C<ACTION>.  At the bottom of the page 
is a centered C<html_menu()>.  The page still needs headers and footers.
C<TABLE>, C<PARAMS>, C<OPTIONS>, and C<OTHER> are passed into the sub-
functions as appropriate.

Default C<ACTION>s (case-insensitive):

  ACTION	Called Function		Function Type

  [none]	html_actions()		Full-Layout Options
  create	html_create()		HTML Form Layout
  list		html_list()		HTML Form Layout
  search	html_search()		HTML Form Layout
  edit		html_edit()		HTML Form Layout
  view		html_view()		HTML Form Layout
  delete	html_delete()		HTML Form Layout + Actions
  update 	html_update()		Actions
  insert	html_insert()		Actions

More actions can be added with C<actions()>, and actions can be removed
with C<remove_action()>.  All actions are invoked with the following 
parameters:

  C<TABLE>, C<PARAMS>, C<OPTIONS>, C<OTHER>

Valid C<OPTIONS>:

  nomenu	If set, don't include the bottom menu C<html_menu()>
  quiet		If set, print as little information as possible with the 
		HTML tables; not yet fully implemented

=cut

sub make_html {
  my ($self, $table, $action, $params, $options, @other) = @_;
  $params = {} unless ($params && ref $params);
  $options = {} unless ($options && ref $options);
  $action ||= 'actions';

  my @return;
  if ( my $code = $self->action(lc $action) ) {	
    push @return, &{$code}($self, $table, $params, $options, @other);
  } else { push @return, "Invalid action: $action" }
  
  unless ( $$options{'nomenu'} ) { 
    push @return, "<center> <h2>Table Options</h2> </center> ";
    push @return, "<center>" . $self->html_menu($table) . "</center>";
  }
  
  return wantarray ? @return : join("\n", @return);
}


=item html_actions ( [ TABLE [, PARAMS, OPTIONS ]] )

Returns a table of table/action pairs available to the user.  Gets the
information from C<tables()> and C<@DBIx::Frame::ACTIONS>.  Each column of
the table is a different action; each row is a table.  

=cut

sub html_actions {
  my ($self, $table, $params, $options, @other) = @_;
  my @list = sort $self->tables;
  my @return = "<table align=center width=100%>";
  my $list = scalar @list;

  foreach my $action ( @ACTIONS ) {
    my $act = ucfirst $action;
    push @return, "  <td align=center> $act </td>";
  }
  push @return, " </tr>";

  foreach my $table (@list) {
    next unless $table;
    foreach my $action ( @ACTIONS ) {
      next unless $action;
      push (@return, "  <td align=center>" . 
     		"<a href='$0?table=$table&action=$action'>$table</a>"
	. "</td>");
    }
    push (@return, " </tr>");
  }
  push (@return, "</table>\n");
  wantarray ? @return : join("\n", @return);
}

=item html_menu ( [TABLE] )

Returns a menu in HTML to navigate the various tables and actions
available to the user.  Gets the information from C<tables()> and 
C<@DBIx::Frame::ACTIONS>.  The menu is an HTML form that reinvokes the
calling program, using the fields 'action' and 'table'.  

=cut

sub html_menu {
  my ($self, $table, @other) = @_;
  my $cgi = new CGI;

  my @return = $cgi->start_form;
  
  my @list = sort $self->tables;
  push @return, $cgi->popup_menu('table', \@list, $table);
  foreach ( @ACTIONS ) { 
    next unless $_; 
    push @return, $cgi->submit('action', ucfirst $_ ); }
  push @return, $cgi->end_form;

  wantarray ? @return : join("\n", @return);
}

=back

=head2 HTML Form Layout 

The HTML Form Layout functions are generally based around each table's
C<html()> function, which is defined in its class.  Note that this
function must be properly created if you expect these functions to
actually do anything.

=over 4

=item html_create ( TABLE, PARAMS, OPTIONS )

Returns an HTML form containing the code necessary to insert an item into
the database.  Submitting the form should invoke C<html_insert()>.

=cut

sub html_create {
  my ($self, $table, $params, $options, @other) = @_;
  my $html = $self->html->{$table}; 
  my @return;
  push @return, "<center><font size=+2>Add to '$table'</font></center><br />" 
			unless $$options{'quiet'};
  push @return, <<EOL;
  <center>
   <FORM action='$0' method=post>
    <input type=hidden name=action value='insert'>
    <input type=hidden name=table value=$table>
    @{[ $self->_replace($params || {}, $html->( $self, undef, 'create', 
			 $options )) ]}
   </FORM>
  </center>
EOL
  wantarray ? @return : join("\n", @return);
}

=item html_list ( TABLE, PARAMS, OPTIONS )

=item html_list_banner ( TABLE, PARAMS, OPTIONS )

=item html_list_nosearch ( TABLE, PARAMS, OPTIONS, ENTRIES )

Returns an HTML table containing data selected with C<PARAMS>, using 
C<make_list()>.  (Note that this does not use the C<html()> function.)
The table also includes links to a perform more actions on the items -
by default, it's 'view', but 'edit' and 'delete' can be added.

Valid options for C<OPTIONS>:

  nodetail	Doesn't offer 'view' action
  admin		Offers 'edit' and 'delete' action
  count		Total entries to print.  Defaults to 50.
  first		First entry to print.  Defaults to 0.
  last		Last entry to print.  Defaults to (first + count)
  nocount	Don't offer 'next' and 'last' options, offer a 
		  search dialogue instead (if necessary to narrow 
		  the search) 
  nodelsearch	Don't include the html_search() dialogue box if no 
		  matches are found.
  tdopts	The options to use for each of the <td> tags in the 
		  table.  Defaults to 'align=center'.
  useropts	See below.

The trickiest of the above options is 'useropts'.  This must be an array
reference; it contains a list of additional actions to offer for each
item.  Each array item must be either the name of the function you want to
invoke (see B<actions()> for information on how to add these), or another
array reference; this reference must contain first the name of the
function you want to invoke, and then a list of tables that it affects.  

B<html_list_banner()> is the same as B<html_list()>, except that it returns
a small banner at the top.  B<html_list()> is therefore more easily embedded 
in other code.

B<html_list_nosearch()> actually does the work of B<html_list()> using 
an array of selected datahashes (B<ENTRIES>).  It may be invoked by other
programs that want to select based on their own criteria.

=cut

sub html_list {
  my ($self, $table, $params, $options, @other ) = @_;
  return "" unless $table;
  $self->html_list_nosearch($table, $params, $options, 
  		$self->select($table, $self->_html_select($params), @other) );
}

sub html_list_nosearch {
  my ($self, $table, $params, $options, @entries) = @_;
  return "" unless $table;  

  my $entrycount = scalar @entries;

  $options ||= {};
  my $total  = $$options{'count'} || 50;
  my $first  = $$params{'first'}  || 0;
  my $last   = $$params{'last'}   || $first + $total;

  my $tdopts = $$options{'tdopts'}   || "align=center";

  # Get the list of actions to perform
  my @actions;
  
  push @actions, 'view' unless ( $$options{nodetail} ); 
  push @actions, 'edit'   if ($$options{admin}) ;
  push @actions, 'delete' if ($$options{admin}) ;

  # Parse 'useropts'
  if ( $$options{useropts} ) {
    next unless ref $$options{useropts};
    my @useropts = @{$$options{useropts}};

    foreach my $option (@useropts) {
      next unless $option;
      if (ref $option) {
        my $probation = shift @{$option};
        my %tables;
        foreach ( @{$option} ) { $tables{lc $_}++ }
        next unless $tables{lc $table};
	push @actions, $probation;
      }
    }
  }

  my $printed = 0;
  my @return = "<table width=100%>\n";


  # Iterate through the proper entries
  for (my $i = $first; $i < $last; $i++) {
    my $entry = $entries[$i];
    next unless ($entry && ref $entry);

    # Print the HTML headers from list_head(), if not done yet
    unless ($printed++) {
      push @return, " <tr>";
      foreach my $item ( $self->list_head($table) ) {
        push @return, "  <th>$item</th>";
      }
      push @return, "  <th>Actions</th>" if scalar(@actions);
      push @return, " </tr>";
    }

    push @return, " <tr>";
    foreach my $item ($self->make_list($table, $entry)) {
      # push @return, "  <td align=center> $item </td>";
      push @return, "  <td $tdopts> $item </td>";
    }
    if (scalar @actions) { 
      my @list;
      foreach my $option (@actions) {
        my $action = $self->_action($table, $option, $entry, $0);
        push @list, "<a href='$action'>" . ucfirst lc $option . "</a>";
      }
      push @return, "  <td align=center nowrap>", join(" | \n", @list), "</td>";
    }
    push @return, " </tr>";
  }

  if (! $printed ) {	# No entries matched, go back to 'search'
    push @return, "<p align=center><font size=+2><b>No matches</b></font></p>";
    push @return, "</table>\n";
    push @return, $self->html_search($table, $params, $options)
		unless $$options{nodelsearch};
  } else {		
    my $action  = $self->_action($table, 'list', $params, $0);

    if (!$$options{'nocount'}) {
      push @return, "<caption align=top>";
      push @return, " Entries ", $first + 1, " - ",
                  ($entrycount < $last) ? $entrycount : $last,
                    " of $entrycount<br />";

      push @return, join(" \n",
           $self->_firstentry($action, $params, $first, $total, $entrycount) );
      push @return, " </caption>";

      push @return, "</table>\n";

      # Print the same info under the table
      push @return, "<center>", join("\n",
         $self->_firstentry($action, $params, $first, $total, $entrycount) ),
         "</center>";
    } else {  
      if ($entrycount > $total) {
        # Don't print count information, offer a 'search' option instead
        push @return, "<caption align=top>",
      	    " Entries ", $first + 1, " - ",
            ($entrycount < $last) ? $entrycount : $last, " of $entrycount<br />",
	    "</caption>";
        push @return, "</table>";
        push @return, 
         "<font size=+2><center>Narrow your search</center></font>";
        push @return, $self->html_search($table, $params, $options);
      } else { push @return, "</table>" }
    }
  }

  wantarray ? @return : join("\n", @return);
}

sub html_list_banner {
  my ($self, $table, $params, $options, @other ) = @_;
  my @ret = "<font size=+2><center>Matching entries in $table</center></font>";
  push @ret, html_list(@_);
  wantarray ? @ret : join("\n", @ret);
}


=item html_search( TABLE, PARAMS, OPTIONS )

Returns an HTML form containing the code necessary to search the database.
Submitting the form should invoke C<html_list()>.

Valid options for C<OPTIONS>:

  nosearchname	Don't include the 'search TABLE' bit at the top 
		of the search

=cut

sub html_search {
  my ($self, $table, $params, $options, @other) = @_;
  my $html = $self->html->{$table} || return undef; 
  my @return;
  push @return, "<center><font size=+2>Search $table</font></center>"
	unless $$options{'nosearchname'};
  push @return, <<EOL;
  <center> <FORM action='$0' method=post>
   <input type=hidden name=action value='list' />
   <input type=hidden name=table value=$table />
   @{[ $self->_replace($params || {}, $html->( $self, undef, 'search', 
			$options )) ]}
  </FORM> </center>
EOL
  wantarray ? @return : join("\n", @return);
}

=item html_edit ( TABLE, PARAMS, OPTIONS )

Returns an HTML form containing the code necessary to edit a database
entry.  Submitting the form should invoke C<html_update()>.

=cut

sub html_edit {
  my ($self, $table, $params, $options, @other) = @_;
  my $cgi = new CGI;
  return "" unless $table;
  my $html = $self->html->{$table} || return ""; 
  my $datahash = {};  my @return;
  foreach my $entry ($self->select($table, $params, undef) ) {
    $$entry{'replace'} = 1;
    my @list;  
    foreach ( keys %{$entry} ) {
      next unless $_ && $$entry{$_};
      push @list, $cgi->hidden("Old.$_", $$entry{$_});
    }
    my $id = $$entry{'ID'} || 0;
    push @return, <<EDIT;
<center><font size=+2>Edit item in $table</font>
<FORM action='$0' method=post>
 <input type=hidden name=action value='update' />
 <input type=hidden name=table value=$table />
 @{[ $cgi->hidden('ID', $$entry{ID}) ]}
 @list
 @{[ $self->_replace($entry, $html->( $self, $entry, 'update', $options )) ]}
</FORM>
</center>
EDIT
  }
  wantarray ? @return : join("\n", @return);
}

=item html_view ( TABLE, PARAMS, OPTIONS )

Returns an HTML form containing the code necessary to view an item in
without the formatting of the form - thus making it printable.  Relies on
HTML::FormRemove. 

=cut

sub html_view {
  my ($self, $table, $params, $options, @other) = @_;
  my $html = $self->html->{$table} || return ""; 
  my @html = "<form>";
  foreach my $entry ($self->select($table, $params, undef) ) {
    push @html , $self->_replace( $entry, $html->( $self, $entry, 'view',
			$options ) );
  }
  push @html, "</form>";
  
  my @return = RemoveFormValues(@html);
  
  wantarray ? @return : join("\n", @return);
}

=back

=head2 HTML Form Layout + Actions 

=over 4

=item html_delete ( TABLE, PARAMS, OPTIONS )

Offer a method of deleting items from the database.  Operates on two
levels: either returns an HTML form containing the code necessary to 
delete an item from the database, or actually does the work and returns 
some basic searching information.

The difference between the two actions is the value of the 'CONFIRM'
parameter.  If it's set, then delete, otherwise return message asking
whether you want to continue.

(Note that this is the least tested part of the code.)

=cut

sub html_delete {
  my ($self, $table, $params, $options, @other) = @_;
  my $id = $$params{'ID'} || 0;
  my @return;

  if ($$params{'CONFIRM'}) {			# Do the deletion

    if ( $self->delete($table, $params) ) {	# Deletion Successful
      push @return, "<center><h2>ID \#$id from $table deleted</h2></center>";
      push @return, $self->html_search($table, {}, $options, @other);

    } else {					# Deletion Unsuccessful
      push @return, "<center><h2>Deletion from $table failed</h2></center>";
      push @return, DBI->errstr;
      push @return, $self->html_actions($table, @other);
    }

  } else {					# Confirm the deletion first
    my @table = $id ? $self->select($table, { 'ID' => $id } )
		    : $self->select($table, $params);
    foreach my $entry ( @table ) {
      push @return, "<h2>Are you sure you want to delete this entry?</h2>";
      push @return, "<ul>";
      foreach (sort keys %{$entry}) { push @return, "<li>$_: $$entry{$_}"; }
      push @return, "</ul>";
      if ($id) {
	push @return, 
	  "<a href='$0?table=$table&action=Delete&CONFIRM=1&ID=$id'>Yes</a>";
      } else {
	my @items = "action=Delete";
	foreach ($self->key($table) ) {
	  push @items, join('=', $_, $$entry{$_} ) if $$entry{$_};
	}
	push @items, "CONFIRM=1";
	my $list = join '&', @items;
	push @return, "<a href='$0?table=$table&$list'>Yes</a>";
      }       
      push @return, "<a href='$0?table=$table&action=search'>No</a>", "<p>";
    }
  }
  wantarray ? join ("\n", @return) : @return;
}

=back

=head2 Actions 

Actions actually do work on the database

=over 4

=item html_update ( TABLE, PARAMS, OPTIONS )

Updates the items selected with C<PARAMS>.  The original items are
selected with "Old.FIELD" fields in C<PARAMS>.  Returns an C<html_list()>
of the appropriate values.

=cut

sub html_update {
  my ($self, $table, $params, $options, @other) = @_;
  my $id = $$params{'ID'} || 0;
  $options ||= {};  

  my $admin = $$options{'admin'} ? 1 : 0;

  my $checkhash = {};   
  foreach ($self->key($table)) { $$checkhash{$_} = $$params{"Old.$_"} } 
  my $hash = $id ? { 'ID' => $id } : $checkhash;

  my @return = "<font size=+2><center>Updating $table</center></font>";
  foreach my $entry ($self->select($table, $hash, undef) ){
    my $checkhash = {};   
    foreach ($self->key($table)) { $$checkhash{$_} = $$params{"Old.$_"} } 
    $$checkhash{'ID'} = $id ;
    if ( $self->update($table, $params, $checkhash, $admin) ) {
      push @return, "<center>Success!  Database updated</center>";
      push @return, $self->html_list($table, $params, $options, @other);
    } else {
      push @return, "<h2>Couldn't update $table - " .  
		$self->error || "Unknown error", "</h2>" ;
      push @return, $self->html_list($table, $checkhash, $options, @other);
    }
  }
  return wantarray ? @return : join("\n", @return);
}

=item html_insert ( TABLE, PARAMS, OPTIONS )

Adds an item into C<TABLE> based on C<PARAMS>.  Returns an
C<html_create()> of the same values, allowing you to add more entries
easily.

=cut

sub html_insert {
  my ($self, $table, $params, $options, @other) = @_;
  $options ||= {};  my $admin = $$options{'admin'} ? 1 : 0;
  my (@missing, $hash, @return);
  if ($self->insert($table, $params, $admin)) {
    push @return, "<center>Success!  Database updated with new entry</center>";
    push @return, $self->html_list($table, $params, $options, @other);
  } else { 
    push @return, "<h2>Couldn't insert into $table - " . 
			$self->error || "Unknown error" . "</h2>" ;
  }
  push @return, $self->html_create($table, {}, @other);
  return wantarray ? @return : join("\n", @return);
}

=back

=cut

=head2 Local Behaviour Management

One of the main goals of this module is to allow for programmers to
manipulate the behaviours of these HTML forms fairly easily.  This is
primarily taken care of through the use of the C<PARAMS> and C<OPTIONS>
hash references, which are referenced throughout the code.  

There are also a few functions to help manipulate the behaviour of the
code:

=over 4

=item action ( ACTION [, CODEREF] )

This function handles the list of actions available within C<make_html()>.  
The actions are contained by a private hash, where the keys are the action
names and the values are the code references to make the HTML and/or
perform the actions.  

If C<ACTION> is not offered, returns undef.  If it doesn't exist, and no
C<CODEREF> is offered, returns an empty string.  If C<CODEREF> is offered,
sets the code refence value to C<CODEREF> (regardless of whether the
action previously existed).  Regardless, returns the new code reference.

Note, all code references should take the standard parameters:

  CODEREF($self, $table, $params, $options, @other);

=cut

sub action { 
  my ($self, $action, $code) = @_;
  return undef unless $action;
  $action = lc $action;

  if ($code) {
    return undef unless ref $code;
    $ACTION{$action} = $code;
  }

  $ACTION{$action} || "";
}

=item remove_action ( ACTION [, ACTION [, ACTION [...]]] )

Removes C<ACTION> from the list of actions.  If multiple C<ACTION>s are
offered, removes them all.  Returns the number of successful removals.

=cut

sub remove_action { 
  my $self = shift;
  my $count = 0;
  foreach (@_) { if ($_ && $ACTION{$_}) { delete $ACTION{$_} && $count++ } }
  $count;
}

=back 

=cut

###############################################################################
### INTERNAL FUNCTIONS ########################################################
###############################################################################

### _html_select ( PARAMS, OPTIONS )
# Creates the hash for passing into select().  
sub _html_select {
  my ($self, $params, $options, @other) = @_;
  my $datahash = {};
  if ($params && ref $params) {
    foreach (keys %{$params}) {
      next unless defined($$params{$_});
      $$datahash{$_} = join("", "%", $$params{$_}, "%")
              if ( $$params{$_} =~ /\S/ ) ;
      $$datahash{$_} =~ s/^%\^//g if defined($$datahash{$_});
      $$datahash{$_} =~ s/\$%$//g if defined($$datahash{$_});
    }
  }
  $datahash;
}

### _action ( TABLE, ACTION [, ENTRY [, PROG ]] )
# Returns the HTML code necessary to invoke PROG to do ACTION on ENTRY in
# TABLE.  
sub _action {
  my ($self, $table, $action, $entry, $prog) = @_;
  return undef unless ($table && $action);
  $prog ||= $0;   $entry ||= {};
  
  my $select = $$entry{ID} ? "ID=$$entry{ID}"
			   : $self->_make_select_keys($table, $entry) || "";

  "$prog?action=$action&table=$table&$select";
}

### _firstentry ( ACTION, PARAMS, FIRST, TOTAL, COUNT )
# Create the "First 25 | Prev 25 | Next 25 | Last 25" links.
sub _firstentry {
  my ($self, $action, $params, $first, $total, $count) = @_;
  return "" if ($count <= $total);
  return "" unless ($params && ref $params);

  my @options = ( 0, $first - $total, $first + $total, $count - $total );
  my @labels  = qw( First Previous Next Last );

  my @return; 
  push @return, "<table align=center width=100%>", "<tr>";
  for (my $i = 0; $i < scalar @options; $i++) { 
    if (   ( $labels[$i] eq 'First'    && ! $first > 0 )
        || ( $labels[$i] eq 'Previous' && $first - $total < 0 )
	|| ( $labels[$i] eq 'Next'     && $first + $total > $count )
	|| ( $labels[$i] eq 'Last'     && $first + $total == $count ) ) {
      push @return, "<td width=25% align=center>",
		     " <i>$labels[$i] $total</i>", "</td>";
    } else { 
      push @return, "<td width=25% align=center>";
      push @return, " <FORM action='$0' method=post>";
      foreach (sort keys %{$params}) { 
        push @return, CGI->hidden($_, $$params{$_}) unless lc $_ eq 'first';
      }
      push @return, CGI->hidden('first', $options[$i]);
      push @return, CGI->submit( 'submit-number', "$labels[$i] $total" ) ;
      push @return, " </FORM>", "</td>";
    }
  }
  push @return, "</tr>", "</table>";
  
  wantarray ? @return : join(" ", @return);
}


### _make_select_keys ( TABLE, ENTRY )
# Help make the URL for searching for ENTRY, based on the keys for that
# TABLE.
sub _make_select_keys {
  my ($self, $table, $entry) = @_;
  my @items;
  foreach ($self->key($table) ) {
    next unless $_;
    my $val = $$entry{$_};  next unless defined $$entry{$_};  
    $val =~ s/%/\\%/g; 
    push @items, join('=', $_, $val);
  }
  join '&', @items;
}

1;
__DATA__

=head1 SHARED DATA STRUCTURES

The following data structions are considered public, and may be modified
by the running program as appropriate.

=over 4

=item @DBIx::Frame::ACTIONS

Determines which actions should be offered in C<html_actions()>.  

=back

=cut

=head1 NOTES

None of these items do any work to determine whether the user is allowed
to perform the actions that he's trying to do - this should be taken care
of when writing the CGI scripts and choosing which user can connect.  

Good class design is also important.  The C<KEY> values that you use must
guarantee that each item is unique!  If this is not done, then functions
like C<html_delete()> can wreak havoc on your tables.

=head1 REQUIREMENTS

Perl 5 or better, DBIx::Frame, and HTML::FormRemove.

=head1 SEE ALSO

B<DBI>, B<DBIx::Frame>, B<HTML::FormRemove>.

=head1 TODO

Fixing up the HTML::FormRemove thing would be nice, or else doing
something else with C<html_view()> (which I'm not altogether happy with).

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@ks.uiuc.edu>.

=head1 HOMEPAGE

B<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/>

=head1 LICENSE

This code is distributed under the University of Illinois Open Source
License.  See
C<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/license.html> for
details.

=head1 COPYRIGHT

Copyright 2000-2004 by the University of Illinois Board of Trustees and
Tim Skirvin <tskirvin@ks.uiuc.edu>.

=cut

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.9  	Fri Jul 13 10:51:18 CDT 2001
### Release candidate.  Internal documentation written, it seems modular.
# v0.91 	Tue Jul 17 11:48:09 CDT 2001
### Added 'Table Options' to the html_menu() in make_html()
# v0.92 	Fri Jul 27 09:34:10 CDT 2001
### Removed quotes from around the 'table'.  Fixed a bug in html_list()
# involving HTML tables.
# v0.93 	Thu Aug 16 12:09:47 CDT 2001
### Added actions() and its related functions, and modified make_html() for it
### Added support for 'useropts' in the list of OPTIONS for html_list()
### Standardized the 'actions' list in html_list()
### Added html_list_banner() for increased actions() support
# v0.94 	Fri Jan 25 13:58:07 CST 2002
### Fixed the "Next 25" thing to work on searches.
# v0.95 	Thu Feb 21 11:18:04 CST 2002
### Changed to UIUC/NCSA Open Source License - essentially the BSD license.
# v0.96	Tue Apr  2 13:35:03 CST 2002
### Fixed to work with with DBI::Frame 1.04
# v0.97 	Wed Aug 14 11:12:04 CDT 2002
### html_list_nosearch() split off to let other functions use it.  Added
### 'tdopts' as an option.  Updated _firstentry() to use whole forms instead 
### of links; this looks much better, and works better too.
# v0.98		Mon Oct  7 16:20:45 CDT 2002
### Actually using 'options' for various fields.
### Minor typographical fixes.
# v0.98.1	Wed Jan 15 14:56:45 CST 2003
### Added an 'option' of 'quiet', which is meant for displaying only the
### necessary information for the tables - ie, no 'Add to Register' text.  
### Only html_create uses it so far, we'll do more soon.
# v0.98.2	Fri Jan 17 13:03:45 CST 2003
### Using SelfLoader.  It might help.
### Trying to use the 'admin' field more appropriately.  Need more docs
### first. 
### Still need to match DBI::Frame's ADMIN, ORDER, REQUIRED fields
# v0.98.3	Thu Mar 27 14:19:29 CST 2003 
### Set 'nowrap' on the actions table field
# v0.98.4	Mon Oct 20 10:08:49 CDT 2003 
### html_search() now has a 'nosearchname' field.  Updated the
### documentation a bit for prettiness
# v1.00		Tue Oct 21 13:49:49 CDT 2003 
### Updated to be DBIx::Frame.  Updated for prettiness.
# v1.01.01	Mon May 17 11:01:57 CDT 2004 
### Small fix in html_create().  <br> -> <br />
# v1.01.02	Wed May 26 09:10:14 CDT 2004 
### Changes in _make_select_keys() to deal with '%' in the values better.
### Some fixes to make things closer to HTML4; more will have to come later.
