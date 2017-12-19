#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers;

my $qr_class = 'Bio::MUST::Drivers::Blast::Query';
my $db_class = 'Bio::MUST::Drivers::Blast::Database';
my $db_tmp_class = 'Bio::MUST::Drivers::Blast::Database::Temporary';


# skip all BLAST tests unless blastp is available in the $PATH
unless ( qx{which blastp} ) {
    plan skip_all => <<"EOT";
skipped all BLAST tests!
If you want to use this module you need to install NCBI BLAST+ executables:
ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
EOT
}

my $basename;
my $filename;
my $report_m6;
my $report_xml;

{
    my $db = $db_tmp_class->new( seqs => file('test', 'protdb.fasta') );
    cmp_ok $db->type, 'eq', 'prot', 'got expected -db_type';
    $basename = $db->filename;
    ok(-e "$basename.$_", "wrote db file with expected suffix: $_")
        for qw(phr pin psq);
    explain $basename;

    my $query = $qr_class->new( seqs => file('test', 'protquery.fasta') );
    $filename = $query->filename;
    explain $filename;

    # HTML format
    my $report_html = $query->blast($db, {
        -html   => undef,
        -evalue => 1e-50,
    } );
    ok $report_html =~ m/\.html\z/xms, "wrote HTML report: $report_html";

    # tabular format
    my $tab_parser = $query->blast($db, {
        -evalue => 1e-10,
    } );
    isa_ok($tab_parser, 'Bio::FastParsers::Blast::Table');

    $report_m6 = $tab_parser->filename;
    explain $report_m6;
    compare_filter_ok $report_m6, file('test', 'report.blastp.m6'),
        \&filter, 'wrote expected tabular BLASTP report';
    $tab_parser->remove;

    # XML format
    my $xml_parser = $query->blast($db, {
        -evalue => 1e-10,
        -outfmt => 5,
    } );
    isa_ok($xml_parser, 'Bio::FastParsers::Blast::Xml');

    cmp_ok $xml_parser->blast_output->count_iterations, '==', 7,
        'got expected number of iterations';

    $report_xml = $xml_parser->filename;
    explain $report_xml;
    compare_filter_ok $report_xml, file('test', 'report.blastp.xml'),
        \&filter, 'wrote expected XML BLASTP report';
    $xml_parser->remove;
}
ok(!-e "$basename.$_", "deleted db file with expected suffix: $_")
    for qw(phr pin psq);
ok(!-e $filename,   'deleted query file');
ok(!-e $report_m6,  'deleted tabular report file');
ok(!-e $report_xml, 'deleted XML report file');

{
    my $db = $db_class->new( file => 'nt', remote => 1 );
    cmp_ok $db->type, 'eq', 'nucl', 'got expected -db_type';
    $basename = $db->filename;
    explain $basename;

    my $query = $qr_class->new( seqs => file('test', 'nuclquery.fasta') );
    $filename = $query->filename;
    explain $filename;

    my $parser = $query->blast($db, {
        '-entrez_query' => q{'Euglenozoa[ORGN]'},
        '-evalue'       => 1e-250,
        '-outfmt'       => 7,
    } );
    isa_ok($parser, 'Bio::FastParsers::Blast::Table');

    my $hsp_count = 0;
    while ($parser->next_hsp) {
        $hsp_count++;
    }
    cmp_ok $hsp_count, '==', 8, 'got expected number of remote HSPs';

    my $report = $parser->filename;
    explain $report;
    compare_filter_ok $report, file('test', 'report.blastn.m7'),
        \&filter, 'wrote expected tabular report after remote BLASTN';
    $parser->remove;
}

{
    my $db = $db_class->new( file => file('test', 'prebuiltdb') );
    cmp_ok $db->type, 'eq', 'prot', 'got expected -db_type';
    $basename = $db->filename;
    ok(-e "$basename.$_", "found db file with expected suffix: $_")
        for qw(phr pin psq pog psi psd);
    explain $basename;

    my @ids = qw(gnl|Ca|29376464 gnl|Mg|16801896 gnl|Cu|29375460);
    my $seqs = $db->blastdbcmd( \@ids );
    cmp_ok $seqs->count_seqs, '==', 3, 'fetched expected number of seqs';
}

# TODO: test other BLAST variants and options?

sub filter {
    my $line = shift;
    $line =~ s{\t\ +}{\t}xmsg;      # normalize whitespace
    $line =~ s{\ +\t}{\t}xmsg;      # normalize whitespace

    return q{} if $line =~ m/BlastOutput_version/xms;
    return q{} if $line =~ m/BlastOutput_db/xms;

    return q{} if $line =~ m/RID:/xms;

    return $line;
}

done_testing;
