use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Spelling;

set_spell_cmd('aspell list -l en -p /dev/null');

add_stopwords( <DATA> );

all_pod_files_spelling_ok( 'bin', 'lib' );



__DATA__
AVG
BNRY
Cols
Colwidth
csv
Ctrl
Dir
ENV
eol
IFS
Kiem
MERCHANTIBILITY
Matthäus
Multirow
Pg
PrintTable
ProgressBar
RaiseError
repexp
SGR
SQ
sql
stackoverflow
Subqueries
subqueries
subquery
substatement
Substatements
Tabwidth
Schemas
de
mappable
preselected
schemas
