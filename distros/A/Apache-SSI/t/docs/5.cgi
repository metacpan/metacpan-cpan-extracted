#!/usr/bin/perl
print "Content-type: text/html\n\n";
print "5; path_info: $ENV{'PATH_INFO'}; query_string: $ENV{'QUERY_STRING'};";
