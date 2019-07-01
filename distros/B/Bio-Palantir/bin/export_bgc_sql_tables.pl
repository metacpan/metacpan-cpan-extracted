#!/usr/bin/env perl
# PODNAME: export_bgc_sql_tables.pl
# ABSTRACT: Exports SQL tables of BGC data (Palantir and antiSMASH annotations)
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Carp;
use Const::Fast;
use Data::UUID;
use DBI;
use GD::Simple;
use Getopt::Euclid qw(:vars);
use File::Basename qw(fileparse);
use File::ShareDir qw(dist_dir);
use File::Temp;
use Path::Class qw(dir file);
use POSIX;

use Bio::Palantir::Parser;
use Bio::MUST::Core;

use aliased 'Bio::FastParsers::Hmmer::DomTable';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::Palantir::Parser';
use aliased 'Bio::Palantir::Refiner::ClusterPlus';


const my $DATA_PATH => dist_dir('Bio-Palantir') . '/';

unless (@ARGV_infiles || $ARGV_file_table) {
    croak 'Error: use of --xml-reports or --file-table is needed';
}

if (@ARGV_types) {
    Parser->is_cluster_type_ok(@ARGV_types);
}

# SQLite database creation

# delete the previous database
if ($ARGV_new_db) {
    my $cmd = 'rm -rf ' . $ARGV_db_name . ' ' . $ARGV_db_name . '_tables/';
    system $cmd;
}

# connect to SQLite database
my $dsn = "DBI:SQLite:$ARGV_db_name";
my %attr = (PrintError=>0, RaiseError=>1);
 
my $dbh = DBI->connect($dsn,'', '', \%attr);

my @stmts = <<'EOT' =~ m/(CREATE .*? \) \;)/xmsg;
CREATE TABLE IF NOT EXISTS Clusters (
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
type            TEXT       NOT NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
lineage         TEXT       NOT NULL,
FOREIGN KEY(lineage) REFERENCES lineages(id)
);
CREATE TABLE IF NOT EXISTS Genes ( 
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
name            TEXT       NOT NULL,
smcog           TEXT       NULL,
bgc_type        TEXT       NULL,
domains_detail  TEXT       NULL,
monomers        TEXT       NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
cluster         TEXT       NOT NULL,
FOREIGN KEY(cluster) REFERENCES clusters(id),
FOREIGN KEY(id)   REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Modules ( 
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
domains         TEXT       NOT NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
cluster         TEXT       NOT NULL,
FOREIGN KEY(cluster) REFERENCES clusters(id),
FOREIGN KEY(id)   REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Domains (
id              TEXT       NOT NULL    PRIMARY KEY,
base_id         TEXT       NULL,
rank            INTEGER    NOT NULL,
activity        TEXT       NULL,
chemistry       TEXT       NULL,
monomer         TEXT       NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
module          TEXT       NOT NULL,
gene            TEXT       NOT NULL,
FOREIGN KEY(module) REFERENCES modules(id),
FOREIGN KEY(gene)   REFERENCES genes(id),
FOREIGN KEY(id)     REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Genes_plus ( 
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
name            TEXT       NOT NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
cluster         TEXT       NOT NULL,
FOREIGN KEY(cluster) REFERENCES clusters(id),
FOREIGN KEY(id)   REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Domains_plus (
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
activity        TEXT       NULL,
chemistry       TEXT       NULL,
monomer         TEXT       NULL,
subtype         TEXT       NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
evalue          INTEGER    NOT NULL,
score           INTEGER    NOT NULL,
subtype_evalue  TEXT       NULL,
subtype_score   TEXT       NULL,
base_id         TEXT       NULL,
module          TEXT       NOT NULL,
gene            TEXT       NOT NULL,
FOREIGN KEY(module) REFERENCES modules_plus(id),
FOREIGN KEY(gene)   REFERENCES genes_plus(id),
FOREIGN KEY(id)     REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Modules_plus ( 
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NOT NULL,
domains         TEXT       NOT NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
cluster         TEXT       NOT NULL,
FOREIGN KEY(cluster) REFERENCES clusters(id),
FOREIGN KEY(id)   REFERENCES sequences(id)
);
CREATE TABLE IF NOT EXISTS Sequences (
id              TEXT       NOT NULL    PRIMARY KEY,
sequence        TEXT       NOT NULL,
size            INTEGER    NOT NULL
);
CREATE TABLE IF NOT EXISTS Lineages (
id              TEXT        NOT NULL    PRIMARY KEY,
taxid           INTEGER     NULL,
lineage         TEXT        NULL,
superkingdom    TEXT        NULL,
phylum          TEXT        NULL,
class           TEXT        NULL,
ordre           TEXT        NULL,
family          TEXT        NULL,
genus           TEXT        NULL,
species         TEXT        NULL,
strain          TEXT        NULL
);
CREATE TABLE IF NOT EXISTS Domains_explus (
id              TEXT       NOT NULL    PRIMARY KEY,
rank            INTEGER    NULL,
activity        TEXT       NULL,
chemistry       TEXT       NULL,
monomer         TEXT       NULL,
subtype         TEXT       NULL,
size            INTEGER    NOT NULL,
coordinates     TEXT       NOT NULL,
begin           INTEGER    NOT NULL,
end             INTEGER    NOT NULL,
evalue          INTEGER    NOT NULL,
score           INTEGER    NOT NULL,
subtype_evalue  TEXT       NULL,
subtype_score   TEXT       NULL,
base_id         TEXT       NULL,
gene            TEXT       NOT NULL,
FOREIGN KEY(gene)   REFERENCES genes_plus(id),
FOREIGN KEY(id)     REFERENCES sequences(id)
);
EOT

if ($ARGV_quast) {
    push @stmts, <<'EOT', 
CREATE TABLE IF NOT EXISTS Assemblies (
id                     TEXT     NOT NULL    PRIMARY KEY,
n_contigs_gt0          INTEGER  NOT NULL,
n_contigs_gt1000       INTEGER  NOT NULL,
tot_length_gt0         INTEGER  NOT NULL,
tot_length_gt1000      INTEGER  NOT NULL,
n_contigs              INTEGER  NOT NULL,
largest_contig         INTEGER  NOT NULL,
tot_length             INTEGER  NOT NULL,
GC_content             INTEGER  NOT NULL,
N50                    INTEGER  NOT NULL,
N75                    INTEGER  NOT NULL,
L50                    INTEGER  NOT NULL,
L75                    INTEGER  NOT NULL,
Ns_per_100kbp          INTEGER  NOT NULL,
br_n_contigs_gt0       INTEGER  NULL,
br_n_contigs_gt1000    INTEGER  NULL,
br_tot_length_gt0      INTEGER  NULL,
br_tot_length_gt1000   INTEGER  NULL,
br_n_contigs           INTEGER  NULL,
br_largest_contig      INTEGER  NULL,
br_tot_length          INTEGER  NULL,
br_GC_content          INTEGER  NULL,
br_N50                 INTEGER  NULL,
br_N75                 INTEGER  NULL,
br_L50                 INTEGER  NULL,
br_L75                 INTEGER  NULL,
br_Ns_per_100kbp       INTEGER  NULL,
FOREIGN KEY (id) REFERENCES clusters(lineage)
);
EOT
}

# initialize the database with table statements
for my $stmt (@stmts) {
    $dbh->do($stmt);
}

# fill the SQL tables
my %table_for;

# optionally use an idm file to connect genomes/proteomes and antiSMASH report filenames
my %accession_for;
if ($ARGV_idm_file) {
    open my $in, '<', $ARGV_idm_file;

    my @idm_ext = qw(.faa .fna .fa);

    while (my $line = <$in>) {
        
        chomp $line; 

        my ($id, $accession) = split "\t", $line;
        $id = fileparse($id, @idm_ext);

        $accession_for{$id} = $accession;
    }
}

# handle paths table
my (@infiles, @prot_files, @quast_files);

if ($ARGV_file_table) {
    open my $handle, '<', $ARGV_file_table;

    chomp(my @lines = <$handle>);

    @infiles   = map{ (split "\t", $_)[0] } @lines;
    @prot_files  = map{ (split "\t", $_)[1] } @lines
        if $ARGV_proteomes;
    @quast_files = map{ (split "\t", $_)[2] } @lines
        if $ARGV_quast;
}


# integrate each file report into the SQL tables
my $i = 0; 
for my $infile ($ARGV_file_table ? @infiles : @ARGV_infiles) {

    ### Reading of: $infile
    
    my @xml_ext = qw(_ensembl.xml _ncbi.xml _lm.xml .xml);
    my ($base, $dir, $suffix) = fileparse($infile, @xml_ext);

    # generate Lineage table and get lineage_id
    my $lineage_id = get_lineageid_and_fill_lineage_table($base);


    # load antiSMASH report
    my $parser = Parser->new( file => $infile);
    my $root = $parser->root;

    my @clusters = $root->all_clusters;
    my @clusters_plus = map { 
        ClusterPlus->new( 
            _cluster => $_,
            gap_filling => $ARGV_gap_filling,
            undef_cleaning => $ARGV_undef_cleaning,
        )
    } @clusters;

    # generate BGC tables
    fill_bgc_tables('antismash', $lineage_id, \%table_for, \@clusters);
    fill_bgc_tables('palantir' , $lineage_id, \%table_for, \@clusters_plus);
 
    if ($ARGV_quast) {

        my @quast_elmts = $lineage_id;
       
        my $infile = $quast_files[$i];
        open my $in, '<', $infile;

        while (my $line = <$in>) {
            
            chomp $line;
            
            next if $line =~ m/^Assembly \t/xms;    

            my @chunks = split "\t", $line;

            push @quast_elmts, @chunks[1..(scalar @chunks - 1)];   # skip assembly name column 
        }

        unless (@quast_elmts[13..26]) {
            $quast_elmts[$_] = 'No Ns' for 13..26;
        }
        push @{ $table_for{'Assemblies'} }, join "\t", @quast_elmts;
    }

} 

# ### %table_for

# write tables
my $db_dir = $ARGV_db_name . '_tables/';
mkdir $db_dir unless -d $db_dir;

for my $table (keys %table_for) {
    open my $out, '>>', $db_dir . $table;
    for (@{ $table_for{$table} }) { say {$out} $_};
}

# disconnect from the database
$dbh->disconnect;

say 'all is good!';


sub get_lineageid_and_fill_lineage_table {

    my $defline = shift;

    # Lineages table
    my ($lineage_id, @lineage_elmts);
    if ($ARGV_taxdir) {
    
        # get taxonomic informations
        my $tax = Taxonomy->new(
                tax_dir   => $ARGV_taxdir,
                save_mem  => 1,
                fuzzy_map => 1,
        );

        my ($gca) = $defline =~ m/ (GC[AF] \_ \d{9} \. \d) /xmsi;
        $gca = $defline =~ m/taxid(\d+)/xmsi 
            unless $gca;
         
        if ($ARGV_idm_file && ! defined $gca) {
                $gca = $accession_for{$defline};
        }
        
        my ($org) = $defline =~ m/ ( [^\_\.]* \_  [^\_\.]*) /xms;

        my ($taxid, @lineages);
        if ($gca) {
            
            @lineages =  $tax->get_taxonomy($gca);
            
            $org = $lineages[-1] =~ tr/ /_/r;
            $taxid = $tax->get_taxid_from_seq_id( $org . '@1') // 'na';
            
            push @lineage_elmts,
                $taxid, (join ',', @lineages), 
                (map { $lineages[$_] } (1, 2, 3)),
                (map { $tax->get_term_at_level($gca, $_) }
                    qw(order family genus species)),
                    $lineage_elmts[-1],
            ;

            $lineage_id = $gca;
        }

        elsif ($org) {

            $taxid = $tax->get_taxid_from_seq_id($org . '@1');

            if ($taxid) {

                @lineages =  $tax->get_taxonomy($taxid);
                
                push @lineage_elmts,
                    $taxid, (join ',', @lineages),
                    (map { $lineages[$_] } (1, 2, 3)),
                    (map { $tax->get_term_at_level($taxid, $_) } 
                        qw(order family genus species)),
                        $lineage_elmts[-1],
                ;
            }

            $lineage_id = $defline;
        }    
         

        else {
            $lineage_id = $defline;
        }
    }

    else {
        $lineage_id = $defline;
    }
    
    unshift @lineage_elmts, $lineage_id;
    
    if (@lineage_elmts < 10) {
        push @lineage_elmts, (('NULL') x 10);
    }

    push @{ $table_for{'Lineages'} }, join "\t", @lineage_elmts;

    return ($lineage_id);
}

sub fill_bgc_tables {

    my ($annotation, $lid, $table_ref, $ref_clusters) = @_;

    my $suffix = $annotation eq 'palantir'
        ? '_plus'
        : ''
    ;

    my $ug = Data::UUID->new;

    CLUSTER:
    for my $cluster (@$ref_clusters) {

        #TODO make an option to allow others? -> need to create new uui for genes and maybe domains that are used several times
        #TODO use the same loop (with fix&proceed for additional information) for Parser and Refiner
        if (@ARGV_types) {
            next CLUSTER unless
                grep { $cluster->type =~ m/$_/xmsi } @ARGV_types;
        }

        # keep root uui for clusters and clusters_plus
        my $cluster_uui =
            $cluster->meta->name eq 'Bio::Palantir::Refiner::ClusterPlus'
            ? $cluster->_cluster->uui
            : $cluster->uui
        ;

        # to not duplicate Cluster data in the SQL table
        if ($annotation eq 'antismash') {
            my @cluster_elmts = (
                $cluster_uui, $cluster->rank, $cluster->type, 
                $cluster->genomic_prot_size, 
                (join '-', @{ $cluster->genomic_prot_coordinates }), 
                $cluster->genomic_prot_begin, $cluster->genomic_prot_end,
                $lid,
            );
            
            @cluster_elmts = map { $_ // 'na' } @cluster_elmts;
            push @{ $table_ref->{'Clusters'} }, join "\t", @cluster_elmts;
        }

        # treat genes containing modules and note them to no repeat action
        my %module_uui_for;
        my @modules = $cluster->all_modules;
        if (@modules) {

            Module:
            for my $module (sort { $a->rank <=> $b->rank } @modules) {

                my @module_elmts = (
                    $module->uui, $module->rank, 
                    (join '-',  @{ $module->get_domain_functions }), 
                    $module->size, 
                    (join '-', @{ $module->genomic_prot_coordinates }),
                    $module->genomic_prot_begin, $module->genomic_prot_end, 
                    $cluster_uui,
                );

                @module_elmts = map { $_ // 'na' } @module_elmts;

                $module_uui_for{$_->uui} 
                    = $module->uui for @{ $module->domains };

                push @{ $table_ref->{'Modules' . $suffix} }, 
                    join "\t", @module_elmts;

                push @{ $table_ref->{'Sequences'} }, join "\t", 
                    ($module->uui, $module->protein_sequence, $module->size);
            }
        }

        # filter duplicated genes (taken in several clusters) TODO improve this... not clean
        my @done_uuis;

        GENE:
        for my $gene ( sort { $a->rank <=> $b->rank } $cluster->all_genes) {

            # TODO need to generate uuid here because some genes are included in different clusters sometimes
            next GENE if grep { $_ eq $gene->uui } @done_uuis;
            
            my $gene_uui = $ug->create_str; # For duplicated genes (t3pks in t1pks,...) TODO what to do ? duplicated ids because of overlapping clusters otherwise

            my @gene_elmts;
            if ($annotation eq 'antismash') {
                @gene_elmts = (
                    $gene_uui, $gene->rank, $gene->name, 
                    $gene->smcog, $gene->type, $gene->domains_detail, 
                    (join '; ', $gene->monomers), $gene->genomic_prot_size, 
                    (join '-', @{ $gene->genomic_prot_coordinates }),
                    $gene->genomic_prot_begin, $gene->genomic_prot_end, 
                    $cluster_uui,
                );
            }

            else {
                @gene_elmts = (
                    $gene->uui, $gene->rank, $gene->name, 
                    $gene->genomic_prot_size, 
                    (join '-', @{ $gene->genomic_prot_coordinates }), 
                    $gene->genomic_prot_begin, $gene->genomic_prot_end, 
                    $cluster_uui,
                );
            }    
            
            @gene_elmts = map { $_ // 'na' } @gene_elmts;
            push @{ $table_ref->{'Genes' . $suffix} }, join "\t", @gene_elmts;

            DOMAIN:
            for my $domain (sort { $a->rank <=> $b->rank } $gene->all_domains) {
                
                my $domain_uui = $ug->create_str;

                my $function = $domain->function;
               
               my (@domain_elmts, @domain_explus_elmts);
               if ($annotation eq 'antismash') {
                 
                    unless ($function && $ARGV_undef_recov == 0) {
                       get_function($domain->protein_sequence);
                    }

                    @domain_elmts = (
                        $domain_uui, $domain->uui, $domain->rank, $function,
                        $domain->chemistry, $domain->monomer, $domain->size,
                        (join '-', @{ $domain->coordinates }), $domain->begin,
                        $domain->end, $module_uui_for{$domain->uui} // 'null',
                        $gene_uui,
                    );
                }

                else {
                
                    @domain_elmts = (
                        $domain->uui, $domain->rank, $domain->symbol,
                        $domain->chemistry, $domain->monomer, $domain->subtype,
                        $domain->size, (join '-', @{ $domain->coordinates }),
                        $domain->begin, $domain->end, $domain->evalue,
                        $domain->score, $domain->subtype_evalue,
                        $domain->subtype_score, $domain->base_uui,
                        $module_uui_for{$domain->uui} // 'null', $gene->uui,
                    );

                    @domain_explus_elmts = (
                        $domain->uui, $domain->rank, $domain->symbol, 
                        $domain->chemistry, $domain->monomer, $domain->subtype,
                        $domain->size, (join '-', @{ $domain->coordinates }),
                        $domain->begin, $domain->end, $domain->evalue,
                        $domain->score, $domain->subtype_evalue, 
                        $domain->subtype_score, $domain->base_uui, $gene->uui,
                    );

                    @domain_explus_elmts
                        = map { $_ // 'na' } @domain_explus_elmts;

                    push @{ $table_ref->{'Domains_explus'} }, join "\t",
                        @domain_explus_elmts;

                    push @{ $table_ref->{'Sequences'} }, join "\t", 
                        ($domain->uui, $domain->protein_sequence, 
                        $domain->size)
                    ;
                }

                @domain_elmts = map { $_ // 'na' } @domain_elmts;

                push @{ $table_ref->{'Domains' . $suffix} }, 
                    join "\t", @domain_elmts;

                push @{ $table_ref->{'Sequences'} }, join "\t", 
                    ($domain_uui, $domain->protein_sequence, $domain->size);
            }

            push @done_uuis, $gene_uui; 
        }

    }

    return;
}

sub get_function {
    my $seq = shift;
    my $hmmdb = $DATA_PATH . 'generic_domains.hmm';

    my $tbout = do_hmmscan($seq, $hmmdb);

    #parsing of  domtblout hmmscan report 
    my $report = DomTable->new( file => $tbout->filename );

    my %hit_for;
    my $evalue_threshold = 10e-3;
    my $hit_i = 1;

    HIT:
    while (my $hit = $report->next_hit) {

        next HIT if $hit->evalue > $evalue_threshold;

        $hit_for{'hit' . $hit_i} = { map { $_ => $hit->$_ } 
            qw(query_name target_name ali_from ali_to hmm_from 
                hmm_to tlen qlen) 
        };

        $hit_for{'hit' . $hit_i}{score}  = $hit->dom_score;
        $hit_for{'hit' . $hit_i}{evalue} = $hit->i_evalue;     # i-value = independent evalue ('evalue' return cumulative evalues for the sequence, and c-evalue may be deleted because potentially e-value)
        $hit_i++;
    }

    my $best_hit = (sort { $hit_for{$b}{score} <=> $hit_for{$a}{score} } 
        keys %hit_for)[0];

    my $function = $hit_for{$best_hit}{target_name};

    my $activity = 
    $function =~ m/^A$ | AMP-binding | A-OX/xms ? 'A' : 
    $function =~ m/^PCP | PP-binding/xms ? 'PCP' : 
    $function =~ m/^C$ | Condensation | ^X$ | Cglyc | Cter/xms ? 'C' :
    $function =~ m/^E$ | Epimerization/xms ? 'E' :
    $function =~ m/^H$ | Heterocyclization/xms ? 'H' :
    $function =~ m/^TE$ | Thioesterase/xmsi ? 'Te' :
    $function =~ m/^Red$ | ^TD$ /xmsi ? 'Red' : 
    $function =~ m/Aminotran/xms ? 'Amt' :
    $function =~ m/^PKS_/xms ? $function =~ s/PKS_// :
    $function;  # no need to reappoint domains like cMT, oMT, B, Hal,... 

    return $activity;
}

sub do_hmmscan {
    my ($seq, $hmmdb) = @_; 

    my $template = 'tempfile_XXXXXXXXXX';
    my $query = File::Temp->new($template, suffix => '.faa'); 
    print $query '>query' . "\n" . $seq;

    my $pgm = 'hmmscan';

    my $tbout = File::Temp->new($template, suffix => '_domtblout.tsv');
    my $opt = ' --domtblout ' . $tbout . ' --cpu ' . $ARGV_cpu;

    my $cmd = "$pgm $opt $hmmdb $query"; 
    system $cmd;

    return $tbout;
}

__END__

=pod

=head1 NAME

export_bgc_sql_tables.pl - Exports SQL tables of BGC data (Palantir and antiSMASH annotations)

=head1 VERSION

version 0.191800

=head1 NAME

export_bgc_sql_tables.pl - This tool exports SQL tables structuring the BGC data
from antiSMASH reports and annotated with Palantir.

=head1 USAGE

    $0 [options] --infiles [=] <report_paths>.../--file-table [=] <report.list>

=head1 REQUIRED ARGUMENTS

=over

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --infiles [=] <report_paths>...

Paths to biosynML.xml (antiSMASH 3-4) or regions.js (antiSMASH 5) files.
This option can takes multiple values.

=item --file-table [=] <tsv_file>

TSV (Tab-Separated Values) format file to give non ambiguously the path
of xml reports, proteomes and quast files. Order : xml reports (1st column),
proteomes (2nd column) and quast files (3rd column). If you only want to parse
xml and quast reports, you can follow this format : "biosynML.xml    undef
quast.tsv".

=item --types [=] <str>...

Filter clusters on a/several specific type(s). 

Types allowed: acyl_amino_acids, amglyccycl, arylpolyene, bacteriocin, 
butyrolactone, cyanobactin, ectoine, hserlactone, indole, ladderane, 
lantipeptide, lassopeptide, microviridin, nrps, nucleoside, oligosaccharide, 
otherks, phenazine, phosphonate, proteusin, PUFA, resorcinol, siderophore, 
t1pks, t2pks, t3pks, terpene.

Any combination of these types, such as nrps-t1pks or t1pks-nrps, is also
allowed. The argument is repeatable.

=item --taxdir [=] <dir>

Path to a local mirror of the NCBI Taxonomy database.

=item --idm[-file] [=] <file>

Path to an id mapper file to retrieve the assembly accession numbers. The
file should be in tabular format with accession numbers in the second column.

=item --proteomes

Use organism proteome to predict with external pHMMs domains to include in SQL
database.

=item --quast

Create an additionnal table "Assemblies" with Quast statistics. For this
option, you need to use the transposed_report.tsv output of quast and name it
with the basename of your report file. For example, if you use my_org.xml, name
your Quast file my_org.tsv.

=item --new-db

Remove the previous sql tables to start over the db.

=item --db-name [=] <str>

Name of your database [default: bgc_db].

=for Euclid: str.type: str
    str.default: 'bgc_db'

=item --gap-filling [=] <bool>

Tries to find domains if gaps present in clusters [default: 1].

=for Euclid: bool.type: num 
    bool.default: 1

=item --undef-cleaning [=] <bool>

Eliminates undef domains from antiSMASH output that can't be recovered
[default: 1].

=for Euclid: bool.type: num 
    bool.default: 1

=item --undef-recov [=] <bool>

Try to recover antismash undef domain values [default: 0].

=for Euclid: bool.type: num 
    bool.default: 0

=item --evalue-threshold [=] <n>

E-value threshold to apply in HMMER searches [default: 1e-4].

=for Euclid: n.type: num 
    n.default: 1e-4

=item --cpu [=] <n>

Number of threads/cpus to use [default: 1].

=for Euclid: n.type: int 
    n.default: 1 

=item --version

=item --usage

=item --help

=item --man

print the usual program information

=back

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
