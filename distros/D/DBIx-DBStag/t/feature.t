use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 5;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

unless ($ENV{DBSTAG_DEVELOPER_MODE}) {
    print "test feature.t takes a loooooong time, so I'm skipping it.\n";
    print "if you want to run this test, set env DBSTAG_DEVELOPER_MODE\n";
    ok(1) foreach (1..5);
    exit 0;
}

drop();
my $dbh = connect_to_cleandb();

foreach my $f (qw(chado-cvterm.sql
                  chado-pub.sql
                  chado-feature.sql
                  chado-fr.sql
                 )) {
    open(F, "t/data/$f") || die;
    my $ddl = join('',<F>);
    close(F);
    $dbh->do($ddl);
}

foreach my $f (qw(relationship.chado-xml
                  sofa.chado-xml
                  CG10833.with-macros.chado-xml)) {
    print "parsing..\n";
    my $chado  = Data::Stag->parse("t/data/$f");
    print "parsed; now storing..\n";
    $dbh->storenode($_) foreach $chado->subnodes;
}
ok(1);
my $fset =
  $dbh->selectall_stag(q[
SELECT * 
FROM feature
 LEFT OUTER JOIN dbxref ON (feature.dbxref_id = dbxref.dbxref_id)
 LEFT OUTER JOIN db ON     (dbxref.db_id = db.db_id)
 INNER JOIN cvterm AS ftype ON (feature.type_id = ftype.cvterm_id)
USE NESTING (set(feature(ftype)(dbxref(db))))
]);
print $fset->xml;
my @features = $fset->get_feature;
ok(@features,10);
my ($gene) = $fset->where(feature=>sub {
                              shift->find('cvterm/name') eq 'gene'
                          });
ok($gene->sget_name eq 'Cyp28d1');

$fset =
  $dbh->selectall_stag(q[
SELECT subf.* 
FROM feature
 INNER JOIN feature_relationship ON (feature.feature_id = feature_relationship.object_id)
 INNER JOIN feature AS subf      ON (subf.feature_id = feature_relationship.subject_id)
WHERE feature.name='Cyp28d1-RA'
]);
print $fset->xml;
@features = $fset->get_subf;
ok(@features,7);

$fset =
  $dbh->selectall_stag(q[
SELECT feature.* 
FROM feature
 INNER JOIN featureloc ON (feature.feature_id = featureloc.feature_id)
 INNER JOIN feature AS srcf ON (srcf.feature_id = featureloc.srcfeature_id)
WHERE srcf.uniquename='2L'
]);
@features = $fset->get_feature;
ok(@features,9);

$dbh->disconnect;
