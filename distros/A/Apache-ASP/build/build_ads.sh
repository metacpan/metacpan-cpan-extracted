#!/bin/bash

#perl ../cgi/asp -b -o ../site ./*.html
#perl /perl/bin/pod2text -80 < ../ASP.pm  > ../README

#perl ../cgi/asp -b -o ../site ./index.html ads 1 
perl ../asp-perl -b -o ../site ./index.html ads 1 ./*.html
touch ../site/apps/search/index.asp
rsync --delete --stats --exclude=CVS -a ../site/ /usr/local/proj/mlink/site/asp/
