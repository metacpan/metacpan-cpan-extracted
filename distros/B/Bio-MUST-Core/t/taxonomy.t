#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Smart::Comments;

use Config::Any;
use Const::Fast;
use List::AllUtils qw(each_array);
use Path::Class qw(dir file);
use Test::Files;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:files);
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::Taxonomy';

# skip all Taxonomy tests unless asked to do so
const my $TAX_VAR => 'BMC_TEST_TAX';
unless ( $ENV{$TAX_VAR} ) {
    plan skip_all => <<"EOT";
skipped all $class tests!
These tests are long to run and require downloading the NCBI Taxonomy database.
To enable them use:
\$ $TAX_VAR=1 make test
EOT
}


# database load

# use local database
my $tax_dir = dir('test', 'taxdump')->stringify;

SKIP: {
  skip 'due to NCBI Taxonomy database already installed', 1
    if -e file($tax_dir, 'names.dmp');
    ok $class->setup_taxdir($tax_dir),
        'rightly setup the taxdump directory';
}

SKIP: {
  skip 'due to binary cache file already built', 1
    if -e file($tax_dir, 'cachedb.bin');
    my $tax4cache = $class->new( tax_dir => $tax_dir );
    $tax4cache->update_cache;
}

# new_from_cache
my $tax = $class->new_from_cache( tax_dir => $tax_dir );
isa_ok $tax, $class;

{
    my @items = qw(Canis Felis Homo Rattus Gallus);

    my @exp_items = @items;
    my @exp_ids = qw(9611 9682 9605 10114 9030);

    my @taxon_ids = map { $tax->get_taxid_from_seq_id($_) } @items;

    cmp_deeply \@items, \@exp_items, 'lazy bug: got expected items';
    cmp_deeply \@taxon_ids, \@exp_ids, 'lazy bug: got expected taxon_ids';
}


# fetch lineages

my @valid_ids = (

    # viruses
    [ 'HIV-1 M:C_505006@210038491',     # Note the unusual names of viruses
        'Viruses; Riboviria; Pararnavirae; Artverviricota; Revtraviricetes; Ortervirales; Retroviridae; Orthoretrovirinae; Lentivirus; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C; HIV-1 M:C U2226',
        'Viruses; Riboviria; Pararnavirae; Artverviricota; Revtraviricetes; Ortervirales; Retroviridae; Orthoretrovirinae; Lentivirus; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C',
       ('Viruses; Riboviria; Pararnavirae; Artverviricota; Revtraviricetes; Ortervirales; Retroviridae; Orthoretrovirinae; Lentivirus; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C; HIV-1 M:C U2226') x 3,
        q{'HIV-1 M:C U2226'},
        q{'HIV-1 M:C U2226 [210038491]'} ],

    # Archaea
    [ 'Methanobrevibacter ruminantium_634498@288561462',
        'cellular organisms; Archaea; Euryarchaeota; Methanomada group; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium; Methanobrevibacter ruminantium M1',
        'cellular organisms; Archaea; Euryarchaeota; Methanomada group; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium',
       ('cellular organisms; Archaea; Euryarchaeota; Methanomada group; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium; Methanobrevibacter ruminantium M1') x 3,
        q{'Methanobrevibacter ruminantium M1'},
        q{'Methanobrevibacter ruminantium M1 [288561462]'} ],

    # Bacteria
    [ 'Acholeplasma laidlawii_441768@162448101',
        'cellular organisms; Bacteria; Terrabacteria group; Tenericutes; Mollicutes; Acholeplasmatales; Acholeplasmataceae; Acholeplasma; Acholeplasma laidlawii; Acholeplasma laidlawii PG-8A',
        'cellular organisms; Bacteria; Terrabacteria group; Tenericutes; Mollicutes; Acholeplasmatales; Acholeplasmataceae; Acholeplasma; Acholeplasma laidlawii',
       ('cellular organisms; Bacteria; Terrabacteria group; Tenericutes; Mollicutes; Acholeplasmatales; Acholeplasmataceae; Acholeplasma; Acholeplasma laidlawii; Acholeplasma laidlawii PG-8A') x 3,
        q{'Acholeplasma laidlawii PG-8A'},
        q{'Acholeplasma laidlawii PG-8A [162448101]'} ],
    [ 'Curvibacter putative_667019@260221396',
        'cellular organisms; Bacteria; Proteobacteria; Betaproteobacteria; Burkholderiales; Comamonadaceae; Curvibacter; Curvibacter putative symbiont of Hydra magnipapillata',
        '',         # Note the unusual 'organism' name
       ('cellular organisms; Bacteria; Proteobacteria; Betaproteobacteria; Burkholderiales; Comamonadaceae; Curvibacter; Curvibacter putative symbiont of Hydra magnipapillata') x 3,
        q{'Curvibacter putative symbiont of Hydra magnipapillata'},
        q{'Curvibacter putative symbiont of Hydra magnipapillata [260221396]'} ],
    [ 'Desulfotomaculum gibsoniae_767817@357041591',
        'cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfallas; Desulfallas gibsoniae; Desulfallas gibsoniae DSM 7213',
        'cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfallas; Desulfallas gibsoniae',
       ('cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfallas; Desulfallas gibsoniae; Desulfallas gibsoniae DSM 7213') x 3,
        q{'Desulfallas gibsoniae DSM 7213'},
        q{'Desulfallas gibsoniae DSM 7213 [357041591]'} ],

    # Eukaryota
    [ 'Arabidopsis halleri_81971@184160085',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [184160085]'} ],
    [ 'Arabidopsis halleri_63677@63056225',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. gemmifera',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. gemmifera') x 3,
        q{'Arabidopsis halleri subsp. gemmifera'},
        q{'Arabidopsis halleri subsp. gemmifera [63056225]'} ],
    [ 'Arabidopsis halleri_81970@ABB29495.1',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri') x 3,
        q{'Arabidopsis halleri'},
        q{'Arabidopsis halleri [ABB29495.1]'} ],
    [ 'Arabidopsis halleri_halleri@78182999',
        '',     # legacy id without taxon_id (but alignable)
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [78182999]'} ],
    [ 'Arabidopsis halleri_halleri@ABB29495.1',
        '',     # legacy id without taxon_id (but alignable)
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [ABB29495.1]'} ],
    [ 'Arabidopsis lyrata_81972@297836718',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata; Arabidopsis lyrata subsp. lyrata',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata; Arabidopsis lyrata subsp. lyrata') x 3,
        q{'Arabidopsis lyrata subsp. lyrata'},
        q{'Arabidopsis lyrata subsp. lyrata [297836718]'} ],
    [ 'Arabidopsis thaliana_3702@15224717',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana') x 3,
        q{'Arabidopsis thaliana'},
        q{'Arabidopsis thaliana [15224717]'} ],
    [ 'Noccaea caerulescens_107243@326416416',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens') x 3,
        q{'Noccaea caerulescens'},
        q{'Noccaea caerulescens [326416416]'} ],

    # valid ids with merged taxon_ids in NCBI Taxonomy
    [ 'Synedra acus_191585@123456',
        'cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus',
        'cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus',
       ('cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus') x 3,
        q{'Ulnaria acus'},
        q{'Ulnaria acus [123456]'} ],
    [ 'Oscillatoriales cyanobacterium_627090@ABCDEF',
        'cellular organisms; Bacteria; Terrabacteria group; Cyanobacteria/Melainabacteria group; Cyanobacteria; unclassified Cyanobacteria; [Leptolyngbya] sp. JSC-1',
        'cellular organisms; Bacteria; Terrabacteria group; Cyanobacteria/Melainabacteria group; Cyanobacteria; Oscillatoriophycideae; Oscillatoriales; unclassified Oscillatoriales; Oscillatoriales cyanobacterium',
       ('cellular organisms; Bacteria; Terrabacteria group; Cyanobacteria/Melainabacteria group; Cyanobacteria; unclassified Cyanobacteria; [Leptolyngbya] sp. JSC-1') x 3,
        q{'[Leptolyngbya] sp. JSC-1'},
        q{'[Leptolyngbya] sp. JSC-1 [ABCDEF]'} ],
#     [ 'Fistulifera sp._880758@xyz789',
#         'cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera solaris',
#         'cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera sp.',
#        ('cellular organisms; Eukaryota; Sar; Stramenopiles; Ochrophyta; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera solaris') x 3,
#         q{'Fistulifera solaris'},
#         q{'Fistulifera solaris [xyz789]'} ],

    # valid ids normally not found in NCBI Taxonomy (but that work due to greedy behavior)
    [ 'Bostrichobranchus mypilularis@123456',   # mypilularis because pilularis now exists!
        '',
        '',
       ('cellular organisms; Eukaryota; Opisthokonta; Metazoa; Eumetazoa; Bilateria; Deuterostomia; Chordata; Tunicata; Ascidiacea; Stolidobranchia; Molgulidae; Bostrichobranchus') x 3,
        q{'Bostrichobranchus'},
        q{'Bostrichobranchus [123456]'} ],

    # valid ids not found in NCBI Taxonomy
    [ 'Nessiteras rhombopteryx@PCR28S',
        '', '', ('') x 3,
        q{'Nessiteras rhombopteryx'},
        q{'Nessiteras rhombopteryx [PCR28S]'} ],
    [ q{Nessiteras rhombopteryx_'loch-ness'@PCR28S},
        '', '', ('') x 3,
        q{'Nessiteras rhombopteryx loch-ness'},
        q{'Nessiteras rhombopteryx loch-ness [PCR28S]'} ],

    # taxonomy-aware foreign ids
    [ '81970|ABB29495.1',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
        '',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri') x 3,
        q{'Arabidopsis halleri'},
        q{'Arabidopsis halleri [ABB29495.1]'},
    ],

    # NCBI FASTA-style foreign ids
    # skipped by default to avoid build GI-to-taxid mapper
#     [ 'gi|404160475',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
#         q{'Anthurium andraeanum'},
#         q{'Anthurium andraeanum [404160475]'} ],
#     [ 'gi|404160475|gb|AFR53081.1|',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
#         q{'Anthurium andraeanum'},
#         q{'Anthurium andraeanum [AFR53081.1]'} ],
#     [ 'gi|404160475|gb|AFR53081.1| AOX [Anthurium andraeanum]',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
#         q{'Anthurium andraeanum'},
#         q{'Anthurium andraeanum [AFR53081.1]'} ],
#     [ 'gi|11245480|gb|AAG33633.1|AF314254_1',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Chlorophyta; Chlorophyceae; Chlamydomonadales; Chlamydomonadaceae; Chlamydomonas; Chlamydomonas reinhardtii',
#         q{'Chlamydomonas reinhardtii'},
#         q{'Chlamydomonas reinhardtii [AAG33633.1]'} ],
#     [ 'gi|11245480|gb|AAG33633.1|AF314254_1 alternative oxidase 1 [Chlamydomonas reinhardtii]',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Chlorophyta; Chlorophyceae; Chlamydomonadales; Chlamydomonadaceae; Chlamydomonas; Chlamydomonas reinhardtii',
#         q{'Chlamydomonas reinhardtii'},
#         q{'Chlamydomonas reinhardtii [AAG33633.1]'} ],

    # other foreign ids
    [ 'seq1',
        '', '', ('') x 3,
        q{'seq1'},
        q{'seq1'} ],
);

{
    for my $exp_row (@valid_ids) {
        my $seq_id = Bio::MUST::Core::SeqId->new( full_id => $exp_row->[0] );
        my @taxonomy = $tax->get_taxonomy_from_seq_id($seq_id);
        my $lineage  = join '; ', @taxonomy;
        my $got_row = [
            $seq_id->full_id,
            join('; ', @{ $tax->get_taxonomy($seq_id->taxon_id)      // [] } ),
            join('; ', @{ $tax->get_taxonomy_from_name($seq_id->org) // [] } ),
            $lineage,
            join('; ', @{ $tax->get_taxonomy_from_seq_id(\@taxonomy) // [] } ),
            join('; ', @{ $tax->get_taxonomy_from_seq_id($lineage)   // [] } ),
            $tax->get_nexus_label_from_seq_id($seq_id),
            $tax->get_nexus_label_from_seq_id($seq_id, { append_acc => 1 } ),
        ];  # Note: warnings are expected here
        is_deeply $got_row, $exp_row,
            'Fetched expected taxonomic information from valid SeqId';
    }
}


# strains and gca numbers

sub check_legacy {
    my $method  = shift;

    tie my     %taxid_for, 'Tie::IxHash';
    tie my %exp_taxid_for, 'Tie::IxHash';

    my $infile = $method . '.test';
    open my $in, '<', file('test', $infile);

    my $outfile = "my_$infile";
    open my $out, '>', file('test', $outfile);

    LINE:
    while ( my $line = <$in> ) {
        chomp $line;

        # skip empty lines and comment lines
        if ($line =~ $EMPTY_LINE
         || $line =~ $COMMENT_LINE) {
            say {$out} $line;
            next LINE;
        }

        # fetch full_id
        my ($full_id) = $line =~ m/ (\w+ \s+ \S+) /xms;

        # get taxon_id from seq_id
        my $seq_id = Bio::MUST::Core::SeqId->new(full_id => $full_id);
        my $taxid = $tax->$method($seq_id);

        # output full_id => taxon_id pair
        say {$out} join "\t", $full_id, $taxid // 'NA';
    }

    close $out;
    close $in;

    # compare file contents
    compare_filter_ok(file('test', $outfile), file('test', $infile), \&canonize,
        "Fetched expected taxon_ids from legacy seq_ids: $infile");

    return;
}

sub canonize {
    my $line = shift;
    $line =~ s{GC[AF]_(\d+)\.\d+}{GCA_$1.1}xms;
    return $line;
}

# TODO: try to make this work again

SKIP: {
  skip 'due to change in handling of exceptions', 2;
    check_legacy('get_taxid_from_legacy_seq_id', $tax);
    check_legacy('get_taxid_from_seq_id', $tax);
}


{
    my $infile = 'get_taxonomy_from_gca.test';

    open my $in, '<', file('test', $infile);

    my $outfile = "my_$infile";
    open my $out, '>', file('test', $outfile);

    LINE:
    while ( my $line = <$in> ) {
        chomp $line;

        # skip empty lines and comment lines
        if ($line =~ $EMPTY_LINE
         || $line =~ $COMMENT_LINE) {
            say {$out} $line;
            next LINE;
        }

        # fetch gca
        my ($gca) = $line =~ m/^ (\w+ \. \d+) \s /xms;

        # get taxon_id from seq_id
        my @taxonomy = $tax->get_taxonomy($gca);
        my $org = $taxonomy[-1];

        # output full_id => taxon_id pair
        say {$out} join "\t", $gca, $org // 'NA';
    }

    close $out;
    close $in;

    # compare file contents
    compare_filter_ok(file('test', $outfile), file('test', $infile), \&canonize,
        "Fetched expected taxonomy from GCAs: $infile");
}


# duplicate taxa
my @dupe_tests = (

    # non-duplicate taxa
    [ 'Archaea', 'cellular organisms; Archaea', 2157,
        [ qw(Archaea undef undef undef undef undef undef undef) ] ],
    [ 'Chlamydomonas', 'cellular organisms; Eukaryota; Viridiplantae; Chlorophyta; core chlorophytes; Chlorophyceae; Chlamydomonadales; Chlamydomonadaceae; Chlamydomonas', 3052,
        [ qw(Eukaryota Viridiplantae Chlorophyta Chlorophyceae Chlamydomonadales Chlamydomonadaceae Chlamydomonas undef) ] ],

    # subtaxa named after higher taxa
    [ 'Actinobacteria', 'cellular organisms; Bacteria; Terrabacteria group; Actinobacteria; Actinobacteria', 1760,
        [ qw(Bacteria undef Actinobacteria Actinobacteria undef undef undef undef) ]  ],
    [ 'Actinobacteria', 'cellular organisms; Bacteria; Terrabacteria group; Actinobacteria', 201174,
        [ qw(Bacteria undef Actinobacteria undef undef undef undef undef) ]  ],
    [ 'Aedes', 'cellular organisms; Eukaryota; Opisthokonta; Metazoa; Eumetazoa; Bilateria; Protostomia; Ecdysozoa; Panarthropoda; Arthropoda; Mandibulata; Pancrustacea; Hexapoda; Insecta; Dicondylia; Pterygota; Neoptera; Holometabola; Diptera; Nematocera; Culicomorpha; Culicoidea; Culicidae; Culicinae; Aedini; Aedes; Aedes', 149531,
        [ qw(Eukaryota Metazoa Arthropoda Insecta Diptera Culicidae Aedes undef) ]  ],
    [ 'Aedes', 'cellular organisms; Eukaryota; Opisthokonta; Metazoa; Eumetazoa; Bilateria; Protostomia; Ecdysozoa; Panarthropoda; Arthropoda; Mandibulata; Pancrustacea; Hexapoda; Insecta; Dicondylia; Pterygota; Neoptera; Holometabola; Diptera; Nematocera; Culicomorpha; Culicoidea; Culicidae; Culicinae; Aedini; Aedes', 7158,
        [ qw(Eukaryota Metazoa Arthropoda Insecta Diptera Culicidae Aedes undef) ]  ],
    [ 'Aquificae', 'cellular organisms; Bacteria; Aquificae; Aquificae', 187857,
        [ qw(Bacteria undef Aquificae Aquificae undef undef undef undef) ]  ],
    [ 'Aquificae', 'cellular organisms; Bacteria; Aquificae', 200783,
        [ qw(Bacteria undef Aquificae undef undef undef undef undef) ]  ],

    # duplicate genera
    [ 'Uronema', 'cellular organisms; Eukaryota; Sar; Alveolata; Ciliophora; Intramacronucleata; Oligohymenophorea; Scuticociliatia; Philasterida; Uronematidae; Uronema', 35106,
        [ qw(Eukaryota undef Ciliophora Oligohymenophorea Philasterida Uronematidae Uronema undef) ]  ],
    [ 'Uronema', 'cellular organisms; Eukaryota; Viridiplantae; Chlorophyta; core chlorophytes; Chlorophyceae; OCC clade; Chaetophorales; Uronemataceae; Uronema', 104535,
        [ qw(Eukaryota Viridiplantae Chlorophyta Chlorophyceae Chaetophorales Uronemataceae Uronema undef) ]  ],

    # genera clashing with higher taxa
    [ 'Vertebrata', 'cellular organisms; Eukaryota; Rhodophyta; Florideophyceae; Rhodymeniophycidae; Ceramiales; Rhodomelaceae; Polysiphonioideae; Vertebrata', 1261581,
        [ qw(Eukaryota undef Rhodophyta Florideophyceae Ceramiales Rhodomelaceae Vertebrata undef) ]  ],
    [ 'Vertebrata', 'cellular organisms; Eukaryota; Opisthokonta; Metazoa; Eumetazoa; Bilateria; Deuterostomia; Chordata; Craniata; Vertebrata', 7742,
        [ qw(Eukaryota Metazoa Chordata undef undef undef undef undef) ]  ],

    # short lineages
    [ 'mixed libraries', 'unclassified entries; unclassified sequences; mixed libraries', 704107,
        [ qw(undef undef undef undef undef undef undef undef) ] ],
    [ 'environmental samples', 'Viruses; environmental samples', 186616,
        [ qw(Viruses undef undef undef undef undef undef undef) ] ],

    # names impossible to disambiguate due to completely identical lineage
    [ 'Frankia', 'cellular organisms; Bacteria; Terrabacteria group; Actinobacteria; Actinobacteria; Frankiales; Frankiaceae; Frankia; unclassified Frankia; Frankia sp. NRRL B-16315', 683320,
        [ qw(Bacteria undef Actinobacteria Actinobacteria Frankiales Frankiaceae Frankia), 'Frankia sp. NRRL B-16315' ]  ],
);

{
    my @ranks = qw(superkingdom kingdom phylum class order family genus species);

    for my $dupe_test (@dupe_tests) {
        my ($taxon, $lineage, $exp_taxon_id, $exp_taxa) = @{$dupe_test};

        my $got_taxon_id = $tax->get_taxid_from_taxonomy($lineage);
        cmp_ok $got_taxon_id, '==', $exp_taxon_id,
            "got expected taxon_id for $taxon";

        my @got_taxa = $tax->get_taxa_from_taxid($got_taxon_id, @ranks);
        is_deeply \@got_taxa, $exp_taxa,
            "got expected taxa for $got_taxon_id";
    }
}


# filters and lca inference

{
    my   @wanted = qw(Fungi Cnidaria);
    my @unwanted = qw(Ascomycota Anthozoa);

    my $infile = 'test/filters.idl';
    my $filter = $tax->tax_filter($infile);

    cmp_bag [ $filter->all_wanted ], \@wanted,
        "loaded expected wanted specs from file: $infile";
    cmp_bag [ $filter->all_unwanted ], \@unwanted,
        "loaded expected unwanted specs from file: $infile";

    ok( (List::AllUtils::all { $filter->is_wanted(  $_) } @wanted),
        "identified wanted taxa as expected:");
    explain [ $filter->all_wanted ];
    ok( (List::AllUtils::all { $filter->is_unwanted($_) } @unwanted),
        "identified unwanted taxa as expected:");
    explain [ $filter->all_unwanted ];

    my @orgs = (
        'Phytophthora infestans',
        'Nessiteras rhombopteryx',          # unknown name   (should be undef)
        'Podocoryne minima',                # synonym        (should be 1)
        'Podocoryna carnea',
        'Hydra sp.',                        # non-dupe genus (should be 1)
        'Arabidopsis thaliana',
        'Saccharomyces cerevisiae',
        'Liriope sp.',                      # dupe genus     (should be undef)
    );

    my @exp_filters = (0, undef, 1, 1, 1, 0, 0, undef);
    is_deeply [ map { $filter->is_allowed($_) } @orgs ], \@exp_filters,
        'got expected allowances for:';
    explain \@orgs;
}

my @filters = (
    [
        [ qw(+eudicotyledons +Lycopodiopsida -Arabidopsis -Medicago) ],
        [
            'Glycine max_3847@356550732',
            'Selaginella moellendorffii_88036@302803464',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta',
    ],
    [
        [ qw(+Poaceae) ],
        [
            'Oryza sativa_39947@315623028',
            'Sorghum bicolor_4558@242096926',
            'Brachypodium distachyon_15368@357123620',
            'Triticum aestivum_4565@302595059',
            'Hordeum vulgare_4513@295881652',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae; BOP clade',
    ],
    [
        [ qw(-eudicotyledons) ],
        [
            'Oryza sativa_39947@315623028',
            'Sorghum bicolor_4558@242096926',
            'Brachypodium distachyon_15368@357123620',
            'Triticum aestivum_4565@302595059',
            'Hordeum vulgare_4513@295881652',
            'Selaginella moellendorffii_88036@302803464',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae',
    ],
    [
        [ '+Arabidopsis thaliana', '+Brachypodium distachyon' ],
        [
            'Arabidopsis thaliana_3702@7269912',
            'Brachypodium distachyon_15368@357123620',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae',
    ],
    [
        [],
        [
            'Medicago truncatula_3880@357479567',
            'Arabidopsis thaliana_3702@7269912',
            'Arabidopsis halleri_81970@78182999',
            'Glycine max_3847@356550732',
            'Oryza sativa_39947@315623028',
            'Sorghum bicolor_4558@242096926',
            'Brachypodium distachyon_15368@357123620',
            'Triticum aestivum_4565@302595059',
            'Hordeum vulgare_4513@295881652',
            'Selaginella moellendorffii_88036@302803464',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae',
    ]
);

{
    my $infile = file('test', 'filter.fasta');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    for my $exp_row (@filters) {
        my $filter = $tax->tax_filter( $exp_row->[0] );
#         explain [ $filter->all_wanted ];
#         explain [ $filter->all_unwanted ];
        my $id_list = $filter->tax_list($ali);
        is_deeply [ $id_list->all_ids ], $exp_row->[1],
            'got expected taxonomic list from filter:';
        explain [ $filter->all_specs ];
        my $filtered = $id_list->filtered_ali($ali);

        my @lineage_10 = $tax->get_common_taxonomy_from_seq_ids(
            $filtered->all_seq_ids
        );
        cmp_ok join('; ', @lineage_10), 'eq', $exp_row->[2],
            'got expected common taxonomy at strict threshold';

        my @lineage_08 = $tax->get_common_taxonomy_from_seq_ids(
            0.8, $filtered->all_seq_ids
        );
        cmp_ok join('; ', @lineage_08), 'eq', $exp_row->[3],
            'got expected common taxonomy at 80% threshold';
    }

    my $mapper = $tax->tax_mapper($ali);
    cmp_store(
        obj => $mapper, method => 'store',
        file => 'filter_tax.idm',
        test => 'wrote expected taxonomic mapper',
    );

    my $mapper_acc = $tax->tax_mapper($ali, { append_acc => 1 } );
    cmp_store(
        obj => $mapper_acc, method => 'store',
        file => 'filter_tax_acc.idm',
        test => 'wrote expected taxonomic mapper with accessions',
    );
}


# mappers

{
    my $infile = file('test', 'tab_mapper_mustids.tsv');

    my $mapper = $tax->tab_mapper($infile, { column => 8 } );
    cmp_store(
        obj => $mapper, method => 'store',
        file => 'tab_mapper_mustids.idm',
        test => 'wrote expected table to id mapper',
    );
}

{
    my $infile = file('test', 'tab_mapper_with_idm.tsv');
    my $idm    = file('test', 'tab_mapper_gi2taxid.idm');

    my $mapper = $tax->tab_mapper( $infile, {
        column   => 8,
        gi2taxid => $idm,
    } );
    cmp_store(
        obj => $mapper, method => 'store',
        file => 'tab_mapper_with_idm.idm',
        test => 'wrote expected table to id mapper',
    );

}

SKIP: {
  skip 'due to the lack of a binary GI-to-taxid mapper', 1
    unless -e file('test', 'taxdump', 'gi_taxid_nucl_prot.bin');

    my $infile = file('test', 'gi_mapper.fasta');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $mapper = $tax->gi_mapper($ali);
    cmp_store(
        obj => $mapper, method => 'store',
        file => 'gi_mapper.idm',
        test => 'wrote expected GI to taxid/GI mapper',
    );
}


# classifiers

{
    # read configuration file
    my $infile = file('test', 'classifier.yaml');
    my $config = Config::Any->load_files( {
        files           => [ $infile->stringify ],
        flatten_to_hash => 1,
        use_ext         => 1,
    } );
    explain $config->{$infile};

    # build classifier
    my $classifier = $tax->tax_classifier( $config->{$infile} );

    my @exp_labels = qw(strict loose);
    is_deeply [ $classifier->all_labels ], \@exp_labels,
        'got expected label list for classifier';

    # classify Ali files
    my @exp_cats = ('strict', ('loose') x 5);
    for my $num ( qw(392 590 593 618 639 649) ) {
        my $infile = file('test', "GNTPAN19$num.ali");
        my $ali = Bio::MUST::Core::Ali->load($infile);
        my $got_cat = $classifier->classify($ali) // q{undef};
        cmp_ok $got_cat, 'eq', shift @exp_cats,
            "rightly classified $infile as $got_cat";
    }
}

{
    my $frfile = file('test', 'lifemrch.fra');
    my $classifier = $tax->tax_labeler_from_systematic_frame($frfile);

    my $infile = file('test', 'fetch-tax-mustid.idl');
    my $list = Bio::MUST::Core::IdList->load($infile);

    my @exp_taxa = (
        qw(Tenericutes Proteobacteria Firmicutes Firmicutes Firmicutes) x 2
    );

    # check classification using both plain full_ids and true seq_ids
    my @got_taxa = map {
        $classifier->classify($_)
    } $list->all_ids, $list->all_seq_ids;

    is_deeply \@got_taxa, \@exp_taxa,
        'got expected taxa for seq_ids compared to a systematic frame';
}


# eq_tax

my @lcas = (
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana', 1, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales', 1, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliopsida; Mesangiospermae; eudicotyledons', 1, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta', 1, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina', 1, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Klebsormidiophyceae', 0, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta', 0, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae', 0, 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota', 0, 0 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Rhodophyta; Bangiophyceae; Cyanidiales; Cyanidiaceae', 0, 0 ],
);

{
    my $infile = file('test', 'classifier-simple.idl');
    my $classifier = $tax->tax_labeler_from_list($infile);

    for my $exp_row (@lcas) {
        my ($org, $lca, $exp, $exp_gr) = @{$exp_row};

        my ($got_taxon, $exp_taxon) = $tax->eq_tax($org, $lca, $classifier);
        explain $got_taxon;
        explain $exp_taxon;

        my $got = $tax->eq_tax($org, $lca, $classifier) // 0;
        cmp_ok $got, '==', $exp,
            "got expected result for eq_tax with $lca";

        my $got_gr = $tax->eq_tax($org, $lca, $classifier, { greedy => 1 }) // 0;
        cmp_ok $got_gr, '==', $exp_gr,
            "got expected result for greedy eq_tax with $lca";
    }
}

my @eq_tests = (

    [ 'GCF_000005825.2',
    'cellular organisms; Bacteria; Firmicutes; Bacilli; Bacillales; Bacillaceae; Bacillus',
    'cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Bacilli; Bacillales; Bacillaceae; Bacillus; Bacillus pseudofirmus; Bacillus pseudofirmus OF4',
    ],
    [ 'GCF_000006625.1',
    'cellular organisms; Bacteria; Tenericutes; Mollicutes; Mycoplasmatales; Mycoplasmataceae; Ureaplasma',
    'cellular organisms; Bacteria; Terrabacteria group; Tenericutes; Mollicutes; Mycoplasmatales; Mycoplasmataceae; Ureaplasma; Ureaplasma parvum; Ureaplasma parvum serovar 3 str. ATCC 700970',
    ],
    [ 'GCF_000007405.1',
    'cellular organisms; Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia-Shigella',
    'cellular organisms; Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacterales; Enterobacteriaceae; Shigella; Shigella flexneri; Shigella flexneri 2a str. 2457T',
    ],
    [ 'GCF_000007325.1',
    'cellular organisms; Bacteria; Fusobacteria; Fusobacteriia; Fusobacteriales; Fusobacteriaceae; Fusobacterium',
    'cellular organisms; Bacteria; Fusobacteria; Fusobacteriia; Fusobacteriales; Fusobacteriaceae; Fusobacterium; Fusobacterium nucleatum; Fusobacterium nucleatum subsp. nucleatum ATCC 25586',
    ],
    [ 'GCF_000007205.1',
    'cellular organisms; Bacteria; Chlamydiae; Chlamydiae; Chlamydiales; Chlamydiaceae; Chlamydia',
    'cellular organisms; Bacteria; PVC group; Chlamydiae; Chlamydiia; Chlamydiales; Chlamydiaceae; Chlamydia/Chlamydophila group; Chlamydia; Chlamydia pneumoniae; Chlamydophila pneumoniae TW-183',
    ],

    # note the lack of space after the semicolons and the trailing semicolons
    [ 'GCF_000006665.1',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Escherichia-Shigella;',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacterales;Enterobacteriaceae;Escherichia;Escherichia coli;Escherichia coli O157:H7 str. EDL933;',
    ],
    [ 'GCF_000006725.1',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Xanthomonadales;Xanthomonadaceae;Xylella;',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Xanthomonadales;Xanthomonadaceae;Xylella;Xylella fastidiosa;Xylella fastidiosa 9a5c;',
    ],
    [ 'GCF_000006865.1',
    'cellular organisms;Bacteria;Firmicutes;Bacilli;Lactobacillales;Streptococcaceae;Lactococcus;',
    'cellular organisms;Bacteria;Terrabacteria group;Firmicutes;Bacilli;Lactobacillales;Streptococcaceae;Lactococcus;Lactococcus lactis;Lactococcus lactis subsp. lactis Il1403;',
    ],
    [ 'GCF_000007725.1',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Buchnera;',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacterales;Erwiniaceae;Buchnera;Buchnera aphidicola;Buchnera aphidicola str. Bp (Baizongia pistaciae);',
    ],

    # must fail!
#   [ 'GCF_000008625.1',
#   'cellular organisms;Bacteria;Aquificae;Aquificae;Aquificales;Aquificaceae;Aquifex;',
#   'cellular organisms;Archaea;Euryarchaeota;Thermoplasmata;Thermoplasmatales;Picrophilaceae;Picrophilus;Picrophilus torridus;Picrophilus torridus DSM 9790;',
#   ],

    [ 'GCF_000008885.1',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Wigglesworthia;',
    'cellular organisms;Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacterales;Erwiniaceae;Wigglesworthia;Wigglesworthia glossinidia;Wigglesworthia glossinidia endosymbiont of Glossina brevipalpis;',
    ],
    [ 'GCF_000009625.1',
    'cellular organisms;Bacteria;Proteobacteria;Alphaproteobacteria;Rhizobiales;Rhizobiaceae;Mesorhizobium;',
    'cellular organisms;Bacteria;Proteobacteria;Alphaproteobacteria;Rhizobiales;Phyllobacteriaceae;Mesorhizobium;Mesorhizobium loti;Mesorhizobium loti MAFF303099;',
    ],
);

{
    my $infile = file('test', 'leaf_4_fra_bact.list');
    my $classifier = $tax->tax_labeler_from_list($infile);

    for my $exp_row (@eq_tests) {
        my ($gca, $sina_lineage, $ncbi_lineage) = @{$exp_row};
        my $got = $tax->eq_tax($sina_lineage, $ncbi_lineage, $classifier);
        ok $got, "got expected result for eq_tax for $gca";
    }
}


# color schemes and tree annotation

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

my @exp_icols = (1..22);

my @seq_ids = (
    'HIV-1 M:C_U2226_505006@1',
    'Methanobrevibacter ruminantium_M1_634498@1',
    'Acholeplasma laidlawii_PG8A_441768@1',
    'Curvibacter putative_symbiontofHydramagnipapillata_667019@1',
    'Streptomyces lunaelactis@1',
    'Desulfotomaculum gibsoniae_DSM7213_767817@1',
    'Arabidopsis halleri_halleri_81971@1',
    'Noccaea caerulescens_107243@1',
);

my @bact_colors = qw( 000000 000000 000000 9e58d8 b64348 02ae94 000000 000000 );

{
    my $class = 'Bio::MUST::Core::Taxonomy::ColorScheme';

    my $infile = file('test', 'bacteria.cls');
    my $scheme = $tax->load_color_scheme($infile);
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

    SKIP: {
      skip 'due to stricter handling of duplicate taxa', 2;
        my @got = map { uc $scheme->hex($_, '#') } $scheme->all_names;
        is_deeply [ map { uc $scheme->hex($_, '#') } $scheme->all_names ],
            $scheme->colors, "got expected color translations using $infile";

        is_deeply [ map { $scheme->icol($_) } $scheme->all_names ], \@exp_icols,
            'got expected indexed colors from .cls file';
    }

    is_deeply [ map { scalar $scheme->hex($_) } @seq_ids ], \@bact_colors,
        "got expected colors for seq_ids using $infile";
}

my @life_colors = qw( ffa500 0000ff 008000 008000 008000 a52a2a ff0000 ffff00 );
my @life_icols  = (4, 1, 2, 2, 2, 5, 3, 6);

{
    my $infile = file('test', 'life.cls');
    my $scheme = $tax->load_color_scheme($infile);
    is_deeply [ map { scalar $scheme->hex($_) } @seq_ids ], \@life_colors,
        "got expected colors for seq_ids using $infile";

#     explain \@seq_ids;
    my @lineages = map { scalar $scheme->tax->fetch_lineage($_) } @seq_ids;
#     explain \@lineages;
    my @labels   = map { $scheme->classify($_) } @lineages;
#     explain \@labels;
    my @colors   = map { $scheme->color_for($_) } @labels;
#     explain \@colors;
    my @icols    = map { $scheme->icol_for($_) } @colors;
#     explain \@icols;
    is_deeply \@icols, \@life_icols,
        "got expected indexed colors (indirectly) for seq_ids using $infile";

    my @icols_dir = map { scalar $scheme->icol($_) } @seq_ids;
    is_deeply \@icols_dir, \@life_icols,
        "got expected indexed colors (directly) for seq_ids using $infile";
}

my @html_colors = qw( ff6347 6a5acd 228b22 228b22 228b22 a0522d b22222 ffd700 );

{
    my $infile = file('test', 'life_html.cls');
    my $scheme = $tax->load_color_scheme($infile);
    is_deeply [ map { scalar $scheme->hex($_) } @seq_ids ], \@html_colors,
        "got expected colors for lineages using $infile";
}

{
    my $infile = file('test', 'cyanos.arb');
    my $tree = Bio::MUST::Core::Tree->load($infile);

    $tax->attach_taxonomies_to_terminals($tree);
    $tax->attach_taxonomies_to_internals($tree);

    $tax->attach_taxa_to_entities($tree);
    $tree->switch_attributes_and_labels_for_internals('taxon');
    cmp_store(
        obj => $tree, method => 'store',
        file => 'cyanos_taxa.tre',
        test => 'wrote expected taxonomically-annotated tree',
    );
}

{
    my $infile = file('test', 'collapse.tre');
    my $tree = Bio::MUST::Core::Tree->load($infile);

    $tax->attach_taxonomies_to_terminals($tree);
    $tax->attach_taxonomies_to_internals($tree);

    $tax->attach_taxa_to_entities($tree, { name => 'family' });
    $tree->collapse_subtrees;
    $tree->switch_attributes_and_labels_for_internals('taxon');
    cmp_store(
        obj => $tree, method => 'store_figtree',
        file => 'collapse.nex',
        test => 'wrote expected taxonomically-annotated tree',
    );
}

{
    # TODO: rewrite using a convenience sub

    my $infile = file('test', 'PBP3.tre');
    my $tree = Bio::MUST::Core::Tree->load($infile);

    $tax->attach_taxonomies_to_terminals($tree);
    $tax->attach_taxonomies_to_internals($tree);

    # test auto naming with no collapsing and .tre output
    $tax->attach_taxa_to_entities($tree);
    $tree->switch_attributes_and_labels_for_internals('taxon');
    cmp_store(
        obj => $tree, method => 'store',
        file => 'PBP3_auto.tre',
        test => 'wrote expected taxonomically-annotated tree',
    );
    $tree->switch_attributes_and_labels_for_internals('taxon');

    SKIP: {
      skip 'due to reccurrent issues linked to NCBI Taxonomy updates', 4
        unless 1;

        # test auto naming with phylum-level collapsing and .nex output
        $tax->attach_taxa_to_entities($tree, { collapse => 'phylum' } );
        $tree->collapse_subtrees;
        cmp_store(
            obj => $tree, method => 'store_figtree',
            file => 'PBP3_auto_phylum.nex',
            test => 'wrote expected taxonomically-annotated tree',
        );

        # test family-level naming with no collapsing and .tre output
        $tax->attach_taxa_to_entities($tree, {     name => 'family' } );
        $tree->switch_attributes_and_labels_for_internals('taxon');
        cmp_store(
            obj => $tree, method => 'store',
            file => 'PBP3_family.tre',
            test => 'wrote expected taxonomically-annotated tree',
        );
        $tree->switch_attributes_and_labels_for_internals('taxon');

        # test family-level naming with phylum-level collapsing and .nex output
        $tax->attach_taxa_to_entities($tree, {     name => 'family',
                                               collapse => 'phylum' } );
        $tree->collapse_subtrees;
        cmp_store(
            obj => $tree, method => 'store_figtree',
            file => 'PBP3_family_phylum.nex',
            test => 'wrote expected taxonomically-annotated tree',
        );

        # test phylum-level naming with phylum-level collapsing, coloring
        # ... and .nex output!
        $tax->attach_taxa_to_entities($tree, {     name => 'phylum',
                                               collapse => 'phylum' } );
        $tree->collapse_subtrees;
        my $scheme = $tax->load_color_scheme(file('test', 'bacteria.cls'));
        $scheme->attach_colors_to_entities($tree);
        cmp_store(
            obj => $tree, method => 'store_figtree',
            file => 'PBP3_phylum_4color.nex',
            test => 'wrote expected taxonomically-annotated tree',
        );
     }
}

{
    my $infile   = file('test', 'PBP3.tre');

    my $outfile  = file('test', "my_PBP3.tre");
    my $outfile1 = file('test', 'my_PBP3-color.txt');
    my $outfile2 = file('test', 'my_PBP3-range.txt');
    my $outfile3 = file('test', 'my_PBP3-label.txt');
    my $outfile4 = file('test', 'my_PBP3-collapse.txt');

    my $color_file = file('test', 'PBP3-color.txt');
    my $range_file = file('test', 'PBP3-range.txt');
    my $label_file = file('test', 'PBP3-label.txt');
    my $colps_file = file('test', 'PBP3-collapse.txt');

    my $tree = Bio::MUST::Core::Tree->load($infile);
    $tax->attach_taxonomies_to_terminals($tree);
    $tax->attach_taxonomies_to_internals($tree);
    $tax->attach_taxa_to_entities($tree, {     name => 'phylum',
                                           collapse => 'phylum' } );

    my $scheme = $tax->load_color_scheme( file('test', 'bacteria.cls') );
    $scheme->attach_colors_to_entities($tree);
    $tree->collapse_subtrees;

    $outfile1->remove;
    $outfile2->remove;
    $outfile3->remove;
    $outfile4->remove;

    $tree->store_itol_datasets($outfile);
     compare_ok($outfile1, $color_file,
         "wrote expected iTOL color file: $color_file");
     compare_ok($outfile2, $range_file,
         "wrote expected iTOL range file: $range_file");
     compare_ok($outfile3, $label_file,
         "wrote expected iTOL label file: $label_file");
     compare_ok($outfile4, $colps_file,
         "wrote expected iTOL collapse file: $colps_file");
}

{
    my $infile   = file('test', 'OG0000464-edit-MMETSP172.tre');

    my $outfile  = file('test', 'my_OG0000464-edit-MMETSP172.tre');
    my $outfile1 = file('test', 'my_OG0000464-edit-MMETSP172-color.txt');
    my $outfile2 = file('test', 'my_OG0000464-edit-MMETSP172-range.txt');
    my $outfile3 = file('test', 'my_OG0000464-edit-MMETSP172-label.txt');
    my $outfile4 = file('test', 'my_OG0000464-edit-MMETSP172-collapse.txt');

    my $color_file = file('test', 'OG0000464-edit-MMETSP172-color.txt');
    my $range_file = file('test', 'OG0000464-edit-MMETSP172-range.txt');
    my $label_file = file('test', 'OG0000464-edit-MMETSP172-label.txt');
    my $colps_file = file('test', 'OG0000464-edit-MMETSP172-collapse.txt');

    my $collapse_key = ( my $annotate_key = 'taxon_label' );

    my $tree = Bio::MUST::Core::Tree->load($infile);
    $tax->attach_taxonomies_to_terminals($tree);
    $tax->attach_taxonomies_to_internals($tree);
    $tax->attach_taxa_to_entities($tree, {     name => 'no rank',
                                           collapse => 'no rank' } );

    my $scheme = $tax->load_color_scheme(file('test', 'colors-itol-euka.txt'));
    $scheme->attach_colors_to_entities($tree);
    $tree->collapse_subtrees($collapse_key);

    $outfile1->remove;
    $outfile2->remove;
    $outfile3->remove;
    $outfile4->remove;

    $tree->store_itol_datasets($outfile, $annotate_key);
     compare_ok($outfile1, $color_file,
         "wrote expected iTOL color file: $color_file");
     compare_ok($outfile2, $range_file,
         "wrote expected iTOL range file: $range_file");
     compare_ok($outfile3, $label_file,
         "wrote expected iTOL label file: $label_file");
     compare_ok($outfile4, $colps_file,
         "wrote expected iTOL collapse file: $colps_file");
}

# {
#     use Bio::Phylo::Treedrawer;
#     my $td = Bio::Phylo::Treedrawer->new(
#             -width  => 400,
#             -height => 600,
#             -shape  => 'RECT',
#             -mode   => 'CLADO',
#             -format => 'PDF',
#     );
#     $td->set_padding(50);

#   $td->set_tree($tree->tree);
#   open my $out1, '>', file('test', 'test1.pdf');
#   print {$out1} $td->draw;

#   $tax->attach_taxa_to_entities($tree, 'family');
#   $tree->switch_attributes_and_labels('taxon');

#   $td->set_tree($tree->tree);
#   open my $out2, '>', file('test', 'test2.pdf');
#   print {$out2} $td->draw;
#
#   $tax->attach_taxa_to_entities($tree, 'class');
#   $tree->switch_attributes_and_labels('taxon');
#   $td->set_tree($tree->tree);
#   open my $out3, '>', file('test', 'test3.pdf');
#   print {$out3} $td->draw;
#
#   $tax->attach_taxa_to_entities($tree, 'phylum');
#   $tree->switch_attributes_and_labels('taxon');
#   $td->set_tree($tree->tree);
#   open my $out4, '>', file('test', 'test4.pdf');
#   print {$out4} $td->draw;
# }

done_testing;
