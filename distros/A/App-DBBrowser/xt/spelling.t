use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Spelling;


add_stopwords( <DATA> );

all_pod_files_spelling_ok( 'bin', 'lib' );



__DATA__
BNRY
PrintTable
Colwidth
Ctrl
Kiem
Lk
Matthäus
ProgressBar
Sssc
Tabwidth
compat
repexp
stackoverflow
ENV
Pg
Cols
Multirow
csv
sql
substatement
IFS
RaiseError
Subqueries
subqueries
subquery
substatement
MERCHANTIBILITY
