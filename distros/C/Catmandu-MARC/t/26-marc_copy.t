use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use Catmandu;

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

note 'marc_copy(001,cntrl)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(001,cntrl); retain_field(cntrl)'
    );
    my $record = $importer->first;
    is_deeply $record->{cntrl},
        [
            {
                tag => '001',
                ind1 => undef,
                ind2 => undef,
                content => "   92005291 "
            }
        ], 'marc_copy(001,cntrl)';
}

note 'marc_copy(245,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(245,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
            {
                tag => '245',
                ind1 => '1',
                ind2 => '0',
                subfields => [
                    { a => 'Title / '},
                    { c => 'Name' },
                ]
            }
        ], 'marc_map(245,title)';
}

note 'marc_copy(245a,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(245a,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
            {
                tag => '245',
                ind1 => '1',
                ind2 => '0',
                subfields => [
                    { a => 'Title / '},
                    { c => 'Name' },
                ]
            }
        ], 'marc_map(245a,title)';
}

note 'marc_copy(245x,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(245x,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
        ], 'marc_map(245x,title)';
}

note 'marc_copy(245a,title,equals:"Title / ")';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(245a,title,equals:"Title / "); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
        {
            tag => '245',
            ind1 => '1',
            ind2 => '0',
            subfields => [
                { a => 'Title / '},
                { c => 'Name' },
            ]
        }
        ], 'marc_map(245a,title,equals:"Title / ")';
}

note 'marc_copy(999,local)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(999,local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local},
        [
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'X'},
                    { a => 'Y'}
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'Z'}
                ]
            }
        ], 'marc_copy(999,local)';
}

note 'marc_copy(...,all)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_copy(...,all); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all},
        [
            {
                tag => 'LDR',
                ind1 => undef,
                ind2 => undef,
                content => "                        "
            },
            {
                tag => '001',
                ind1 => undef,
                ind2 => undef,
                content => "   92005291 "
            },
            {
                tag => '245',
                ind1 => '1',
                ind2 => '0',
                subfields => [
                    { a => 'Title / '},
                    { c => 'Name' },
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'X'},
                    { a => 'Y'}
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'Z'}
                ]
            }
        ], 'marc_copy(...,all)';
}


done_testing;
