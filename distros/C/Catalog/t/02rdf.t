#
# $Header: /cvsroot/Catalog/Catalog/t/02rdf.t,v 1.6 1999/05/31 18:33:08 loic Exp $
#
use strict;

use Test;

require "t/lib.pl";

plan test => 2;

conftest_generic();
create_catalogs();

my($catname) = 'urltheme';

#$::opt_verbose = 'normal';
#$::opt_fake = 1;

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Import RDF file
#
";
my($catalog) = Catalog->new();
$catalog->cimport_api($catname, "t/rdf/guide.rdf");
my($count) = $catalog->db()->exec_select_one("select count(*) as count from urldemo")->{'count'};
ok($count == 18, 1, "import t/rdf/guide.rdf $count records in urldemo instead of 18");
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Export RDF file
#
";
my($catalog) = Catalog->new();
$catalog->cexport_api($catname, "t/tmp/guide.rdf");
system("perl -pi -e 's/.*modified>.*//s;' t/tmp/guide.rdf");
system("diff t/tmp/guide.rdf t/rdf/guide.rdf >/dev/null 2>&1");
ok($?, 0, "export t/tmp/guide.rdf different from t/rdf/guide.rdf");
$catalog->close();
}
show_size();

conftest_generic_clean();

# Local Variables: ***
# mode: perl ***
# End: ***
