# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'params', set => { param_length => 1 } );
use strict;

print "Content-type: text/html\n\n";
print "a1\n";
warn;

