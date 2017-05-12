#!/bin/bash

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl
perl -Ilib scripts/populate.tables.pl
perl -Ilib scripts/report.tables.pl
perl -Ilib scripts/tree.pl -t two -v
perl -Ilib scripts/tree.pl -t two -c one
perl -Ilib scripts/tree.pl -t two -c one
perl -Ilib scripts/tree.pl -t one -s 1 -v
perl -Ilib scripts/tree.pl -t one -s 21 -v

