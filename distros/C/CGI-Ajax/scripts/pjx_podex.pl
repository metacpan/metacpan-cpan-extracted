#!/usr/bin/perl -w
use strict;
use CGI::Ajax;
use CGI;

# define an anonymous perl subroutine that you want available to
# javascript on the generated web page.

my $evenodd_func = sub {
  my $input = shift;

  my $magic = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font size=-1>look ma, no submit!</font><br>";
  
  # see if input is defined
  if ( not defined $input ) {
    return("input not defined or NaN" . $magic);
  }

  # see if value is a number (*thanks Randall!*)
  if ( $input !~ /\A\d+\z/ ) {
    return("input is NaN" . $magic);
  }

  # got a number, so mod by 2
  $input % 2 == 0 ? return("$input is EVEN" . $magic) : return("$input is ODD" . $magic);

}; # don't forget the trailing ';', since this is an anon subroutine

# define a function to generate the web page - this can be done
# million different ways, and can also be defined as an anonymous sub.
# The only requirement is that the sub send back the html of the page.
sub Show_HTML {
  my $html = "";
  $html .= <<EOT;

<HTML>
<HEAD><title>CGI::Ajax Example</title>
</HEAD>
<BODY>
<form>
  Enter a number:&nbsp;
  <input type="text" name="val1" id="val1" size="6"
     onkeyup="evenodd( ['val1'], ['resultdiv'] ); return true;"><br>
    <hr>
    <div id="resultdiv" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>
</form>
</BODY>
</HTML>
EOT

  return $html;
}

my $cgi = new CGI();  # create a new CGI object
# now we create a CGI::Ajax object, and associate our anon code
my $pjx = new CGI::Ajax( 'evenodd' => $evenodd_func );

# now print the page.  This can be done easily using
# CGI::Ajax->build_html, sending in the CGI object to generate the html
# header.  This could also be done manually, and then you don't need
# the build_html() method
print $pjx->build_html($cgi,\&Show_HTML); # this outputs the html for the page

# that's it!

