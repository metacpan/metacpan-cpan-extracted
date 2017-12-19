#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::ColorScheme';

my @exp_names = (
    'Acidobacteria',
    'Actinobacteria',
    'Aquificae',
    'Bacteroidetes',
    'Chlamydiae',
    'Chlorobi',
    'Chloroflexi',
    'Cyanobacteria',
    'Deferribacteres',
    'Deinococcus-Thermus',
    'Dictyoglomi',
    'Firmicutes',
    'Fusobacteria',
    'Ignavibacteria',
    'Nitrospirae',
    'Planctomycetes',
    'Proteobacteria',
    'Spirochaetes',
    'Synergistetes',
    'Thermodesulfobacteria',
    'Thermotogae',
    'Verrucomicrobia',
);

my @exp_colors = (
    '#E5585D',
    '#B64348',
    '#DDA35D',
    '#AF8147',
    '#C6D95E',
    '#9DAC48',
    '#73DC63',
    '#5BAF4C',
    '#00DD7C',
    '#00AF61',
    '#0BDBBC',
    '#02AE94',
    '#46BCD8',
    '#3494AC',
    '#6876D8',
    '#505DAC',
    '#9E58D8',
    '#7D43AB',
    '#DF4FD6',
    '#B13CAA',
    '#E753A3',
    '#B73F80',
);

my @lineages = (
    [
        'Viruses',
        'Retro-transcribing viruses',
        'Retroviridae',
        'Orthoretrovirinae',
        'Lentivirus',
        'Primate lentivirus group',
        'Human immunodeficiency virus 1',
        'HIV-1 group M',
        'HIV-1 M:C',
        'HIV-1 M:C U2226'
    ],
    [
        'cellular organisms',
        'Archaea',
        'Euryarchaeota',
        'Methanobacteria',
        'Methanobacteriales',
        'Methanobacteriaceae',
        'Methanobrevibacter',
        'Methanobrevibacter ruminantium',
        'Methanobrevibacter ruminantium M1'
    ],
    [
        'cellular organisms',
        'Bacteria',
        'Tenericutes',
        'Mollicutes',
        'Acholeplasmatales',
        'Acholeplasmataceae',
        'Acholeplasma',
        'Acholeplasma laidlawii',
        'Acholeplasma laidlawii PG-8A'
    ],
    [
        'cellular organisms',
        'Bacteria',
        'Proteobacteria',
        'Betaproteobacteria',
        'Burkholderiales',
        'Comamonadaceae',
        'Curvibacter',
        'Curvibacter putative symbiont of Hydra magnipapillata'
    ],
    [
        'cellular organisms',
        'Bacteria',
        'Firmicutes',
        'Clostridia',
        'Clostridiales',
        'Peptococcaceae',
        'Desulfotomaculum',
        'Desulfotomaculum gibsoniae',
        'Desulfotomaculum gibsoniae DSM 7213'
    ],
    [
        'cellular organisms',
        'Eukaryota',
        'Viridiplantae',
        'Streptophyta',
        'Streptophytina',
        'Embryophyta',
        'Tracheophyta',
        'Euphyllophyta',
        'Spermatophyta',
        'Magnoliophyta',
        'eudicotyledons',
        'core eudicotyledons',
        'rosids',
        'malvids',
        'Brassicales',
        'Brassicaceae',
        'Camelineae',
        'Arabidopsis',
        'Arabidopsis halleri',
        'Arabidopsis halleri subsp. halleri'
    ],
    [
        'cellular organisms',
        'Eukaryota',
        'Viridiplantae',
        'Streptophyta',
        'Streptophytina',
        'Embryophyta',
        'Tracheophyta',
        'Euphyllophyta',
        'Spermatophyta',
        'Magnoliophyta',
        'eudicotyledons',
        'core eudicotyledons',
        'rosids',
        'malvids',
        'Brassicales',
        'Brassicaceae',
        'Noccaeeae',
        'Noccaea',
        'Noccaea caerulescens'
    ],
);

my @bact_colors = qw( 000000 000000 000000 9e58d8 02ae94 000000 000000 );

{
    my $infile = file('test', 'bacteria.cls');
    my $scheme = $class->load($infile);
    isa_ok $scheme, $class, $infile;
    is $scheme->count_comments, 2, 'read expected number of comments';
    is $scheme->count_names, 22, 'read expected number of names';
    is $scheme->count_colors, 22, 'read expected number of colors';
    is $scheme->header, <<'EOT', 'got expected header';
# HSB spectrum built by FigTree
# RGB values obtained with Mountain Lion's Digital Color Meter
EOT
    is_deeply $scheme->names, \@exp_names,
        'got expected names from .cls file';
    is_deeply $scheme->colors, \@exp_colors,
        'got expected colors from .cls file';

    cmp_store(
        obj => $scheme, method => 'store',
        file => 'bacteria.cls',
        test => 'wrote expected .cls file',
    );

    is_deeply [ map { uc $scheme->hex($_, '#') } $scheme->all_names ],
        $scheme->colors, "got expected color translations using $infile";

    is_deeply [ map { $scheme->hex($_) } @lineages ], \@bact_colors,
        "got expected colors for lineages using $infile";
}

my @life_colors = qw( ffa500 0000ff 008000 008000 a52a2a ff0000 ffff00 );

{
    my $infile = file('test', 'life.cls');
    my $scheme = $class->load($infile);
    is_deeply [ map { $scheme->hex($_) } @lineages ], \@life_colors,
        "got expected colors for lineages using $infile";
}

my @html_colors = qw( ff6347 6a5acd 228b22 228b22 a0522d b22222 ffd700 );

{
    my $infile = file('test', 'life_html.cls');
    my $scheme = $class->load($infile);
    is_deeply [ map { $scheme->hex($_) } @lineages ], \@html_colors,
        "got expected colors for lineages using $infile";
}

done_testing;
