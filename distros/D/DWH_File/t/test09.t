BEGIN { $| = 1; print "1..3\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

$loaded = 1;

eval { require 5.005 };
if ( $@ ) {
    print "1..0 # Skip This test requires at least perl 5.005\n";
    exit;
}

########################################################################
# Test array operations
#
# 
########################################################################

tie my %dwh, 'DWH_File', '_test_04', O_RDWR | O_CREAT, 0644;

# arrays set up in test07.t:
#$dwh{ later } = [
#        [ qw( en yndig og frydefuld sommertid ) ],
#        [ qw( jeg kan se paa dine oejne ) ],
#        [ qw( og granerne duppes ) ]
#    ];

####### 1 ######

push @{ $dwh{ later }->[ 0 ] }, qw( i al sin herlighed );

if ( @{ $dwh{ later }->[ 0 ] } == 9 and
     $dwh{ later }->[ 0 ]->[ 0 ] eq 'en' and
     $dwh{ later }->[ 0 ]->[ 3 ] eq 'frydefuld' and
     $dwh{ later }->[ 0 ]->[ 2 ] eq 'og' and
     $dwh{ later }->[ 0 ]->[ 4 ] eq 'sommertid' and
     $dwh{ later }->[ 0 ]->[ 5 ] eq 'i' and
     $dwh{ later }->[ 0 ]->[ 1 ] eq 'yndig' and
     $dwh{ later }->[ 0 ]->[ 7 ] eq 'sin' and
     $dwh{ later }->[ 0 ]->[ 6 ] eq 'al' and
     $dwh{ later }->[ 0 ]->[ 8 ] eq 'herlighed' ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

####### 2 #######

unshift @{ $dwh{ later }->[ 2 ] }, qw( naar egene knoppes );

if ( @{ $dwh{ later }->[ 2 ] } == 6 and
     $dwh{ later }->[ 2 ]->[ 0 ] eq 'naar' and
     $dwh{ later }->[ 2 ]->[ 1 ] eq 'egene' and
     $dwh{ later }->[ 2 ]->[ 2 ] eq 'knoppes' and
     $dwh{ later }->[ 2 ]->[ 3 ] eq 'og' and
     $dwh{ later }->[ 2 ]->[ 4 ] eq 'granerne' and
     $dwh{ later }->[ 2 ]->[ 5 ] eq 'duppes' ) {
    print "ok 2\n";
}
else { print "not ok 2\n" }

####### 3 #######

my $t = shift @{ $dwh{ later }->[ 1 ] };

if ( @{ $dwh{ later }->[ 1 ] } == 5 and
     $dwh{ later }->[ 1 ]->[ 0 ] eq 'kan' and
     $dwh{ later }->[ 1 ]->[ 1 ] eq 'se' and
     $dwh{ later }->[ 1 ]->[ 2 ] eq 'paa' and
     $dwh{ later }->[ 1 ]->[ 3 ] eq 'dine' and
     $dwh{ later }->[ 1 ]->[ 4 ] eq 'oejne' ) {
    print "ok 3\n";
}
else { print "not ok 3\n" }

untie %dwh;
