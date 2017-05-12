#!/bin/bash

perl scripts/stopwordlists.report.pl > html/stopwordlists.report.html

# $DR is my web server's docroot in Debian's RAM disk.

cp html/stopwordlists.report.html $DR/Perl-modules/html

cp html/stopwordlists.report.html ~/savage.net.au/Perl-modules/html
