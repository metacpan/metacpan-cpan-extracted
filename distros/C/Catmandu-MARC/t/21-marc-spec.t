#!/usr/bin/perl
use strict;
use warnings qw(FATAL utf8);
use utf8;
use Test::More;
use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => ['t/marc_spec.fix']);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel9.mrc', type => "ISO" );
my $records = $fixer->fix($importer)->to_array;

is $records->[0]->{my}{id}, 'fol05882032 ', q|fix: marc_spec('001', my.id);|;
ok !defined $records->[0]->{my}{no}{field}, q|fix: marc_spec('000', my.no.field);|;

#field 666 does not exist in camel.usmarc
#he '$append' fix creates $my->{'references'} hash key with empty array ref as value
ok !$records->[0]->{'my'}{'references'}, q|fix: marc_spec('666', my.references.$append);|;

is_deeply
    $records->[0]->{'my'}{'references2'},
    [
        'first',
        'IMchF'
    ], 
    q|fix: add_field(my.references2.$first, 'first'); marc_spec('003', my.references2.$append);|;

is $records->[0]->{my}{title}{all}, 'Cross-platform Perl /Eric F. Johnson.', q|fix: marc_spec('245', my.title.all);|;

is $records->[0]->{my}{title}{default}, 'the title', q|fix: marc_spec('245', my.title.default, value:'the title');|;

is  $records->[0]->{my}{subjects}{all}, 'Perl (Computer program language)Web servers.Cross-platform software development.', q|fix: marc_spec('650', my.subjects.all);|;

is  $records->[0]->{my}{subjects}{joined}, 'Perl (Computer program language)###Web servers.###Cross-platform software development.', q|fix: marc_spec('650', my.subjects.joined, join:'###');|;

is_deeply
    $records->[0]->{my}{append}{subjects},
    [
        'Perl (Computer program language)',
        'Web servers.',
        'Cross-platform software development.'
    ],
    q|fix: marc_spec('650', my.append.subjects.$append);|;

is_deeply
    $records->[0]->{my}{split}{subjects},
    [
        'Perl (Computer program language)',
        'Web servers.',
        'Cross-platform software development.'
    ],
    q|fix: marc_spec('650', my.split.subjects, split:1);|;

is_deeply
    $records->[0]->{my}{append}{split}{subjects},
    [
        [
            "Perl (Computer program language)",
            "Web servers.",
            "Cross-platform software development."
        ]
    ],
    q|fix: marc_spec('650', my.append.split.subjects.$append, split:1);|;

is_deeply
    $records->[0]->{my}{fields}{indicators10},
    ['Cross-platform Perl /Eric F. Johnson.'],
    q|fix: marc_spec('..._10', my.fields.indicators10.$append);|;

is  scalar @{$records->[0]->{my}{fields}{indicators_0}}, 9,  q|fix: marc_spec('...__0', my.fields.indicators_0, split:1);|;

is $records->[0]->{my}{ldr}{all}, '00696nam  22002538a 4500', q|fix: marc_spec('LDR', my.ldr.all);|;

is $records->[0]->{my}{firstcharpos}{ldr}, '0069', q|fix: marc_spec('LDR', my.firstcharpos.ldr);|;

is $records->[0]->{my}{lastcharpos}{ldr}, '4500', q|fix: marc_spec('LDR/#-3', my.lastcharpos.ldr);|;

is $records->[0]->{my}{title}{proper}, 'Cross-platform Perl /', q|fix: marc_spec('245$a', my.title.proper);|;

is $records->[0]->{my}{title}{indicator}{proper}, 'Cross-platform Perl /', q|fix: marc_spec('245_10$a', my.title.indicator.proper);|;

is $records->[0]->{my}{title}{charpos}, 'Cr', q|fix: marc_spec('245$a/0-1', my.title.charpos);|;

is $records->[0]->{my}{second}{subject}, 'Web servers.', q|fix: marc_spec('650[1]', my.second.subjects);|;
is $records->[0]->{my}{last}{subject}, 'Cross-platform software development.', q|fix: marc_spec('650[#]', my.last.subjects);|;

is_deeply
    $records->[0]->{my}{two}{split}{subjects},
    ['Perl (Computer program language)', 'Web servers.'],
    q|fix: marc_spec('650[0-1]', my.two.split.subjects, split:1);|;

is $records->[0]->{my}{two}{join}{subjects}, 'Web servers.###Cross-platform software development.', q|fix: marc_spec('650[#-1]', my.two.join.subjects, join:'###');|;

is $records->[0]->{my}{isbn}{number}, '0764547291 (alk. paper)0491001304test0491001304', q|fix: marc_spec('020$a[0]', my.isbn.number);|;
is $records->[0]->{my}{isbn}{numbers}, '0764547291 (alk. paper)0491001304', q|fix: marc_spec('020$a[0]', my.isbn.numbers);|;
ok !defined $records->[0]->{my}{isbn}{qual}{none}, q|fix: marc_spec('020[0]$q[0]', my.isbn.qual.none);|;
is $records->[0]->{my}{isbn}{qual}{first}, 'black leather', q|fix: marc_spec('020$q[0]', my.isbn.qual.first);|;
is $records->[0]->{my}{isbn}{qual}{second}, 'blue pigskin', q|fix: marc_spec('020$q[1]', my.isbn.qual.second);|;
is $records->[0]->{my}{isbn}{qual}{last}, 'easel binding', q|fix: marc_spec('020$q[#]', my.isbn.qual.last);|;
is_deeply
    $records->[0]->{my}{isbns}{all},
    [
        "0764547291 (alk. paper)",
        "0491001304",
        "test0491001304",
        "black leather",
        "blue pigskin",
        "easel binding"
    ],
    q|fix: marc_spec('020$q$a', my.isbns.all, split:1);|;
is_deeply
    $records->[0]->{my}{isbns}{pluck}{all},
    [
        "0764547291 (alk. paper)",
        "black leather",
        "blue pigskin",
        "easel binding",
        "0491001304",
        "test0491001304"
    ],
    q|fix: marc_spec('020$q$a', my.isbns.all, split:1, pluck:1);|;
is_deeply
    $records->[0]->{my}{isbn}{qual}{other},
    [
        "test0491001304",
        "easel binding"
    ],
    q|fix: marc_spec('020$q[#]$a[1]', my.isbn.qual.other, split:1);|;
is_deeply
    $records->[0]->{my}{isbn}{qual}{range},
    [
        "0764547291 (alk. paper)",
        "0491001304",
        "test0491001304",
        "blue pigskin",
        "easel binding"
    ],
    q|fix: marc_spec('020$q[#-1]$a[0-1]', my.isbn.qual.range, split:1);|;
is_deeply
    $records->[0]->{my}{isbn}{qual}{substring}{other},
    [
        "4",
        "easel"
    ],
    q|fix: marc_spec('020$q[#]/0-4$a[1]/#-0', my.isbn.qual.substring.other, split:1);|;

is $records->[0]->{my}{level3}{inverted}, '2000.', q|fix: marc_spec('260[#]$b$a', my.level3.inverted, invert:1);|;
is $records->[0]->{my}{level2}{inverted}, 'black leatherblue pigskin', q|fix: marc_spec('020$a$q[#]', my.level2.inverted, invert:1);|;
is $records->[0]->{my}{level1}{inverted}, 'ebinding', q|fix: marc_spec('020[#]$a$q[#]/1-5', my.level1.inverted, invert:1);|;
is $records->[0]->{my}{multi}{level1}{inverted}, 'bleatherbigskinebinding', q|fix: marc_spec('020[#]$a$q[0]/1-5$q[1]/1-5$q[2]/1-5', my.multi.level1.inverted, invert:1);|;

is $records->[0]->{my}{nullvalue} , '0' , q|fix: marc_spec('008/0', my.nullvalue);|;


done_testing;