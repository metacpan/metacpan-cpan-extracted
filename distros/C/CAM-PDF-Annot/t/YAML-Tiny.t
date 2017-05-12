# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CAM-PDF-Annot-Parsed.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('CAM::PDF::Annot::Parsed') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

package MyParser;
use base qw(YAML::Tiny);

sub parse {
    return shift->read_string( shift )->[0];
}

1;

package main;
my $pkg = 'CAM::PDF::Annot::Parsed';

my $pdf = $pkg->new( 't/pdf-yaml-tiny.pdf', 'MyParser' );

ok( $pdf, 'Constructor test' );

my $parsed_annots = $pdf->getParsedAnnots( 1 );

ok( $parsed_annots, 'getParsedAnnots' );

# the annotation contained in the test document is a sample taken from
# the get started section of yaml.org
#invoice: 34843
#date   : 2001-01-23
#bill-to:
#    given  : Chris
#    family : Dumars
#    address:
#        lines: |
#            458 Walkman Dr.
#            Suite #292
#        city    : Royal Oak
#        state   : MI
#        postal  : 48046
#product:
#    - sku         : BL394D
#      quantity    : 4
#      description : Basketball
#      price       : 450.00
#    - sku         : BL4438H
#      quantity    : 1
#      description : Super Hoop
#      price       : 2392.00
#tax  : 251.42
#total: 4443.52
#comments: >
#    Late afternoon is best.
#    Backup contact is Nancy
#    Billsmer @ 338-4338.
#

ok($parsed_annots->[0]{'bill-to'}{'given'} eq 'Chris', 'Parsed 1 result');
ok($parsed_annots->[0]{'product'}[0]{'sku'} eq 'BL394D', 'Parsed 2 result');
ok($parsed_annots->[0]{'total'} == 4443.52, 'Parsed 3 result');

