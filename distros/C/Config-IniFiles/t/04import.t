#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my $ors = $\ || "\n";

my ($ini,$value);

#
# Import tests added by JW/WADG
#

# test 1
# print "Import a file .................... ";
my $en = Config::IniFiles->new( -file => t_file('en.ini') );
# TEST
ok ($en, "IniEn was initialized." );

# test 2
my $es = Config::IniFiles->new( -file => t_file('es.ini'), -import => $en );
# TEST
ok( $es, "Ini es was initialized." );


# test 3
# Imported values are good
my $en_sn = $en->val( 'x', 'ShortName' );
my $es_sn = $es->val( 'x', 'ShortName' );
my $en_ln = $en->val( 'x', 'LongName' );
my $es_ln = $es->val( 'x', 'LongName' );
my $en_dn = $en->val( 'm', 'DataName' );
my $es_dn = $es->val( 'm', 'DataName' );

# TEST
is ($en_sn, 'GENERAL', "en_sn is GENERAL");

# TEST
is ($es_sn, 'GENERAL', "es_sn is GENERAL too");

# TEST
is ($en_ln, 'General Summary', "en_ln is OK.");

# TEST
is ($es_ln, 'Resumen general', "es_ln is in Spanish");

# TEST
is ($en_dn, 'Month', "dn is in English");

# TEST
is ($es_dn, 'Mes', "es_dn is in Spanish");

# test 4
# Import another level
my $ca = Config::IniFiles->new( -file => t_file('ca.ini'), -import => $es );

# TEST
is ($en_sn, $ca->val( 'x', 'ShortName' ), "en_sn is OK.");
# TEST
is ($es_sn, $ca->val( 'x', 'ShortName' ), "es_sn is OK.");
# TEST
is ($ca->val( 'x', 'LongName' ), 'Resum general', "LongName is OK.");
# TEST
is ($ca->val( 'm', 'DataName' ), 'Mes', "DateName is OK.");

# test 5
# Try creating a config file that imports from a hand-built object
my $ini_a = Config::IniFiles->new();
$ini_a -> AddSection('alpha');
$ini_a -> AddSection('x');
$ini_a -> newval('x', 'x', 1);
$ini_a -> newval('x', 'LongName', 1);
$ini_a -> newval('m', 'z', 1);
# TEST
is ($ini_a->val('x', 'x'), 1, "x/x");

# TEST
is ($ini_a->val('x', 'LongName'), 1, "x/LongName");

# TEST
is ($ini_a->val('m', 'z'), 1, "m/z");

# test 6
## show that importing a file-less object into a file-based one works
my $ini_b = Config::IniFiles->new( -file=>t_file('ca.ini'), -import=>$ini_a );
# TEST
is ($ini_b->val('x', 'LongName'), 'Resum general', "x/Longname");
# TEST
is ($ini_b->val('x', 'x', 0), 1, "x/x");
# TEST
is ($ini_b->val('m', 'z', 0), 1, "m/z");
# TEST
is ($ini_b->val('m', 'LongName'), 'Resum mensual', "m/LongName");
