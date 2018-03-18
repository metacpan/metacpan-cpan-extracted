#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;
use Config::IniFiles::Slurp qw( slurp );

my $ors = $\ || "\n";
my ( $ini, $value );

#
# Delta tests added by D/DO/DOMQ
#

# test 1
# print "Import a file .................... ";
my $en = Config::IniFiles->new( -file => t_file('en.ini') );

# TEST
ok( $en, "En was instantiated." );

# test 2
my $es = Config::IniFiles->new( -file => t_file('es.ini'), -import => $en );

# TEST
ok( $es, "Es was instantiated." );

my $estext = slurp( t_file("es.ini") );
$estext =~ s/\s*//g;

# test 3
## Delta without any update should result in exact same file (ignoring
## distinctions about leading whitespace)
t_unlink('delta.ini');
$es->WriteConfig( t_file('delta.ini'), -delta => 1 );

my $deltatext = slurp( t_file('delta.ini') );
$deltatext =~ s/\s*//g;

# TEST
is( $deltatext, $estext,
    "Delta without any update should result in exact same file " );

t_unlink('delta.ini');

# test 4
## Delta with updates
$es->newval( "something", "completely", "different" );
$es->WriteConfig( t_file('delta.ini'), -delta => 1 );
$deltatext = slurp( t_file('delta.ini') );

# TEST
if (
    !ok(
        scalar( $deltatext =~ m/^[something].*completely=different/sm ),
        "Delta with updates",
    )
    )
{
    diag($deltatext);
}

t_unlink('delta.ini');

# test 5
## Delta with deletion marks
$es->delval( "x", "LongName" );
$es->DeleteSection("m");
$es->WriteConfig( t_file('delta.ini'), -delta => 1 );
$deltatext = slurp( t_file('delta.ini') );

# TEST
if (
    !ok(
        ( $deltatext =~ m/^. \[m\] is deleted/m )
            && ( $deltatext =~ m/^. LongName is deleted/m ),
        "Delta with deletion marks",
    ),
    )
{
    diag($deltatext);
}

# test 6
## Parsing back deletion marks

$es = Config::IniFiles->new( -file => t_file('delta.ini'), -import => $en );

# TEST
ok( ( !defined $es->val( "x", "LongName" ) ) && ( !$es->SectionExists("m") ),
    "Parsing back deletion marks" );
t_unlink("delta.ini");
