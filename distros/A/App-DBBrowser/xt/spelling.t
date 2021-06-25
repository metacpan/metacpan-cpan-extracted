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
de
Dir
ENV
eol
IFS
Kiem
mappable
Matthäus
MERCHANTIBILITY
Multirow
Pg
preselected
preselection
PrintTable
ProgressBar
RaiseError
repexp
schemas
Schemas
SGR
SQ
sql
stackoverflow
subqueries
Subqueries
subquery
substatement
substatements
Substatements
Tabwidth
