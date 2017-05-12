#!/usr/local/bin/perl -ws

use Coy;

@data = map { chomp; $_ } <DATA>;

print "Let 1000 haiku bloom....\n\n";

for (1..100)
{
	warn $_ foreach @data;
}

__DATA__
Fatal error - failed to allocate the requested memory. Maybe resize the heap?
Missing semicolon.
Bad argument
No such file: dummy.txt
Missing operator near "while"
Can't open input file
Syntax error near line 4
Connection timed out - aborting
Too many arguments to subroutine &print.
Can't generate new lines to match regular expression.
