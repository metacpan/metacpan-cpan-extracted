#! /usr/bin/perl -w

# CGI-Ajax: example script 'pjx_combo.pl'
#
# INSTALL: place in an apache location that can execute perl scripts
#
# this script demonstrates a set of dynamic select boxes, where the
# selection in a box changes other select box contents, or html div
# values.  The data in each select box comes from the data anonymous
# hash, but could just as easily come from a database connection, etc.
#
# N.B. this requires CGI__Ajax version >=0.49
#
# Also, this example has lots of stderr output, so follow your apache
# log files to see what's going on.
#
use strict;
use CGI::Ajax 0.49;
use CGI;
use vars qw( $data );

# This is our data - top level keys get put in the leftmost select
# box, next level of keys get the second select box.  Values will end
# up in the resultdiv html element
$data = {
  'A' => { '1' => "A1", '2' => "A2", '3' => "A3", '42' => "A42" },
  'B' => { 'green' => "Bgreen", 'red' => "Bred" },
  'something' => { 'firefly' => "great show" },
  'final_thing' => { 'email' => "chunkeylover53", 'name' => "homer",
                     'address' => "742 Evergreen Terrace" }
};

my $q = new CGI;  # need a new CGI object

# compose our list of functions to export to js
my %hash = ( 'SetA'         => \&set_listA,
             'SetB'         => \&set_listB,
             'ShowResult'   => \&show_result );

my $pjx = CGI::Ajax->new( %hash ); # this is our CGI::Ajax object
$pjx->js_encode_function('encodeURIComponent');

$pjx->DEBUG(1);   # turn on debugging
$pjx->JSDEBUG(1); # turn on javascript debugging, which will place a
                  #  new div element at the bottom of our page showing
                  #  the asynchrously requested URL

print $pjx->build_html( $q, \&Show_HTML ); # this builds our html
                                           #  page, inserting js

# This subroutine is responsible for outputting the HTML of the web
# page.  Note that I've added an additional javascript function to
# erase/reset contents.  This prevents strange effects from
# overwriting a div without clearing it out first.
sub Show_HTML {
  my $html = <<EOT;
<HTML>
<HEAD><title>Combo Example</title>
<SCRIPT>

// define some reset functions to properly clear out the divs
function resetdiv( ) {
  if ( arguments.length ) {
    // reset a specific div
    for(var i = 0; i < arguments.length; i++ ) {
      document.getElementById(arguments[i]).innerHTML = "";
    }
  } else {
    // just reset all the divs
    document.getElementById("listAdiv").innerHTML = "";
    document.getElementById("listBdiv").innerHTML = "";
    document.getElementById("resultdiv").innerHTML = "";
  }
}

</SCRIPT>

</HEAD>
<BODY onload="resetdiv(); SetA([],['listAdiv']); return true;" >
<form>
        <div id="listAdiv"></div>
        <div id="listBdiv"></div>
        <div id="resultdiv" style="border: 1px solid black; width: 240px; height: 80px; overflow: auto">
        </div>
  <input type="text" name="textfield">
  <input type="submit" name="Submit" value="Submit" 

  </form>
</BODY>
</HTML>
EOT

  return($html);
}

# these are my exported functions - note that set_listA and set_listB
# are just returning html to be inserted into their respective div
# elements.
sub set_listA {
  # this is the returned text... html to be displayed in the div
  # defined in the javascript call
  my $txt = qq!<select id="listA" name="listA_name" size=3!;
  $txt .= qq! onclick="resetdiv('resultdiv'); SetB( ['listA'], ['listBdiv'] ); return true;">!;
  # get values from $data, could also be a db lookup
  foreach my $topval ( keys %$data ) {
    $txt .= '<option value='. $topval . '>'.  $topval .' </option>';
  }
  $txt .= "</select>";
  print STDERR "set_listA:\n";
  print STDERR "returning $txt\n";
  return($txt);
}

sub set_listB {
  my $listA_selection = shift;
  print STDERR "set_listB: received $listA_selection .\n";

  # this is the returned text... html to be displayed in the div
  # defined in the javascript call
  my $txt = qq!<select multiple id="listB" name="listB_name" size=3 style="width: 140px"!; 
  $txt .= qq! onclick="ShowResult( ['listA','listB'], ['resultdiv'] ); return true;">!;

  # get values from $data, could also be a db lookup
  foreach my $midval ( keys %{ $data->{ $listA_selection } } ) {
    $txt .= '<option value=' . $midval . '>' . $midval . "</option>";
  }
  $txt .= "</select>";
  print STDERR "set_listB:\n";
  print STDERR "returning $txt\n";
  return($txt);
}

sub show_result {
  my $listA_selection = shift;
  my $txt = "";
  # this loop is needed in case the user selected multiple elements in
  # the second select box, listB
  while ( @_ ) {
    my $in = shift;
    $txt .= $data->{ $listA_selection }->{ $in } . "<br>";
  }

  print STDERR "show_result - returning txt with value: $txt\n";
  return( $txt );
}

