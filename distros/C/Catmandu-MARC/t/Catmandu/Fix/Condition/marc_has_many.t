#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::marc_has_many';
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

note 'marc_has_many(001)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_has_many(001) add_field(test,failed) end'
    );
    my $record = $importer->first;

    ok ! $record->{test} , 'ok no match';
}

note 'marc_has_many(999)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_has_many(999) add_field(test,ok) end'
    );
    my $record = $importer->first;

    is $record->{test} , "ok" , 'ok match';
}

note 'marc_has_many(998a)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_has_many(998a) add_field(test,ok) end'
    );
    my $record = $importer->first;

    is $record->{test} , "ok" , 'ok match';
}

note 'marc_has_many(998b)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_has_many(998b) add_field(test,failed) end'
    );
    my $record = $importer->first;

    ok ! $record->{test} , 'ok no match';
}

done_testing;
