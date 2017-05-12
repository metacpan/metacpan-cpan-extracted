=head1 NAME

Bio::EBI::RNAseqAPI - A Perl interface to the EMBL-EBI RNA-seq analysis API.

=head1 DESCRIPTION

This module provides a Perl-based interface to the L<EMBL-EBI|http://www.ebi.ac.uk> L<RNA-seq analysis API|http://www.ebi.ac.uk/fg/rnaseq/api/>.

The RNA-seq Analysis API enables access to analysis results for thousands of
publicly available gene expression datasets. This module provides functions to
access each endpoint provided by the API.

For more information about the API, see its L<documentation|http://www.ebi.ac.uk/fg/rnaseq/api/doc>.

=head1 SYNOPSIS

 use 5.10.0;
 use Bio::EBI::RNAseqAPI;

 my $rnaseqAPI = Bio::EBI::RNAseqAPI->new;

 my $runInfo = $rnaseqAPI->get_runs_by_study(
    study => "E-MTAB-513", 
    minimum_mapped_reads => 0
 );

=cut

package Bio::EBI::RNAseqAPI;

use 5.10.0;

use Moose;
use MooseX::FollowPBP;
use LWP::UserAgent;
use Log::Log4perl qw( :easy );
use JSON::Parse qw( parse_json );

our $VERSION = 1.04;

=head1 ATTRIBUTES

=over 2

=cut

#=item B<api_base>

#Base URL for the EBI RNA-seq API. Default value, can be overridden.

#=cut

has 'api_base' => (
    is  => 'rw',
    isa => 'Str',
    default => "http://www.ebi.ac.uk/fg/rnaseq/api"
); 

#=item B<user_agent>

#LWP::UserAgent object with current user's proxy settings. Lazy build.

#=cut

has 'user_agent' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build  => 1
);

#=item B<log_writer>

#Log::Log4perl::Logger object, used for logging error messages. Lazy build.

#=cut

has 'log_writer' => (
    is  => 'rw',
    isa => 'Log::Log4perl::Logger',
    lazy_build  => 1
);

=item B<run_organism_list>

An anonymous hash containing allowed organism names for downloading run
information as keys. Access the contents like this:

 my $runOrganisms = $rnaseqAPI->get_run_organism_list;

=cut

has 'run_organism_list' => (
    is  => 'rw',
    isa => 'HashRef',
    lazy_build  => 1
);

=item B<expression_organism_list>

An anonymous hash containing allowed organism names for downloading gene
expression information as keys. Access the contents like this:

 my $expressionOrganisms = $rnaseqAPI->get_expression_organism_list;

=cut

has 'expression_organism_list' => (
    is  => 'rw',
    isa => 'HashRef',
    lazy_build => 1
);

=back

=head1 METHODS

=head2 Analysis results per sequencing run

These functions take arguments in the form of a hash. These usually
consist of a study accession, or one or more run accessions, plus a value for
"minimum_mapped_reads". This value represents the minimum percentage of mapped
reads to allow for each run in the results. Only information for runs with a
percentage of mapped reads greater than or equal to this value will be
returned. To get all available information, set "minimum_mapped_reads" to zero.

Analysis information for each run is returned in an anonymous hash. Some
functions return anonymous arrays with one anonymous hash per run found. See
below for examples and more information about the results.


=over 2

=item B<get_run>

Accesses the API's C<getRun> JSON endpoint and returns analysis information for
a single run, passed in the arguments.

Arguments should be passed as a hash containing values for "run" and
"minimum_mapped_reads", e.g.:

 my $runInfo = $rnaseqAPI->get_run(
    run => "ERR030885",
    minimum_mapped_reads => 0
 );

Run analysis information is returned in an anonymous hash. Returns C<undef> (and
logs errors) if errors are encountered.

An example of the hash returned is as follows:

 {
     'BIOREP_ID' => 'ERR030885',
     'RUN_IDS' => 'ERR030885',
     'REFERENCE_ORGANISM' => 'homo_sapiens',
     'MAPPING_QUALITY' => 96,
     'ASSEMBLY_USED' => 'GRCh38',
     'ORGANISM' => 'homo_sapiens',
     'BEDGRAPH_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/ERR030/ERR030885/ERR030885.bedgraph',
     'ENA_LAST_UPDATED' => 'Mon Aug 18 2014 13:40:46',
     'STUDY_ID' => 'ERP000546',
     'BIGWIG_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/ERR030/ERR030885/ERR030885.bw',
     'CRAM_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/ERR030/ERR030885/ERR030885.cram',
     'LAST_PROCESSED_DATE' => 'Sun Jul 12 2015 23:31:47',
     'STATUS' => 'Complete',
     'SAMPLE_IDS' => 'SAMEA962348'
 }

=cut

sub get_run {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;
    
    unless( $self->_hash_arguments_ok( \%args, "run", "minimum_mapped_reads" ) ) {

        $logger->error(
            "Problem with arguments to \"get_run\" function."
        );

        return;
    }

    my $restResult = $self->_run_rest_call(
        {
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getRun",
            function_argument => $args{ "run" }
        }
    );

    if( $restResult ) {

        my ( $runInfo ) = @{ $restResult };

        return $runInfo;
    }
    else {

        $logger->error(
            "No result found for run ",
            $args{ "run" }
        );

        return;
    }
}


=item B<get_runs_by_list>

This function takes an anonymous array of run accessions and sequentially
accesses the API's C<getRun> JSON endpoint to collect the analysis information
for each run in the list provided.

 my $runInfo = $rnaseqAPI->get_runs_by_list(
    runs => [ "ERR030885", "ERR030886" ],
    minimum_mapped_reads => 0
 );

Run analysis information is returned as an anonymous array containing one
anonymous hash per run (see L</get_run> documentation for an example of what the
anonymous hash looks like). Returns C<undef> (and logs errors) if errors are
encountered.

=cut

sub get_runs_by_list {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;
    
    unless( $self->_hash_arguments_ok( \%args, "runs", "minimum_mapped_reads" ) ) {

        $logger->error(
            "Problem with arguments to \"get_runs_by_list\" function."
        );

        return;
    }

    # Make sure the run accessions are in an array ref.
    eval { my @runAccessions = @{ $args{ "runs" } } };

    if( $@ ) {
        
        $logger->error(
            "get_runs_by_list requires run accession(s) to be provided as an array reference."
        );

        return;
    }

    my @allRunInfo = ();

    foreach my $runAcc ( @{ $args{ "runs" } } ) {

        my $restResult = $self->get_run( 
            run => $runAcc,
            minimum_mapped_reads => $args{ "minimum_mapped_reads" }
        );
        
        if( $restResult ) {
            
            push @allRunInfo, $restResult;
        }
    }
    
    unless( scalar @allRunInfo ) {

        $logger->error(
            "No results found for any runs."
        );

        return;
    }

    return \@allRunInfo;
}


=item B<get_runs_by_study>

Accesses the API's C<getRunsByStudy> JSON endpoint, and returns an anonymous array
containing an anonymous hash for each run found (see L</get_run> docs for an example).

 my $runInfo = $rnaseqAPI->get_runs_by_study(
    study => "E-MTAB-513",
    minimum_mapped_reads => 0
 );

Study accession can be either an L<ENA|http://www.ebi.ac.uk/ena>,
L<SRA|http://www.ncbi.nlm.nih.gov/sra>, L<DDBJ|http://www.ddbj.nig.ac.jp/> or
L<ArrayExpress|http://www.ebi.ac.uk/arrayexpress> study accession. The example
above uses an ArrayExpress experiment accession. Examples of ENA, SRA or DDBJ
accessions are "ERP000546" or "SRP013533" or "DRP000391", respectively.

Returns C<undef> (and logs errors) if errors are encountered.

=cut

sub get_runs_by_study {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;
    
    unless( $self->_hash_arguments_ok( \%args, "study", "minimum_mapped_reads" ) ) {

        $logger->error(
            "Problem with arguments to \"get_runs_by_study\" function."
        );

        return;
    }
    
    my $restResult = $self->_run_rest_call( 
        {
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getRunsByStudy",
            function_argument => $args{ "study" }
        }
    );

    if( $restResult ) {

        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving runs for ",
            $args{ "study" }
        );
    }
}


=item B<get_runs_by_organism>

Accesses the API's C<getRunsByOrganism> JSON endpoint, and returns an anonymous
array containing an anonymous hash for each run found.

 my $runInfo = $rnaseqAPI->get_runs_by_organism(
    organism => "homo_sapiens",
    minimum_mapped_reads => 70
 );

Value for "organism" attribute is a species scientific name, in lower case,
with underscores instead of spaces. E.g. "homo_sapiens",
"canis_lupus_familiaris", "oryza_sativa_japonica_group". To ensure your
organism name is allowed, check against the L</run_organism_list> attribute:

 my $organism = "oryctolagus_cuniculus";
 my $organismList = $rnaseqAPI->get_run_organism_list;
 if( $organismList->{ $organism } ) {
     say "Found $organism!";
 }

Results are returned as an anonymous array containing an anonymous hash for each
run found. Returns C<undef> (and logs errors) if errors are encountered.

=cut

sub get_runs_by_organism {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;

    unless( $self->_hash_arguments_ok( \%args, "organism", "minimum_mapped_reads" ) ) {

        $logger->error(
            "Problem with arguments to \"get_runs_by_organism\" function."
        );

        return;
    }
    
    # Fail if the organism isn't recognised.
    unless( $self->_organism_name_ok( $args{ "organism" }, "run" ) ) {

        return;
    }
    
    my $restResult = $self->_run_rest_call(
        {
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getRunsByOrganism",
            function_argument => $args{ "organism" }
        }
    );

    if( $restResult ) {

        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving runs for ",
            $args{ "organism" }
        );
    }
}


=item B<get_runs_by_organism_condition>

Accesses the API's C<getRunsByOrganismCondition> JSON endpoint, and returns an
anonymous array containing an anonymous hash for each run found. An organism
name and a "condition" -- meaning a sample attribute -- are passed in the
arguments. The condition must exist in the L<Experimental Factor Ontology (EFO)|http://www.ebi.ac.uk/efo>; this can
be checked via the EFO website or via the L<Ontology Lookup Service (OLS) API|http://www.ebi.ac.uk/ols/docs/api>.


 my $runInfo = $rnaseqAPI->get_runs_by_organism_condition(
    organism => "homo_sapiens",
    condition => "central nervous system",
    minimum_mapped_reads => 70
 );

See L</get_runs_by_organism> docs for how to check organism name format and availability.

Returns C<undef> (and logs errors) if errors are encountered.

=cut

sub get_runs_by_organism_condition {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;
    
    unless( $self->_hash_arguments_ok( \%args, "organism", "minimum_mapped_reads", "condition" ) ) {

        $logger->error(
            "Problem with arguments to \"get_runs_by_organism_condition\" function."
        );

        return;
    }
    
    # Fail if the organism isn't recognised.
    unless( $self->_organism_name_ok( $args{ "organism" }, "run" ) ) {

        return;
    }
    
    my $restResult = $self->_run_rest_call(
        {
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getRunsByOrganismCondition",
            function_argument => $args{ "organism" } . "/" . $args{ "condition" }
        }
    );

    if( $restResult ) {
        
        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving runs for organism \"",
            $args{ "organism" },
            "\" with condition \"",
            $args{ "condition" }
        );
    }
}


=back

=head2 Analysis results per study

These functions take an L<ENA|http://www.ebi.ac.uk/ena>, L<SRA|http://www.ncbi.nlm.nih.gov/sra>, L<DDBJ|http://www.ddbj.nig.ac.jp/> or L<ArrayExpress|http://www.ebi.ac.uk/arrayexpress> accession or species name and return information about the corresponding dataset(s).

=over 2

=item B<get_study>

Accesses the API's C<getStudy> JSON endpoint. Single argument is a study
accession (L<ENA|http://www.ebi.ac.uk/ena>, L<SRA|http://www.ncbi.nlm.nih.gov/sra>, L<DDBJ|http://www.ddbj.nig.ac.jp/> or L<ArrayExpress|http://www.ebi.ac.uk/arrayexpress>). Returns an anonymous hash
containing the results for the matching study. Returns C<undef> (and logs
errors) if errors are encountered. If you try an ArrayExpress accession and it
doesn't work, try the corresponding sequencing archive study accession instead.

 my $studyInfo = $rnaseqAPI->get_study( "SRP033494" );

An example of the anonymous hash returned is as follows:

 {
     'GTF_USED' => 'Arabidopsis_thaliana.TAIR10.26.gtf.gz',
     'ORGANISM' => 'arabidopsis_thaliana',
     'STATUS' => 'Complete',
     'ASSEMBLY_USED' => 'TAIR10',
     'LAST_PROCESSED_DATE' => 'Thu Jun 30 2016 19:55:56',
     'GENES_FPKM_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/genes.rpkm.tsv',
     'EXONS_FPKM_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/exons.rpkm.tsv',
     'GENES_TPM_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/genes.tpm.tsv',
     'SOFTWARE_VERSIONS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/irap.versions.tsv',
     'REFERENCE_ORGANISM' => 'arabidopsis_thaliana',
     'STUDY_ID' => 'SRP033494',
     'EXONS_RAW_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/exons.raw.tsv',
     'GENES_RAW_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/genes.raw.tsv',
     'EXONS_TPM_COUNTS_FTP_LOCATION' => 'ftp://ftp.ebi.ac.uk/pub/databases/arrayexpress/data/atlas/rnaseq/studies/ena/SRP033494/exons.tpm.tsv'
 } 

=cut

sub get_study {

    my ( $self, $studyAcc ) = @_;

    my $logger = $self->get_log_writer;

    unless( $studyAcc ) {

        $logger->error(
            "get_study requires a study accession as an argument."
        );

        return;
    }

    my $restResult = $self->_run_rest_call(
        {
            function_name => "getStudy",
            function_argument => $studyAcc
        }
    );

    if( $restResult ) {

        my ( $studyInfo ) = @{ $restResult };

        return $studyInfo;
    }
    else {

        $logger->error(
            "Problem retrieving study ",
            $studyAcc
        );
    }
}

=item B<get_studies_by_organism>

Accesses the API's C<getStudiesByOrganism> JSON endpoint. Single argument is the
name of an organism (see the L</run_organism_list> attribute for allowed names).
Returns an anonymous array containing one anonymous hash per study found. See
L</get_study> docs for an example of an anonymous hash.

 my $studies = $rnaseqAPI->get_studies_by_organism( "arabidopsis_thaliana" );

=cut

sub get_studies_by_organism {

    my ( $self, $organism ) = @_;

    my $logger = $self->get_log_writer;

    unless( $organism ) {

        $logger->error(
            "get_studies_by_organism requires organism as an argument."
        );

        return;
    }

    # Fail if the organism isn't recognised.
    unless( $self->_organism_name_ok( $organism, "run" ) ) {

        return;
    }
    
    my $restResult = $self->_run_rest_call(
        {
            function_name => "getStudiesByOrganism",
            function_argument => $organism
        }
    );

    if( $restResult ) {

        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving study information for ",
            $organism
        );
    }
}


=back

=head2 Sample attributes per run

These functions return information about the sample attributes that runs are
annotated with. Sample attributes have a "type", e.g. "organism", and a
"value", e.g. "Homo sapiens". Where possible, the URI of the matching ontology term
is also annotated.

=over 2

=item B<get_sample_attributes_by_run>

Accesses the API's C<getSampleAttributesByRun> JSON endpoint. Single argument is
the accession of the run. Returns an anonymous array containing one anonymous
hash per sample attribute found.

 my $sampleAttributes = $rnaseqAPI->get_sample_attributes_by_run( "SRR805786" );

An example of the results returned is as follows:

 [
    {
        'VALUE' => 'peripheral blood mononuclear cells (PBMCs)',
        'EFO_URL' => 'NA',
        'STUDY_ID' => 'SRP020492',
        'TYPE' => 'cell type',
        'RUN_ID' => 'SRR805786'
    },
    {
        'STUDY_ID' => 'SRP020492',
        'TYPE' => 'organism',
        'RUN_ID' => 'SRR805786',
        'VALUE' => 'Homo sapiens',
        'EFO_URL' => 'http://purl.obolibrary.org/obo/NCBITaxon_9606'
    },
 ]

EFO_URL is not always present and will be "NA" if it is not.

Returns C<undef> (and logs errors) if errors are encountered.

=cut

sub get_sample_attributes_by_run {

    my ( $self, $runAcc ) = @_;

    my $logger = $self->get_log_writer;

    unless( $runAcc ) {

        $logger->error(
            "get_sample_attributes_by_run requires a run accession as an argument."
        );

        return;
    }

    my $restResult = $self->_run_rest_call(
        {
            function_name => "getSampleAttributesByRun",
            function_argument => $runAcc
        }
    );

    if( $restResult ) {

        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving sample attributes for run ",
            $runAcc
        );
    }
}

=item B<get_sample_attributes_per_run_by_study>

Accesses the API's C<getSampleAttributesPerRunByStudy> JSON endpoint. Single
argument is a study accession. Returns an array ref containing one anonymous
hash per sample attribute. See L</get_sample_attributes_by_run> docs for an
example. Returns C<undef> (and logs errors) if errors are encountered.

 my $sampleAttributes = $rnaseqAPI->get_sample_attributes_per_run_by_study( "DRP000391" );

=cut

sub get_sample_attributes_per_run_by_study {

    my ( $self, $studyAcc ) = @_;

    my $logger = $self->get_log_writer;

    unless( $studyAcc ) {

        $logger->error(
            "get_sample_attributes_per_run_by_study requires a study accession as an argument."
        );

        return;
    }

    my $restResult = $self->_run_rest_call(
        {
            function_name => "getSampleAttributesPerRunByStudy",
            function_argument => $studyAcc
        }
    );

    if( $restResult ) { 

        return $restResult;
    }
    else {
        
        $logger->error(
            "Problem retrieving sample attributes for ",
            $studyAcc
        );
    }
}

=item B<get_sample_attributes_coverage_by_study>

Accesses the API's C<getSampleAttributesCoverageByStudy> endpoint. Single argument
is a study accession. Returns an anonymous array containing one anonymous hash
per sample attribute. Returns C<undef> (and logs errors) if errors are
encountered.

 my $sampleAttributeCoverage = $rnaseqAPI->get_sample_attributes_coverage_by_study( "DRP000391" );

An example of the results is as follows:

 [
    {
        'VALUE' => 'Nipponbare',
        'STUDY_ID' => 'DRP000391',
        'PCT_OF_ALL_RUNS' => 100,
        'NUM_OF_RUNS' => 28,
        'TYPE' => 'cultivar'
    },
    {
        'VALUE' => 'Oryza sativa Japonica Group',
        'STUDY_ID' => 'DRP000391',
        'PCT_OF_ALL_RUNS' => 100,
        'NUM_OF_RUNS' => 28,
        'TYPE' => 'organism'
    },
    {
        'VALUE' => '7 days after germination',
        'STUDY_ID' => 'DRP000391',
        'PCT_OF_ALL_RUNS' => 29,
        'NUM_OF_RUNS' => 8,
        'TYPE' => 'developmental stage'
    }
 ]

=cut

sub get_sample_attributes_coverage_by_study {

    my ( $self, $studyAcc ) = @_;

    my $logger = $self->get_log_writer;

    unless( $studyAcc ) {

        $logger->error(
            "get_sample_attributes_coverage_by_study requires a study accession as an argument."
        );

        return;
    }

    my $restResult = $self->_run_rest_call(
        {
            function_name => "getSampleAttributesCoverageByStudy",
            function_argument => $studyAcc
        }
    );

    if( $restResult ) { 

        return $restResult;
    }
    else {
        
        $logger->error(
            "Problem retrieving sample attributes for ",
            $studyAcc
        );
    }
}

=back

=head2 Baseline gene expression per tissue, cell type, developmental stage, sex, and strain

=over 2

=item B<get_expression_by_organism_genesymbol>

Accesses the API's C<getExpression> endpoint. Provide arguments as a hash,
passing an organism name and a gene symbol, as well as a value for the minimum
percentage of mapped reads to allow:

 my $geneExpressionInfo = $rnaseqAPI->get_expression(
    minimum_mapped_reads => 0,
    organism    => "oryza_sativa",
    gene_symbol => "BURP7"
 );

Results are returned as an anonymous array of anonymous hashes, with one
anonymous hash per unique combination of tissue, cell type, developmental
stage, sex, and strain. The median expression level of all runs is given in TPM
(transcripts per million). Returns C<undef> (and logs errors) if errors are
encountered.

An example of the results returned is as follows:

 [
    {
        'COEFFICIENT_OF_VARIATION' => '0.3',
        'STRAIN' => 'NA',
        'DEVELOPMENTAL_STAGE' => 'seedling, two leaves visible, three leaves visible',
        'CELL_TYPE' => 'NA',
        'SEX' => 'NA',
        'GENE_ID' => 'OS05G0217700',
        'MEDIAN_EXPRESSION' => '831.1',
        'NUMBER_OF_RUNS' => 60,
        'ORGANISM' => 'oryza_sativa',
        'ALL_SAMPLE_ATTRIBUTES' => 'http://www.ebi.ac.uk/fg/rnaseq/api/tsv/getSampleAttributesByCondition/3238',
        'ORGANISM_PART' => 'shoot, vascular leaf'
    },
    {
        'STRAIN' => 'NA',
        'DEVELOPMENTAL_STAGE' => '20 days after sowing',
        'COEFFICIENT_OF_VARIATION' => '0.3',
        'CELL_TYPE' => 'NA',
        'GENE_ID' => 'OS05G0217700',
        'SEX' => 'NA',
        'ORGANISM' => 'oryza_sativa',
        'NUMBER_OF_RUNS' => 4,
        'MEDIAN_EXPRESSION' => '433.5',
        'ALL_SAMPLE_ATTRIBUTES' => 'http://www.ebi.ac.uk/fg/rnaseq/api/tsv/getSampleAttributesByCondition/3192',
        'ORGANISM_PART' => 'leaf'
    },

=cut

sub get_expression_by_organism_genesymbol {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;
    
    unless( $self->_hash_arguments_ok( \%args, "minimum_mapped_reads", "organism", "gene_symbol" ) ) {

        $logger->error(
            "Problem with arguments to \"get_expression_by_organism_genesymbol\" function."
        );

        return;
    }
    # Fail if the organism isn't recognised.
    unless( $self->_organism_name_ok( $args{ "organism" }, "expression" ) ) {

        return;
    }
    
    my $restResult = $self->_run_rest_call(
        { 
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getExpression",
            function_argument => $args{ "organism" } . "/" . $args{ "gene_symbol" }
        }
    );

    if( $restResult ) {
        
        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving expression information for gene \"",
            $args{ "gene_symbol" },
            "\" in organism \"",
            $args{ "organism" }
        );
    }
}



=item B<get_expression_by_gene_id>

Accesses the API's C<getExpression> endpoint, but instead of querying by
organism and gene symbol (see L</get_expression_by_organism_genesymbol>), this
function queries by gene identifier. Also expects a value for the minimum
percentage of mapped reads to allow.

 my $geneExpressionInfo = $rnaseqAPI->get_expression(
    gene_identifer  => "ENSG00000172023",
    minimum_mapped_reads => 0
 );

Results are returned as an anonymous array of anonymous hashes, with one
anonymous hash per unique combination of tissue, cell type, developmental
stage, sex, and strain. See L</get_expression_by_organism_genesymbol> for an
example.  The median expression level of all runs is given in TPM (transcripts
per million). Returns C<undef> (and logs errors) if errors are encountered.

=cut

sub get_expression_by_gene_id {

    my ( $self, %args ) = @_;

    my $logger = $self->get_log_writer;

    unless( $self->_hash_arguments_ok( \%args, "minimum_mapped_reads", "gene_identifier" ) ) {

        $logger->error(
            "Problem with arguments to \"get_expression_by_gene_id\" function."
        );

        return;
    }
    
    my $restResult = $self->_run_rest_call(
        {
            minimum_mapped_reads => $args{ "minimum_mapped_reads" },
            function_name => "getExpression", 
            function_argument => $args{ "gene_identifier" }
        }
    );

    if( $restResult ) {

        return $restResult;
    }
    else {

        $logger->error(
            "Problem retrieving expression information for gene \"",
            $args{ "gene_identifier" },
            "\"."
        );
    }
}

=back

=cut


# Logger builder.
sub _build_log_writer {

    Log::Log4perl->easy_init(
        {
            level   => $INFO,
            layout  => '%-5p - %m%n'
        }
    );

    return Log::Log4perl::get_logger;
}

# User Agent builder.
sub _build_user_agent {

    my $userAgent = LWP::UserAgent->new;

    $userAgent->env_proxy;

    return $userAgent;
}

# Run organisms list builder. This is built by accessing the API's endpoints for
# the various genome reference resources it uses. Most of these are the
# divisions of Ensembl (http://www.ensembl.org and http://ensemblgenomes.org)
# -- core, plants, fungi, metazoa, and protists, as well as WormBase ParaSite
# (http://parasite.wormbase.org/). The endpoint for each resource provides
# key-value pairs of sample organism and reference organism, the reference
# organism being the name of the reference genome that was used in the
# alignment of RNA-seq reads, and the sample organism being the species the RNA
# sample was taken from. Here we collect all the sample organisms, add them as
# keys in an anonymous hash (pointing at 1), and return the anonymous hash.
sub _build_run_organism_list {

    my ( $self ) = @_;

    my $logger = $self->get_log_writer;

    my $organismList = {};

    my @genomeResources = (
        "ensembl",
        "plants",
        "fungi",
        "metazoa",
        "protists",
        "wbps"
    );

    # Download the lists of organisms from the API.
    foreach my $resource ( @genomeResources ) {
        
        my $restResult = $self->_run_rest_call(
            {
                minimum_mapped_reads => 0,
                function_name => "getOrganisms",
                function_argument => $resource
            }
        );

        if( $restResult ) {

            foreach my $record ( @{ $restResult } ) {
                
                # The sample organism is found under the key "ORGANISM".
                $organismList->{ $record->{ "ORGANISM" } } = 1;
            }
        }

        else {

            $logger->error(
                "Problem collecting ",
                $resource,
                " organism names from API."
            );
        }
    }
    
    return $organismList;
}


# Expression organisms list builder.
sub _build_expression_organism_list {

    my ( $self ) = @_;

    my $logger = $self->get_log_writer;

    my $exprOrganismList = {};

    my $restResult = $self->_run_rest_call(
        {
            function_name => "getExpressionOrganisms"
        }
    );

    if( $restResult ) {

        foreach my $record ( @{ $restResult } ) {

            $exprOrganismList->{ $record->{ "ORGANISM" } } = 1;
        }
    }
    else {

        $logger->error(
            "Problem collecting expression organism names from API."
        );
    }

    return $exprOrganismList;
}

# Check that arguments to functions that require a hash ref of named arguments
# are OK. This means:
#  - Check the variable is actually a hash.
#  - Make sure the arguments required by the calling function are present.
#  - Warn about any arguments that were provided that are not recognised by the
#  calling function.
sub _hash_arguments_ok {

    my $self = shift;

    my $logger = $self->get_log_writer;

    # Get the arguments hash from the first argument.
    my $argsHash = shift;

    # First, make sure the arguments are in a hash.
    unless( ref( $argsHash ) eq "HASH" ) {

        $logger->error(
            "Arguments should be provided as a hash. See POD for examples."
        );

        return;
    }
    # The rest of the @_ array is the names or the keys that should be present.
    my %wantedArgNames = map { $_ => 1 } @_;
    
    # Create a flag to unset if at least one wanted argument is missing.
    my $allWantedPresent = 1;
    
    # Check that all the arguments we want are present.
    foreach my $wantedArgName ( sort keys %wantedArgNames ) {

        unless( defined( $argsHash->{ $wantedArgName } ) ) {

            $logger->error(
                "Required argument \"",
                $wantedArgName,
                "\" is missing."
            );

            $allWantedPresent = 0;
        }
    }
    
    # Next, check whether there are any unrecognised arguments. Just warn about
    # them if so.
    foreach my $argName ( sort keys %{ $argsHash } ) {

        unless( $wantedArgNames{ $argName } ) {

            $logger->warn(
                "Argument \"",
                $argName,
                "\" is not recognised."
            );
        }
    }
    
    # Now return the flag to show whether all wanted arguments are present or
    # not.
    return $allWantedPresent;
}


# REST call running -- common to all the querying functions.
sub _run_rest_call {

    my ( $self, $args ) = @_;

    my $logger = $self->get_log_writer;

    my $userAgent = $self->get_user_agent;

    # Start building the query URL.
    my $url = $self->get_api_base . "/json/";
    
    # If we're passed a minimum percentage of mapped reads, add this to the URL
    # next.
    if( defined( $args->{ "minimum_mapped_reads" } ) ) {

        $url .= $args->{ "minimum_mapped_reads" } . "/";
    }
    
    # Add the function name and argument to the end of the URL.
    $url .= $args->{ "function_name" };

    if( $args->{ "function_argument" } ) {

        $url .= "/" . $args->{ "function_argument" };
    }

    # Run HTTP GET request.
    my $response = $userAgent->get( $url );

    # If the request was successful, return the parsed JSON.
    if( $response->is_success ) {

        return parse_json( $response->decoded_content );
    }
    # Otherwise, log an error and return undef.
    else {
        
        $logger->error(
            "Problem retrieving URL: ",
            $url,
            " . Response from server: ",
            $response->status_line
        );

        return;
    }
}


# Check that the run organism name is allowed. This checks the passed string
# against the keys of the hash stored in the "run_organism_list" attribute.
sub _organism_name_ok {

    my ( $self, $organism, $type ) = @_;

    my $logger = $self->get_log_writer;

    my $organismList = ( $type eq "run" ? $self->get_run_organism_list : $self->get_expression_organism_list );

    if( $organismList->{ $organism } ) {

        return 1;
    }
    else {

        $logger->error(
            "Organism \"",
            $organism,
            "\" is not an allowed organism. Check organisms against the run_organism_list attribute."
        );

        return;
    }
}


=head1 AUTHOR

Maria Keays <mkeays@cpan.org>

The above email should be used for feedback about the Perl module only. All
mail regarding the RNA-seq analysis API itself should be directed to
<rnaseq@ebi.ac.uk>.

=cut

1;

