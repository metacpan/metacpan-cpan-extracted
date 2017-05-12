#!/usr/bin/env perl
use warnings;
use strict;
use Business::Address::POBox;
use Test::More;
use Test::Exception;
my @is_not_pobox = (
    'Post Road 123',
    'Post Rd 123',
    'Post Street 123',
    'Post St 123',
    'Post Avenue 123',
    'Post Av 123',
    'Post Alley 123',
    'Post Drive 123',
    'Post Grove 123',
    'Post Walk 123',
    'Post Parkway 123',
    'Post Row 123',
    'Post Lane 123',
    'Post Bridge 123',
    'Post Boulevard 123',
    'Post Square 123',
    'Post Garden 123',
    'Post Strasse 123',
    'Post Allee 123',
    'Post Gasse 123',
    'Post Platz 123',
    'Postsparkassenplatz 1',
    'Postelweg 5',
    'Boxgasse 32',
    'Postfachplatz 11',
    'PFalznerweg 91',
    'aPOSTelweg 12',
    'Prof. Dr. Stephan Koren-Strasse 10',
    'Pool Lane 123',
    'Pool Street 123',
    'An der alten Post 4',
    'An der Alten Post 4711',
    'Im Wirtshaus an der Post 7',
    'Pf-Karl-Platz 4',
    'Am Steinkopf 17',
    'Alte Post',
);

my @pobox_but_deliverable = (
    'Postgasse 11 Postfach 0815',
    'Universitaetsstrasse 3, PF 45',
    'Au 7, PF 3',
    'PO 37, Postgasse 5',
    'P.F. 37, Post Drive 9',
    'P.O. BOX 37, Post Drive 9',
    'Post Street, P.O.B.',
    'Postfach 41, 1023 Wien',
    'Postfach 41, 1023 Wien',
    'Prof. Mabuse P.O. Box',
    'Pool Box 123',
    'Post Gasse, Postlagernd',
    'Mein Postfach',
);

my @is_pobox = (
    'Box 123',
    'Pob',
    'Postbox',
    'Post',
    'Postschachtel',
    'P O',
    'P O BOX',
    'P.O.',
    'P.O.B.',
    'P.O.BOX',
    'P.O. BOX',
    'P. O.',
    'P. O.BOX',
    'P. O. BOX',
    'POBOX',
    'PF 123',
    'Pf-123',
    'POSTBUS',
    'Post Box 1234',
    'A Post',
);
plan tests => @is_not_pobox + @pobox_but_deliverable + @is_pobox;

for my $value (@is_not_pobox, @pobox_but_deliverable) {
    ok(!Business::Address::POBox->new->is_pobox($value),
        "value [$value] is not a pobox");
}
for my $value (@is_pobox) {
    ok(Business::Address::POBox->new->is_pobox($value),
        "value [$value] is a pobox");
}
