# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'empty_body' );
use strict;

print "Content-type: text/html\n\n";
