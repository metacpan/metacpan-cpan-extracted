#!/usr/bin/perl
use strict;
use warnings;

# Try to imitate a windows client and a file name called "D:\0123.txt" as indicated in bug
# report #1854  http://rt.cpan.org/NoAuth/Bug.html?id=1854

use lib qw(lib t/lib);
use CGI::Upload;
use CGI::Upload::Test;

use Test::More tests => 5*1;

#$ENV{HTTP_USER_AGENT} = "Mozilla/4.7 [fr] (Win95; U)";
$ENV{HTTP_USER_AGENT} = 'Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)';
#,'4.01','MSIE','Win95',qw(ie ie4 ie4up windows win32 win95)
upload_file("plain.txt", {
      long_filename_on_client => 'c:\0123.txt',
      short_filename_on_client => '0123.txt',
});

