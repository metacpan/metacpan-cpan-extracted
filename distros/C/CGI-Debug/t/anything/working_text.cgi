# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'errors', on => 'anything' );
use strict;

print "Content-type: something/else\n\n";
print "a1\n";
