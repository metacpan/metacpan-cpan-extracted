# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'errors' );
use strict;

print "Content-type: text/html\n\tand more\nSomething: else\n\n";
print "a1\n";


