#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_paste';
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
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">Z</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC


note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl)'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-1],
        [ '002' , ' ' , ' ' , '_' , '   92005291 ' ]
        , 'marc_copy(001,cntrl)';
}


note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245)'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-3],
        [ '002' , ' ' , ' ' , '_' , '   92005291 ' ]
        , 'marc_copy(001,cntrl)';
}

note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245c)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245c)'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-3],
        [ '002' , ' ' , ' ' , '_' , '   92005291 ' ]
        , 'marc_copy(001,cntrl)';
}

note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245x)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245x)'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-3],
        [ '245' , '1' , '0' , 'a' , 'Title / ', 'c' , 'Name' ]
        , 'marc_copy(001,cntrl)';
}

note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245c,equals:Name)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245c,equals:Name)'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-3],
        [ '002' , ' ' , ' ' , '_' , '   92005291 ' ]
        , 'marc_copy(001,cntrl)';
}

note 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245,equals:"Title / Name")';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); set_field(cntrl.0.tag,002); marc_paste(cntrl,at:245,equals:"Title / Name")'
    );
    my $record = $importer->first;

    is_deeply $record->{record}->[-3],
        [ '002' , ' ' , ' ' , '_' , '   92005291 ' ]
        , 'marc_copy(001,cntrl)';
}

done_testing;
