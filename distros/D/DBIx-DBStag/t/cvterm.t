use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 9;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

open(F, "t/data/chado-cvterm.sql") || die;
my $ddl = join('',<F>);
close(F);
drop();
my $dbh = connect_to_cleandb();
#DBI->trace(1);

$dbh->do($ddl);

my $chado  = Data::Stag->parse("t/data/test.chadoxml");
$dbh->storenode($_) foreach $chado->subnodes;
ok(1);
my $query =
q[
SELECT * 
FROM cvterm
 INNER JOIN dbxref ON (cvterm.dbxref_id = dbxref.dbxref_id)
 INNER JOIN db ON     (dbxref.db_id = db.db_id)
 INNER JOIN cv ON     (cvterm.cv_id = cv.cv_id)
WHERE
 cvterm.definition LIKE '%snoRNA%'
USE NESTING (set(cvterm(cv)(dbxref(db))))
];

my $termset =
  $dbh->selectall_stag($query);
print $termset->xml;
my @terms = $termset->get_cvterm;
ok(@terms,1);
my $term = shift @terms;
ok($term->sget_cv->sget_name eq 'biological_process');
ok($term->sget_dbxref->sget_db->sget_name eq 'GO');

# find parents of 'snoRNA'
$query =
q[
SELECT * 
FROM cvterm AS baseterm
 INNER JOIN cvterm_relationship AS r ON (r.subject_id=baseterm.cvterm_id)
 INNER JOIN cvterm AS parentterm      ON (r.object_id=parentterm.cvterm_id)
 INNER JOIN cvterm AS rtype          ON (r.type_id=rtype.cvterm_id)
WHERE
 baseterm.definition LIKE '%snoRNA%'
USE NESTING (set(baseterm(r(parentterm)(rtype))))
];

$termset =
  $dbh->selectall_stag(-sql=>$query,
                       -aliaspolicy=>'a');
my @parents = $termset->get('baseterm/r/parentterm');
ok(@parents == 1);

$termset =
  $dbh->selectall_stag(-sql=>$query,
                       -aliaspolicy=>'t');
@parents = $termset->get('cvterm/cvterm_relationship/cvterm');
#both child and parent are cvterm
ok(@parents == 2);

$termset =
  $dbh->selectall_stag(-sql=>$query);
@parents = $termset->get('baseterm/cvterm/r/cvterm_relationship/parentterm/cvterm');
ok(@parents == 1);

# this next test uses the new style of obo2chadoxml conversion
my $chado  = Data::Stag->parse("t/data/test2.chadoxml");
$dbh->storenode($_) foreach $chado->subnodes;
ok(1);

my ($genus) =
  $dbh->selectrow_array("SELECT cvterm.name FROM cvterm_genus INNER JOIN cvterm ON (genus_id=cvterm.cvterm_id)");
ok($genus eq 'a');

$dbh->disconnect;
