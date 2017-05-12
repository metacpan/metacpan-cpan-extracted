#!/bin/bash
# $DR is my web server's doc root.

pod2html.pl -i lib/DBIx/Admin/TableInfo.pm -o $DR/Perl-modules/html/DBIx/Admin/TableInfo.html
