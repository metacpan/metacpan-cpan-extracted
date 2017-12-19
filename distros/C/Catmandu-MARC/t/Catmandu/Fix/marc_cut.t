#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_cut';
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

note 'marc_cut(001,cntrl)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(001,cntrl)'
    );
    my $record = $importer->first;

    is_deeply $record->{cntrl},
        [
            {
                tag => '001',
                ind1 => ' ',
                ind2 => ' ',
                content => "   92005291 "
            }
        ], 'marc_cut(001,cntrl)';

    ok ! marc_has($record,'001') , '001 deleted';
}

note 'marc_cut(245,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(245,title)'
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

    ok ! marc_has($record,'245') , '245 deleted';
}

note 'marc_cut(245a,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(245a,title)'
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
    ok ! marc_has($record,'245') , '245 deleted';
}

note 'marc_cut(245x,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(245x,title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
        ], 'marc_map(245x,title)';
    ok marc_has($record,'245') , '245 still exists';
}

note 'marc_cut(245a,title,equals:"Title / ")';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(245a,title,equals:"Title / ");'
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
    ok ! marc_has($record,'245') , '245 deleted';
}

note 'marc_cut(999,local)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(999,local)'
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
        ], 'marc_cut(999,local)';
    ok ! marc_has($record,'999') , '999 deleted';
}

note 'marc_cut(...,all)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_cut(...,all);'
    );
    my $record = $importer->first;
    is_deeply $record->{all},
        [
            {
                tag => 'LDR',
                ind1 => ' ',
                ind2 => ' ',
                content => "                        "
            },
            {
                tag => '001',
                ind1 => ' ',
                ind2 => ' ',
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
        ], 'marc_cut(...,all)';

    is_deeply $record->{record} , [] , 'marc record is empty';
}

done_testing;

sub marc_has {
    my ($record,$tag) = @_;
    for (@{$record->{record}}) {
        return 1 if $_->[0] eq $tag;
    }
    return 0;
}
