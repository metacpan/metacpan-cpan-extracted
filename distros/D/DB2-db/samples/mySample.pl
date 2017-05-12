#! /usr/bin/perl -w

use warnings;
use strict;

use My::db;

=head1 USAGE

Before using this sample, it is assumed that the database is created.
To create it locally, just run:

    perl -MMy::db -e 'My::db->create_db'

as someone who has authority to create databases.  Ensure that your
instance environment is set up properly beforehand!

=cut

my $tbl = My::db->new()->get_table('Employee');
my $row = $tbl->create_row();

$row->empno("000011");
$row->firstname("Michael");
$row->midinit("J");
$row->lastname("Fox");
$row->salary("500000.55");

$row->save();

$row = $tbl->create_row();

$row->empno("000015");
$row->firstname("Sharon");
$row->midinit("");
$row->lastname("Stone");
$row->salary("30.85");

$row = $tbl->create_row();

$row->empno("000021");
$row->firstname("Arnie");
$row->midinit("");
$row->lastname("Schwarz..etc.");
$row->salary("800");

undef $row;

$row = $tbl->find_id("000015");
printf("%s %s %s is employee number %s\n",
       $row->firstname(),
       $row->midinit(),
       $row->lastname(),
       $row->empno());

my @emps = $tbl->find_where('SALARY > 500');
print "The following employees make more than \$500:\n";
print join(', ',
           map {
               sprintf "%s %s %s", $_->firstname(), $_->midinit(), $_->lastname()
           } @emps
          );
print "\n";

my $prod_tbl = My::db->new()->get_table('Product');
$row = $prod_tbl->create_row();
$row->prodname('One Dum Movie');
$row->baseprice('1500');

$row->save();

