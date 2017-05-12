#!/bin/sh
perl -d:NYTProf script/profile.pl
nytprofhtml
