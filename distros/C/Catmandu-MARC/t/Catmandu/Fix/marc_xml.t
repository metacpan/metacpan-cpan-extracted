#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_xml';
    use_ok $pkg;
}

require_ok $pkg;

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:controlfield tag="001">   92005291 </marc:controlfield>
        <marc:datafield ind1="1" ind2="0" tag="245">
            <marc:subfield code="a">Title / </marc:subfield>
            <marc:subfield code="c">Name</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="998">
            <marc:subfield code="a">X</marc:subfield>
            <marc:subfield code="a">Y</marc:subfield>
            <marc:subfield code="b">Z</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">X</marc:subfield>
            <marc:subfield code="a">Y</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">Z</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC

note 'marc_xml(record)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_xml(record)'
    );
    my $record = $importer->first;

    like $record->{record} , qr/^<marc:record/, 'ok  match';
}

note 'marc_xml(record2)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'copy_field(record,record2); marc_xml(record2)'
    );
    my $record = $importer->first;

    like $record->{record2} , qr/^<marc:record/, 'ok  match';

    is $record->{record}->[0]->[0] , 'LDR' , 'still have a record';
}

note 'marc_xml(record2)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'move_field(record,record2); marc_xml(record2)'
    );
    my $record = $importer->first;

    like $record->{record2} , qr/^<marc:record/, 'ok  match';

    ok ! $record->{record} , 'still have a record';
}

note 'marc_xml(record,reverse:1)';
{
    my $fixer = Catmandu::Fix->new(fixes =>
            [q|marc_xml(record,reverse:1)|]
    );
    my $result = $fixer->fix({ record => $mrc });

    ok $result , 'got a result';

    is ref($result->{record}) , 'ARRAY' , 'got an array';

    is $result->{record}->[0]->[0], 'LDR' , 'smells like marc';
}

done_testing;
