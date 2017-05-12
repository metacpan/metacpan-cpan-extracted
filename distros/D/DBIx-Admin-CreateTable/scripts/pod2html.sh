#!/bin/bash
# $DR is my web server's doc root.

pod2html.pl -i lib/DBIx/Admin/CreateTable.pm -o $DR/Perl-modules/html/DBIx/Admin/CreateTable.html
