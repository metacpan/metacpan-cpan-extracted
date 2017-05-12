# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'params' );
use strict;

print "Content-type: text/html\n\n";
print "a1\n";
warn;

