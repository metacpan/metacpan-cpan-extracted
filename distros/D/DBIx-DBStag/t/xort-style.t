use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 3;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

drop();
my $dbh = connect_to_cleandb();

my $f = "parts-schema.sql";
open(F, "t/data/$f") || die;
my $ddl = join('',<F>);
close(F);
$dbh->do($ddl);

$f = "parts-data.xml";
print "parsing..\n";
my $chado  = Data::Stag->parse("t/data/$f");
print "parsed; now storing..\n";
$dbh->storenode($_) foreach $chado->subnodes;

ok(1);
my $cset =
  $dbh->selectall_stag(q[
SELECT * 
FROM component
 LEFT OUTER JOIN part_of ON (component.component_id=part_of.object_id)
 LEFT OUTER JOIN component AS c2 ON (c2.component_id=part_of.subject_id)
USE NESTING (set(component(part_of(c2))))
]);
print $cset->xml;
my @cs = $cset->get_component;
ok(@cs,5);

$cset =
  $dbh->selectall_stag(q[
SELECT component.*
FROM component
 INNER JOIN part_of ON (component.component_id=part_of.subject_id)
 INNER JOIN component AS c2 ON (c2.component_id=part_of.object_id)
WHERE c2.name='1b'
]);

print $cset->xml;
my @names = sort $cset->find_name;
print "names=@names\n";
ok("@names", "1b-I 1b-II");

$dbh->disconnect;
