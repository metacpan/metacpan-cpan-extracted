#!/usr/bin/perl
use strict;
use warnings;

# subroutine to upload any file (and prepare the multi-part version of it on the fly).
# For some reason you cannot run this function twice !?? What bug is this ?
# using local/plain.txt

use lib qw(lib t/lib);
use CGI::Upload;
use CGI::Upload::Test;
use Test::More tests => 6*1;

#upload_file("plain.txt");
$ENV{HTTP_USER_AGENT} = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.3) Gecko/20030312";
upload_file("plain.txt", {
           long_filename_on_client => '/tmp/plain.txt',
           short_filename_on_client => 'plain.txt',
		   });
ok($INC{"CGI.pm"}, "CGI.pm was loaded");

#upload_file("plain.txt");


