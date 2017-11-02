#!/bin/bash

echo Running drop.tables.pl, create.tables.pl and populate.tables.pl

perl -Ilib scripts/drop.tables.pl -v
perl -Ilib scripts/create.tables.pl -v
perl -Ilib scripts/populate.tables.pl -v

echo Done
