use vars qw(%test_request @request_params %expected_counts %expected_idtypes @output_formats);

%test_request=(request_type=>'translate',
	       input_type=>'gene_entrez',
	       input_ids=>[2983,1829,5893,20383,93883],
	       output_types=>[qw(protein_ensembl peptide_pepatlas reaction_ec function_go gene_symbol_synonym)],
	       output_format=>'json');
@request_params=keys %test_request;

%expected_counts=(
		  93883 => 10,
		  5893 => 8,
		  2983 => 60,
		  20383 => 18,
		  1829 => 192
		  );


%idtypes_expected=('transcript_ensembl'=>  'Ensembl transcript id',
		   'protein_refseq'=> 'RefSeq protein id',
		   'probe_nu'=> 'nucleotide universal id',
		   'probe_lumi'=> 'Illumina probe id',
		   'function_omim'=> 'OMIM number',
		   'chip_lumi'=> 'Illumina array',
		   'gene_unigene'=> 'UniGene id',
		   'transcript_ncbi'=> 'GenBank transcript id',
		   'gene_symbol'=> 'gene symbol',
		   'protein_ncbi'=> 'NCBI protein id',
		   'gene_known'=> 'UCSC known gene id',
		   'organism_name_common'=> 'organism',
		   'transcript_refseq'=> 'RefSeq transcript id',
		   'protein_uniprot'=> 'UniProt id',
		   'chip_affy'=> 'Affymetrix array',
		   'probe_affy'=> 'Affymetrix probeset id',
		   'gene_description'=> 'gene description',
		   'sequence_affy'=> 'Affymetrix probeset sequence',
		   'gene_entrez'=> 'Entrez gene id',
		   'function_omim_description'=> 'OMIM description',
		   'protein_ensembl'=> 'Ensembl protein id',
		   'protein_ipi_description'=> 'IPI protein description',
		   'transcript_epcondb'=> 'EpconDB transcript id',
		   'sequence_nu'=> 'nucleotide universal id sequence',
		   'reaction_ec'=> 'EC number',
		   'peptide_pepatlas'=> 'Peptide Atlas id',
		   'function_go'=> 'GO id',
		   'protein_ipi'=> 'IPI id',
		   'gene_symbol_synonym'=> 'gene synonym',
		   'gene_ensembl'=> 'Ensembl gene id');

@output_formats=qw(tsv csv json xml);
