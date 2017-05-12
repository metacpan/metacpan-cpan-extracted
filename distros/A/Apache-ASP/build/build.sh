#!/bin/bash

pod2text -80 < ../ASP.pm  > ../README
#perl ../asp-perl -b -o ../site ./install.html ./sites.html
perl ../asp-perl -b -o ../site ./*.html
