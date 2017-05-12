#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;
use Test::Deep;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $record = {
  record => [
  			['LDR', undef, undef, '_', '00000nas-a2200000z--4500'],
            ['001', undef, undef, undef, 'rec002'],
            ['008', undef, undef, '_' , '150519s----------------------000---eng-d'] ,
            ['100', '1', '1', 
                '_', '' , 
                'a', 'Slayer'
            ],
            ['245', ' ', ' ',
                '_', '' , 
                'a', 'Reign in Blood' ,
            ],
            ['999', ' ', ' ',
                '_', '' , 
                'x', 'test' ,
                'x', 'test2' ,
                'x', 'test3' ,
            ]
        ]
};

my $fixer   = Catmandu::Fix->new(fixes => [q|marc_in_json()|]);
my $record2 = $fixer->fix($record);

is $record2->{leader}, qq|00000nas-a2200000z--4500|;
is $record2->{fields}->[0]->{'001'}, qq|rec002|;
is $record2->{fields}->[1]->{'008'}, qq|150519s----------------------000---eng-d|;
is $record2->{fields}->[2]->{'100'}->{'ind1'} , 1;
is $record2->{fields}->[2]->{'100'}->{'ind2'} , 1;
is $record2->{fields}->[2]->{'100'}->{'subfields'}->[0]->{a} , 'Slayer';
is $record2->{fields}->[3]->{'245'}->{'subfields'}->[0]->{a} , 'Reign in Blood';
is $record2->{fields}->[4]->{'999'}->{'subfields'}->[0]->{x} , 'test';
is $record2->{fields}->[4]->{'999'}->{'subfields'}->[1]->{x} , 'test2';
is $record2->{fields}->[4]->{'999'}->{'subfields'}->[2]->{x} , 'test3';

my $fixer2  = Catmandu::Fix->new(fixes => [q|marc_in_json(-reverse => 1)|]);
my $record3 = $fixer2->fix($record2);

cmp_deeply($record,$record3);

done_testing 11;