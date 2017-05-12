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

print "1..3\n";

$n = 1;

$head = Data::Locations->new();  ##  E.g. for interface definitions
$body = Data::Locations->new();  ##  E.g. for implementation

$head->filename("example.h");
$body->filename("example.c");

$common = $head->new();    ##  Embed a new location in "$head"
$body->print($common);     ##  Embed this same location in "$body"

##  Create some more locations...

$copyright = Data::Locations->new();
$includes  = Data::Locations->new();
$prototype = Data::Locations->new();

##  ...and embed them in location "$common":

$common->print($copyright,$includes,$prototype);

##  Note that the above is just to show you an alternate
##  (but less efficient) way! Normally you would use:
##
##      $copyright = $common->new();
##      $includes  = $common->new();
##      $prototype = $common->new();

$head->println(";");  ##  The final ";" after a function prototype
$body->println();     ##  Just a newline after a function header

$body->println("{");
$body->println('    printf("Hello, world!\n");');
$body->println("}");

$includes->print("#include <");
$library = $includes->new();     ##  Nesting even deeper still...
$includes->println(">");

$prototype->print("void hello(void)");

$copyright->println("/*");
$copyright->println("    Copyright (c) 1997 - 2009 by Steffen Beyer.");
$copyright->println("    All rights reserved.");
$copyright->println("*/");

$library->print("stdio.h");

$copyright->filename("default.txt");

$txt = join('', $copyright->read());
$ref = <<'VERBATIM';
/*
    Copyright (c) 1997 - 2009 by Steffen Beyer.
    All rights reserved.
*/
VERBATIM

if ($txt eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$txt = join('', $head->read());
$ref = <<'VERBATIM';
/*
    Copyright (c) 1997 - 2009 by Steffen Beyer.
    All rights reserved.
*/
#include <stdio.h>
void hello(void);
VERBATIM

if ($txt eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$txt = join('', $body->read());
$ref = <<'VERBATIM';
/*
    Copyright (c) 1997 - 2009 by Steffen Beyer.
    All rights reserved.
*/
#include <stdio.h>
void hello(void)
{
    printf("Hello, world!\n");
}
VERBATIM

if ($txt eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$head->filename("");
$body->filename("");
$copyright->filename("");

__END__

