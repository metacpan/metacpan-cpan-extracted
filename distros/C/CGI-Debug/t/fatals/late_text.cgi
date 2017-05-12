# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'errors' );
use strict;

print "Content-type: something/strange\n\n";
print "a1\n";
die;

