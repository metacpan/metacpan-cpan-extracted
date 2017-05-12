# -*-Perl-*-
BEGIN { unshift @INC, 'blib/lib' }
use CGI::Debug( report => 'errors', 
	    to => { file => "/tmp/a$$" },
	    set => { error_document => 'failed.html' });
use strict;


compile error!

print "Content-type: text/html\n\n";
print "a1\n";


