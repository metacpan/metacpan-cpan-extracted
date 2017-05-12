#
# To see the HTML page associated to a test (mostly usefull if it fails),
# look in t/tmp/html/<test number>.html.
#
# Leak detection strategy:
# Run on RedHat
# Uncomment the loop around the test that needs testing
# Uncomment the ok() because it appear like slight leak, which is natural.
# Run the test. The numbers, except for the first two, must not change at all.
#
# $Header: /cvsroot/Catalog/Catalog/t/01catalog.t,v 1.7 1999/07/01 17:51:09 loic Exp $
#
use strict;

package main;

use vars qw($count);

use Test;
use Cwd;
use File::Path;

use Catalog::tools::cgi;
use Catalog::tools::tools;
use Catalog;

require "t/lib.pl";

#$::opt_verbose = 'mysql|normal';
$::opt_error_stack = 1;

conftest_generic();

plan test => 84;


mem_size();
{
    print "
#
# Initialize catalog
#
";
    my($cgi, $catalog, $t, $html);
    $catalog = Catalog->new();
    $cgi = Catalog::tools::cgi->new();
    $cgi->param('context' => 'csetup_confirm');
    $cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
    $t = $catalog->selector($cgi);
    ok($t =~ /has been setup/i, 1, "catalog setup failed");
    $catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print control panel
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'ccontrol_panel');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /catalog on table/i, 1, "print catalog control panel");
#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

print "
#
# Build demo table
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdemo');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "create urldemo table");

#$catalog->exec("drop table urldemo");
#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

my($catname);
#foreach $catname ('urltheme', 'urltheme2', 'urltheme3', 'urltheme4', 'urltheme5', 'urltheme6') 
foreach $catname ('urltheme')
{
mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

print "
#
# Build catalog first step, get editing form
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbuild');
$cgi->param('navigation' => 'theme');
$cgi->param('table' => 'urldemo');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "get insert form table");

#print STDERR size() . "\n";
#}

$html = $t;

print "
#
# Effectively build the catalog
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('tablename' => 'urldemo');
$cgi->param('name' => "$catname");
$cgi->param('navigation' => 'theme');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /$catname/i, 1, "create $catname catalog");

#
# For leak test, re-init
#$catalog->exec("delete from catalog where name = "$catname"");
#$catalog->exec("drop table catalog_entry2category_$catname");
#$catalog->exec("drop table catalog_category2category_$catname");
#$catalog->exec("drop table catalog_category_$catname");
#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the root of the catalog editing panel for $catname
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cedit');
$cgi->param('name' => "$catname");
$cgi->param('id' => '1');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /centryselect/i, 1, "catalog edit root");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();

foreach $count (1..5) {
print "
#
# Show the form for creating a catalog entry
#
";
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'categoryinsert');
$cgi->param('name' => "$catname");
$cgi->param('id' => '1');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /catalog_category_$catname/i, 1, "form to insert a category");

#print STDERR size() . "\n";
#}

$html = $t;

print "
#
# Effectively create the category
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('name' => "cat$count");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /cat$count/i, 1, "create category cat$count");
}

#$catalog->exec("delete from catalog_category_$catname where name like 'cat%'");
#$catalog->exec("delete from catalog_category2category_$catname");
#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

my($url) = 'a';
foreach $count (1..10) {

print "
#
# Insert form (record and link it to the category)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryinsert');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "insert/link entry$count form");

$html = $t;

print "
#
# Effectively create the entry
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('url' => $url);
$cgi->param('comment' => "My comment entry$count");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /my comment entry$count/i, 1, "insert link entry$count");
$catalog->close();

$url++;
}

#my($catalog) = Catalog->new();
#$catalog->exec("delete from catalog_entry2category_$catname");
#print STDERR size() . "\n";
#}
}
show_size();

mem_size();
{
print "
#
# Insert form (record and link it to the category) (page 2)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryinsert');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "insert/link entry11 form");

$html = $t;

print "
#
# Effectively create the entry (page 2)
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('url' => 'http://www.foo.com/');
$cgi->param('comment' => "My comment entry11");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /number of pages 2/i, 1, "insert link entry11 (page 2)");
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

foreach $count (1..5) {
my($tmp) = $count + 5;
print "
#
# Search form (link it to the category cat3)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryselect');
$cgi->param('name' => "$catname");
$cgi->param('id' => '4');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "insert/link entry$tmp form");

$html = $t;

print "
#
# Effectively link the entry to cat3
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html, '^fct_.*');
$cgi->param('context' => 'fct_return');
$cgi->param('table' => 'urldemo');
$cgi->param('rowid' => "$tmp");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /entry$tmp/i, 1, "link entry$tmp");
$catalog->close();
}

#my($catalog) = Catalog->new();
#$catalog->exec("delete from catalog_entry2category_$catname");
#print STDERR size() . "\n";
#}
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";

print "
#
# Print catalog category cat1, page 2
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cedit');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('page' => '2');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /my comment entry11/i, 1, "print category cat1 entry11 (page 2)");
$catalog->close();
#print STDERR size() . "\n";
#}
}
show_size();

mem_size();
{
print "
#
# Edit form for cat4
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'categoryedit');
$cgi->param('name' => "$catname");
$cgi->param('id' => '1');
$cgi->param('child' => '5');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /cat4/i, 1, "edit form for cat4");

$html = $t;

$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('name' => 'cat4 and more');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /and more/i, 1, "changing name of cat4");

$catalog->close();
}
show_size();

mem_size();
{

print "
#
# Remove category cat4
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'categoryremove');
$cgi->param('name' => "$catname");
$cgi->param('id' => '1');
$cgi->param('child' => '5');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t !~ /cat4/i && $t !~ /is not empty/, 1, "removing cat4");
$catalog->close();

}
show_size();

mem_size();
{

print "
#
# Unlink entry2
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryremove');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('row' => '2');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t !~ /entry2/i, 1, "unlink entry2");
$catalog->close();

}
show_size();

mem_size();
{
print "
#
# Edit form for entry3
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryedit');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('row' => '3');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /my comment entry3/i, 1, "edit form for entry3");

$html = $t;

$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('comment' => 'another comment');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /another comment/i, 1, "changing comment for entry3");

$catalog->close();
}
show_size();

mem_size();
{

print "
#
# Remove entry3 : confirmation
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'centryremove_all');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('row' => '3');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /confirm removal/i, 1, "removing entry3 confirmation");

$html = $t;

$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
my($row) = $catalog->db()->exec_select_one("select * from urldemo where comment like '%entry3%'");
ok($t !~ /entry3/i && !defined($row), 1, "removing entry3");

$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the category cat1 (user view)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('id' => '2');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /entry5/i, 1, "catalog browse category cat1");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Recalculate the count for each category
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$catalog->db()->exec("update catalog_category_$catname set count = 0 where rowid = 4");
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'category_count');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

my($row) = $catalog->db()->exec_select_one("select * from catalog_category_$catname where rowid = 4");
ok($row->{'count'}, 5, "counting category cat3");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Search for records
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'entry5');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t =~ /records matching/i &&
   $t =~ /entry5/, 1, "searching entry5");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Search for categories
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'cat1');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t =~ /categories matching/i &&
   $t =~ /cat1/, 1, "searching cat1");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Search failed
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => '+entry5 +cat1');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t =~ /no record matches/i, 1, "searching non existent");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Search failed for categories only
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'entry5');
$cgi->param('what' => 'categories');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t =~ /no category matches/i, 1, "searching non existent category");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Advanced query
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'cat3 or cat1');
$cgi->param('name' => "$catname");
$cgi->param('query_mode' => 'advanced');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t =~ m:/cat1/:i &&
   $t =~ m:/cat3/:i, 1, "searching cat1 cat3 using advanced syntax ");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Browsing mode is pathcontext
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'entry5');
$cgi->param('mode' => 'pathcontext');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t !~ /cbrowse/i &&
   $t !~ /cedit/i, 1, "searching in pathcontext mode");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Browsing mode is cedit
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'csearch');
$cgi->param('text' => 'entry5');
$cgi->param('mode' => 'cedit');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);

ok($t !~ /cbrowse/i &&
   $t =~ /cedit/i, 1, "searching in cedit mode");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
print "
#
# Dump the catalog (confirmation)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdump');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /Warning/, 1, "dumping catalog (confirmation)");

$html = $t;

print "
#
# Dump the catalog
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
mkpath("t/tmp/html/dump");
$cgi->param('path' => "t/tmp/html/dump");
$cgi->param('location' => "/location");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /dumped/, 1, "dumping catalog");

$catalog->close();
}
show_size();

mem_size();
{
print "
#
# Destroy catalog (confirmation)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdestroy');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /confirm removal/i, 1, "Destroy catalog (confirmation)");

print "
#
# Destroy catalog 
#
";
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdestroy_confirm');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
my(@tables) = grep(/$catname/, $catalog->db()->tables());
ok($t !~ /$catname/i, 1, "Destroy catalog");

$catalog->close();
}
show_size();

}

$catname = "urlalpha";

mem_size();
{

print "
#
# Build catalog alpha first step, get editing form
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbuild');
$cgi->param('navigation' => 'alpha');
$cgi->param('table' => 'urldemo');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "get insert form table");

$html = $t;

print "
#
# Effectively build the catalog alpha
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('tablename' => 'urldemo');
$cgi->param('name' => "$catname");
$cgi->param('fieldname' => 'url');
$cgi->param('navigation' => 'alpha');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /$catname/i, 1, "create $catname catalog");

$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog alpha root
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /t u v w/i &&
   $t =~ /letter=h/, 1, "catalog alpha browse root");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog alpha letter h
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('letter' => 'h');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /navigation h/i &&
   $t =~ /entry8/i &&
   $t =~ /entry11/, 1, "catalog alpha browse letter h");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Count entries
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$catalog->db()->exec("update catalog_alpha_urlalpha set count = 0");
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'calpha_count');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urlalpha/i, 1, "catalog alpha browse letter h");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog alpha root (to check count)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /t u v w/i &&
   $t =~ /letter=h/, 1, "catalog alpha browse root (to check count)");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
print "
#
# Destroy catalog (confirmation)
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdestroy');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /confirm removal/i, 1, "Destroy catalog (confirmation)");

print "
#
# Destroy catalog 
#
";
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cdestroy_confirm');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
my(@tables) = grep(/$catname/, $catalog->db()->tables());
ok($t !~ /$catname/i, 1, "Destroy catalog");

$catalog->close();
}
show_size();

$catname = "urldate";

mem_size();
{

print "
#
# Build catalog date first step, get editing form
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbuild');
$cgi->param('navigation' => 'date');
$cgi->param('table' => 'urldemo');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /urldemo/i, 1, "get insert form table");

$html = $t;

print "
#
# Effectively build the catalog date
#
";
$cgi = Catalog::tools::cgi->new();
param_snif($cgi, $html);
$cgi->param('tablename' => 'urldemo');
$cgi->param('name' => "$catname");
$cgi->param('fieldname' => 'created');
$cgi->param('navigation' => 'date');
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /$catname/i, 1, "create $catname catalog");

$catalog->close();
}
show_size();

{
    #
    # Change dates
    #
    my($catalog);
    $catalog = Catalog->new();
    my($i) = 1;
    my($date);
    foreach $date ('1997-02-02 10:10:10',
		  '1997-03-01 10:10:10',
		  '1998-04-30 10:10:10',
		  '1998-04-30 10:10:10',
		  '1998-05-08 10:10:10',
		  '1998-06-10 10:10:10',
		  '1998-07-01 10:10:10',
		  '1998-07-05 10:10:10',
		  '1998-08-15 10:10:10',
		  '1998-08-15 10:10:10',
		  '1998-08-15 10:10:10',
		  '1998-08-15 10:10:10',
		  '1998-08-15 10:10:10',
		  '1998-08-15 10:10:10') {
	$catalog->db()->exec("update urldemo set created = '$date' where rowid = $i");
	$i++;
    }
    $catalog->close();
}

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog date root
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /1998/i &&
   $t =~ /1997/, 1, "catalog date root");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog date root 1998
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('date' => "1998");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /1998/i &&
   $t !~ /1997/, 1, "catalog date root 1998");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog date root July 1998
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('date' => "199807");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /1998/i &&
   $t !~ /June/i &&
   $t !~ /1997/, 1, "catalog date root July 1998");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

mem_size();
{
#foreach (1..100) {
#print STDERR size() . " -> ";
print "
#
# Print the catalog date root July, 10 1998
#
";
my($cgi, $catalog, $t, $html);
$catalog = Catalog->new();
$cgi = Catalog::tools::cgi->new();
$cgi->param('context' => 'cbrowse');
$cgi->param('name' => "$catname");
$cgi->param('date' => "19980701");
$cgi->param('dump' => "t/tmp/html/catalog$Test::ntest.html");
$t = $catalog->selector($cgi);
ok($t =~ /1998/i &&
   $t =~ /July/i &&
   $t =~ /Wednesday/i &&
   $t !~ /June/i &&
   $t !~ /1997/, 1, "catalog date root July 10, 1998");

#print STDERR size() . "\n";
#}
$catalog->close();
}
show_size();

conftest_generic_clean();

# Local Variables: ***
# mode: perl ***
# End: ***
