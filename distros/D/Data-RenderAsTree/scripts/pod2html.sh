#!/bin/bash

DIR=Perl-modules/html/Data
FILE=RenderAsTree.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Data/RenderAsTree.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
