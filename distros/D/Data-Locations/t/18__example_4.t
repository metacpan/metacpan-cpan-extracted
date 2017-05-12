#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $toplocation = Data::Locations->new();
#   $sublocation = $location->new();
#   $location->print(@items);
#   $location->print($sublocation);
#   @list = $location->read();
# ======================================================================

print "1..3\n";

$n = 1;

$file = Data::Locations->new();

$rule = ('=' x 78);
$line = "$rule\n";

print $file $line;
print $file "example.h:\n";
print $file $line;

$head = $file->new();

print $file $line;
print $file "example.c:\n";
print $file $line;

$body = $file->new();

$common = $head->new();
$body->print($common);

$copyright = Data::Locations->new();
$includes  = Data::Locations->new();
$prototype = Data::Locations->new();

$common->print($copyright,$includes,$prototype);

$head->println(";");
$body->println();

$body->println("{");
$body->println('    printf("Hello, world!\n");');
$body->println("}");

$includes->print("#include <");
$library = $includes->new();
$includes->println(">");

$prototype->print("void hello(void)");

$copyright->println("/*");
$copyright->println("    Copyright (c) 1997 - 2009 by Steffen Beyer.");
$copyright->println("    All rights reserved.");
$copyright->println("*/");

$library->print("stdio.h");

$txt = join('', $file->read());
$ref = <<"VERBATIM";
$rule
example.h:
$rule
/*
    Copyright (c) 1997 - 2009 by Steffen Beyer.
    All rights reserved.
*/
#include <stdio.h>
void hello(void);
$rule
example.c:
$rule
/*
    Copyright (c) 1997 - 2009 by Steffen Beyer.
    All rights reserved.
*/
#include <stdio.h>
void hello(void)
{
    printf("Hello, world!\\n");
}
VERBATIM

if ($txt eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = '';
$file->traverse( sub { $str .= $_[0]; } );

if ($str eq $txt)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($str eq $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

