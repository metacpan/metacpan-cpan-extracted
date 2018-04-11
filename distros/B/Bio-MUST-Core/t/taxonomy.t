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

my @valid_ids = (

    # viruses
    [ 'HIV-1 M:C_505006@210038491',     # Note the unusual names of viruses
        'Viruses; Retro-transcribing viruses; Retroviridae; Orthoretrovirinae; Lentivirus; Primate lentivirus group; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C; HIV-1 M:C U2226',
        'Viruses; Retro-transcribing viruses; Retroviridae; Orthoretrovirinae; Lentivirus; Primate lentivirus group; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C',
       ('Viruses; Retro-transcribing viruses; Retroviridae; Orthoretrovirinae; Lentivirus; Primate lentivirus group; Human immunodeficiency virus 1; HIV-1 group M; HIV-1 M:C; HIV-1 M:C U2226') x 3,
        q{'HIV-1 M:C U2226'},
        q{'HIV-1 M:C U2226 [210038491]'} ],

    # Archaea
    [ 'Methanobrevibacter ruminantium_634498@288561462',
        'cellular organisms; Archaea; Euryarchaeota; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium; Methanobrevibacter ruminantium M1',
        'cellular organisms; Archaea; Euryarchaeota; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium',
       ('cellular organisms; Archaea; Euryarchaeota; Methanobacteria; Methanobacteriales; Methanobacteriaceae; Methanobrevibacter; Methanobrevibacter ruminantium; Methanobrevibacter ruminantium M1') x 3,
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
        'cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfotomaculum; Desulfotomaculum gibsoniae; Desulfotomaculum gibsoniae DSM 7213',
        'cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfotomaculum; Desulfotomaculum gibsoniae',
       ('cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Clostridia; Clostridiales; Peptococcaceae; Desulfotomaculum; Desulfotomaculum gibsoniae; Desulfotomaculum gibsoniae DSM 7213') x 3,
        q{'Desulfotomaculum gibsoniae DSM 7213'},
        q{'Desulfotomaculum gibsoniae DSM 7213 [357041591]'} ],

    # Eukaryota
    [ 'Arabidopsis halleri_81971@184160085',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [184160085]'} ],
    [ 'Arabidopsis halleri_63677@63056225',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. gemmifera',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. gemmifera') x 3,
        q{'Arabidopsis halleri subsp. gemmifera'},
        q{'Arabidopsis halleri subsp. gemmifera [63056225]'} ],
    [ 'Arabidopsis halleri_81970@ABB29495.1',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri') x 3,
        q{'Arabidopsis halleri'},
        q{'Arabidopsis halleri [ABB29495.1]'} ],
    [ 'Arabidopsis halleri_halleri@78182999',
        '',     # legacy id without taxon_id (but alignable)
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [78182999]'} ],
    [ 'Arabidopsis halleri_halleri@ABB29495.1',
        '',     # legacy id without taxon_id (but alignable)
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri; Arabidopsis halleri subsp. halleri') x 3,
        q{'Arabidopsis halleri subsp. halleri'},
        q{'Arabidopsis halleri subsp. halleri [ABB29495.1]'} ],
    [ 'Arabidopsis lyrata_81972@297836718',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata; Arabidopsis lyrata subsp. lyrata',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis lyrata; Arabidopsis lyrata subsp. lyrata') x 3,
        q{'Arabidopsis lyrata subsp. lyrata'},
        q{'Arabidopsis lyrata subsp. lyrata [297836718]'} ],
    [ 'Arabidopsis thaliana_3702@15224717',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana') x 3,
        q{'Arabidopsis thaliana'},
        q{'Arabidopsis thaliana [15224717]'} ],
    [ 'Noccaea caerulescens_107243@326416416',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Coluteocarpeae; Noccaea; Noccaea caerulescens') x 3,
        q{'Noccaea caerulescens'},
        q{'Noccaea caerulescens [326416416]'} ],

    # valid ids with merged taxon_ids in NCBI Taxonomy
    [ 'Synedra acus_191585@123456',
        'cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus',
        'cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus',
       ('cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Fragilariophyceae; Fragilariophycidae; Licmophorales; Ulnariaceae; Ulnaria; Ulnaria acus') x 3,
        q{'Ulnaria acus'},
        q{'Ulnaria acus [123456]'} ],
    [ 'Oscillatoriales cyanobacterium_627090@ABCDEF',
        'cellular organisms; Bacteria; Terrabacteria group; Cyanobacteria/Melainabacteria group; Cyanobacteria; unclassified Cyanobacteria; [Leptolyngbya] sp. JSC-1',
        '',
       ('cellular organisms; Bacteria; Terrabacteria group; Cyanobacteria/Melainabacteria group; Cyanobacteria; unclassified Cyanobacteria; [Leptolyngbya] sp. JSC-1') x 3,
        q{'[Leptolyngbya] sp. JSC-1'},
        q{'[Leptolyngbya] sp. JSC-1 [ABCDEF]'} ],
    [ 'Fistulifera sp._880758@xyz789',
        'cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera solaris',
        'cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera sp.',
       ('cellular organisms; Eukaryota; Stramenopiles; Bacillariophyta; Bacillariophyceae; Bacillariophycidae; Naviculales; Naviculaceae; Fistulifera; Fistulifera solaris') x 3,
        q{'Fistulifera solaris'},
        q{'Fistulifera solaris [xyz789]'} ],

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
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri',
        '',
       ('cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis halleri') x 3,
        q{'Arabidopsis halleri'},
        q{'Arabidopsis halleri [ABB29495.1]'},
    ],

    # NCBI FASTA-style foreign ids
    # skipped by default to avoid build GI-to-taxid mapper
#     [ 'gi|404160475',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
#         q{'Anthurium andraeanum'},
#         q{'Anthurium andraeanum [404160475]'} ],
#     [ 'gi|404160475|gb|AFR53081.1|',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
#         q{'Anthurium andraeanum'},
#         q{'Anthurium andraeanum [AFR53081.1]'} ],
#     [ 'gi|404160475|gb|AFR53081.1| AOX [Anthurium andraeanum]',
#         '', '', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Alismatales; Araceae; Pothoideae; Potheae; Anthurium; Anthurium andraeanum',
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

{
    for my $exp_row (@valid_ids) {
        my $seq_id = Bio::MUST::Core::SeqId->new( full_id => $exp_row->[0] );
        my @taxonomy = $tax->get_taxonomy_from_seq_id($seq_id);
        my $lineage  = join '; ', @taxonomy;
        my $got_row = [
            $seq_id->full_id,
            join('; ', $tax->get_taxonomy($seq_id->taxon_id)),
            join('; ', $tax->get_taxonomy_from_name($seq_id->org)),
            $lineage,
            join('; ', $tax->get_taxonomy_from_seq_id( \@taxonomy )),
            join('; ', $tax->get_taxonomy_from_seq_id($lineage)),
            $tax->get_nexus_label_from_seq_id($seq_id),
            $tax->get_nexus_label_from_seq_id($seq_id, { append_acc => 1 } ),
        ];  # Note: warnings are expected here
        is_deeply $got_row, $exp_row,
            'Fetched expected taxonomic information from valid SeqId';
    }
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
        my $scheme = Bio::MUST::Core::ColorScheme->load(file('test', 'bacteria.cls'));
        $scheme->attach_colors_to_entities($tree);
        cmp_store(
            obj => $tree, method => 'store_figtree',
            file => 'PBP3_phylum_4color.nex',
            test => 'wrote expected taxonomically-annotated tree',
        );
     }
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
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae; BOP clade',
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
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; Liliopsida; Petrosaviidae; commelinids; Poales; Poaceae',
    ],
    [
        [ '+Arabidopsis thaliana', '+Brachypodium distachyon' ],
        [
            'Arabidopsis thaliana_3702@7269912',
            'Brachypodium distachyon_15368@357123620',
        ],
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae',
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae',
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
        'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae',
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
        'Podocoryne carnea',                # misspelling    (should be 1)
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

    my @exp_cats = ('strict', ('loose') x 5);

    # classify Ali files
    for my $num ( qw(392 590 593 618 639 649) ) {
        my $infile = file('test', "GNTPAN19$num.ali");
        my $ali = Bio::MUST::Core::Ali->load($infile);
        my $cat = $classifier->classify($ali) // q{undef};
        cmp_ok $cat, 'eq', shift @exp_cats,
            "rightly classified $infile as $cat";
    }
}

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

SKIP: {
    skip 'due to defaulting to prefer_gca', 2;
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

{
    my $frfile = file('test', 'lifemrch.fra');
    my $classifier = $tax->classifier_from_systematic_frame($frfile);

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

my @lcas = (
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales; Brassicaceae; Camelineae; Arabidopsis; Arabidopsis thaliana', 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; malvids; Brassicales', 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons', 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta', 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina', 1 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae; Streptophyta', 0 ],
    [ 'Arabidopsis thaliana_3702@1', 'cellular organisms; Eukaryota; Viridiplantae', 0 ],
);

{
    my $frfile = file('test', 'debrief42-accurate.fra');

    # TODO: fix warnings due to residual dupes
    # Warning: Actinobacteria is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Elusimicrobia is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Thermotogae is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Aquificae is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Chrysiogenetes is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Deferribacteres is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Thermodesulfobacteria is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.
    # Warning: Gemmatimonadetes is taxonomically ambiguous in tax_filter! at constructor Bio::MUST::Core::Taxonomy::Filter::new (defined at /Users/denis/Dropbox/Private/Development/Perl/Bio-MUST-Core/lib/Bio/MUST/Core/Taxonomy/Filter.pm line 125) line 64.

    my $classifier = $tax->classifier_from_systematic_frame($frfile);

    for my $exp_row (@lcas) {
        my ($org, $lca, $exp) = @{$exp_row}[0..2];
        cmp_ok $tax->eq_tax($org, $lca, $classifier), '==', $exp,
            "got expected result for eq_tax with $lca";
    }
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
