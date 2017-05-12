#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $toplocation = Data::Locations->new();
#   $sublocation = $location->new();
#   $location->filename($filename);
#   $location->print(@items);
#   $location->print($sublocation);
#   @list = $location->read();
# ======================================================================

print "1..1\n";

$n = 1;

$html = Data::Locations->new("example.html");

$html->println("<HTML>");
$head = $html->new();
$body = $html->new();
$html->println("</HTML>");

$head->println("<HEAD>");
$tohead = $head->new();
$head->println("</HEAD>");

$body->println("<BODY>");
$tobody = $body->new();
$body->println("</BODY>");

$tohead->print("<TITLE>");
$title = $tohead->new();
$tohead->println("</TITLE>");

$tohead->print('<META NAME="description" CONTENT="');
$description = $tohead->new();
$tohead->println('">');

$tohead->print('<META NAME="keywords" CONTENT="');
$keywords = $tohead->new();
$tohead->println('">');

$tobody->println("<CENTER>");

$tobody->print("<H1>");
$tobody->print($title);      ##  Re-using this location!!
$tobody->println("</H1>");

$contents = $tobody->new();

$tobody->println("</CENTER>");

$title->print("'Data::Locations' Example HTML-Page");

$description->println("Example for generating HTML pages");
$description->print("using 'Data::Locations'");

$keywords->print("locations, magic, insertion points,\n");
$keywords->print("nested, recursive");

$contents->println("This page was generated using the");
$contents->println("<P>");
$contents->println("&quot;<B>Data::Locations</B>&quot;");
$contents->println("<P>");
$contents->println("module for Perl.");

$txt = join('', $html->read());
$ref = <<'VERBATIM';
<HTML>
<HEAD>
<TITLE>'Data::Locations' Example HTML-Page</TITLE>
<META NAME="description" CONTENT="Example for generating HTML pages
using 'Data::Locations'">
<META NAME="keywords" CONTENT="locations, magic, insertion points,
nested, recursive">
</HEAD>
<BODY>
<CENTER>
<H1>'Data::Locations' Example HTML-Page</H1>
This page was generated using the
<P>
&quot;<B>Data::Locations</B>&quot;
<P>
module for Perl.
</CENTER>
</BODY>
</HTML>
VERBATIM

if ($txt eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$html->filename("");

__END__

