#!perl

# Run all tests against Apache mod_perl using a LocationMatch regex block
#
# Note, to get this to run properly, you may need to give it the path to your
# httpd.conf:
#
# perl t/optional/mod_perl-locationmatch.pl -httpd_conf /etc/apache/httpd.conf
#
# For debugging, you can start TestApp and leave it running with
# perl t/optional/mod_perl-locationmatch.pl -httpd_conf /etc/apache/httpd.conf --start-httpd
#
# To stop it:
# perl t/optional/mod_perl-locationmatch.pl -httpd_conf /etc/apache/httpd.conf --stop-httpd

use strict;
use warnings;

use Apache::Test;
use Apache::TestRunPerl ();

$ENV{CATALYST_SERVER} = 'http://localhost:8529/match/that';

Apache::TestRunPerl->new->run(@ARGV);
