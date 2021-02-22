#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Pure::Fast;
use HTTP::Headers;

# HTTP header.
my $header = HTTP::Headers->new;
$header->header('Content-Type' => 'text/html');

# FCGI script.
my $count = 1;
while (my $cgi = CGI::Pure::Fast->new) {
        print $header->as_string."\n";
        print $count++."\n";
}

# Output in CGI mode:
# Content-Type: text/html
# 
# 1
# ...
# Content-Type: text/html
# 
# 1
# ...

# Output in FASTCGI mode:
# Content-Type: text/html
# 
# 1
# ...
# Content-Type: text/html
# 
# 2
# ...