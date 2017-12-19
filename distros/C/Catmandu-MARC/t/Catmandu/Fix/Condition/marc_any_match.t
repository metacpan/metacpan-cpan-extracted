#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::marc_any_match';
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

note 'marc_any_match(999,A)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_any_match(999,A) add_field(test,failed) end'
    );
    my $record = $importer->first;

    ok ! $record->{test} , 'ok matched nothing';
}

note 'marc_any_match(999,X)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_any_match(999,X) add_field(test,ok) end'
    );
    my $record = $importer->first;

    is $record->{test} , 'ok' , 'ok matched something'
}

note 'marc_any_match(999,[XYZ])';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'if marc_any_match(999,[XYZ]) add_field(test,ok) end'
    );
    my $record = $importer->first;

    is $record->{test} , 'ok' , 'ok matched something'
}

done_testing;
