#!perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Spelling';

Test::Spelling->import();

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
CGI
CPAN
CPANTS
FCGI
GPL
Init
ISPs
logdir
MetaCPAN
POSTing
RT
cgi
documentroot
http
https
params
param
stdin
tmpdir
Tmpdir
www
xml
iPad
