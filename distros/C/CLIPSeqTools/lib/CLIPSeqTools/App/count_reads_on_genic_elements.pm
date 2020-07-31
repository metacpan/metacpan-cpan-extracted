=head1 NAME

CLIPSeqTools::App::count_reads_on_genic_elements - Count reads on transcripts, genes, exons, introns

=head1 SYNOPSIS

clipseqtools count_reads_on_genic_elements [options/parameters]

=head1 DESCRIPTION

Counts library reads on transcripts, genes, exons, introns.

* Transcript counts are measured only on their exons.
* Gene counts are measured only for exonic regions.

Output (4 files): counts.gene.tab, counts.transcript.tab, counts.exon.tab, counts.intron.tab - (name, location, length, count, count_per_nt, exonic_count, exonic_length, exonic_count_per_nt)

=head1 OPTIONS

  Input options for library.
    --driver <Str>         driver for database connection (eg. mysql,
                           SQLite).
    --database <Str>       database name or path to database file for file
                           based databases (eg. SQLite).
    --table <Str>          database table.
    --host <Str>           hostname for database connection.
    --user <Str>           username for database connection.
    --password <Str>       password for database connection.
    --records_class <Str>  type of records stored in database.
    --filter <Filter>      filter library. May be used multiple times.
                           Syntax: column_name="pattern"
                           e.g. keep reads with deletions AND not repeat
                                masked AND longer than 31
                                --filter deletion="def" 
                                --filter rmsk="undef" .
                                --filter query_length=">31".
                           Operators: >, >=, <, <=, =, !=, def, undef

  Other input
    --gtf <Str>            GTF file with genes/transcripts.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut


package CLIPSeqTools::App::count_reads_on_genic_elements;
$CLIPSeqTools::App::count_reads_on_genic_elements::VERSION = '0.1.10';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with 
	"CLIPSeqTools::Role::Option::Library" => {
		-alias    => { validate_args => '_validate_args_for_library' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::Genes" => {
		-alias    => { validate_args => '_validate_args_for_genes' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};

	
#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;
	
	$self->_validate_args_for_library;
	$self->_validate_args_for_genes;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;
	
	warn "Starting analysis: count_reads_on_genic_elements\n";
	
	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();
	
	warn "Creating gene collection\n" if $self->verbose;
	my $gene_collection = $self->gene_collection;
	
	warn "Creating transcript collection\n" if $self->verbose;
	my $transcript_collection = $self->transcript_collection;
	
	warn "Creating reads collection\n" if $self->verbose;
	my $reads_collection = $self->reads_collection;

	warn "Calculating transcript and exon/intron counts\n" if $self->verbose;
	my $counter = 1;
	$transcript_collection->foreach_record_do( sub {
		my ($transcript) = @_;
		
		# Calculate exon and transcript counts. Transcript counts is calculated by the exonic region only
		my $transcript_exonic_count = 0;
		foreach my $exon (@{$transcript->exons}) {
			my $exon_count = $reads_collection->total_copy_number_for_records_contained_in_region($exon->strand, $exon->chromosome, $exon->start, $exon->stop);
			$exon->extra({count => $exon_count});
			$transcript_exonic_count += $exon_count;
		}
		
		# Calculate intron counts.
		my $transcript_intronic_count = 0;
		foreach my $intron (@{$transcript->introns}) {
			my $intron_count = $reads_collection->total_copy_number_for_records_contained_in_region($intron->strand, $intron->chromosome, $intron->start, $intron->stop);
			$intron->extra({count => $intron_count});
			$transcript_intronic_count += $intron_count;
		}
		
		my $transcript_count = $reads_collection->total_copy_number_for_records_contained_in_region($transcript->strand, $transcript->chromosome, $transcript->start, $transcript->stop);
		
		$transcript->extra({
			count          => $transcript_count,
			exonic_count   => $transcript_exonic_count,
			intronic_count => $transcript_intronic_count
		});
		
		if ($self->verbose and ($counter % 5000 == 0)){
			warn "Parsed $counter transcripts\n";
		}
		$counter++;
		
	});
	
	warn "Calculating gene counts\n" if $self->verbose;
	$gene_collection->foreach_record_do( sub {
		my ($gene) = @_;
		
		my $gene_exonic_count = 0;
		foreach my $exonic_region ($gene->all_exonic_regions) {
			$gene_exonic_count += $reads_collection->total_copy_number_for_records_contained_in_region($exonic_region->strand, $exonic_region->chromosome, $exonic_region->start, $exonic_region->stop);
		}
		my $gene_count = $reads_collection->total_copy_number_for_records_contained_in_region($gene->strand, $gene->chromosome, $gene->start, $gene->stop);
		
		$gene->extra({
			count        => $gene_count,
			exonic_count => $gene_exonic_count
		});
	});
	
	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();
	
	warn "Printing gene counts\n" if $self->verbose;
	open(my $OUT1, '>', $self->o_prefix.'counts.gene.tab');
	say $OUT1 join("\t", 'gene_name', 'gene_location', 'gene_length', 'gene_count', 'gene_count_per_nt', 'gene_exonic_count', 'gene_exonic_length', 'gene_exonic_count_per_nt');
	$gene_collection->foreach_record_do( sub {
		my ($gene) = @_;
		
		say $OUT1 join("\t", $gene->name, $gene->location, $gene->length, $gene->extra->{count}, $gene->extra->{count} / $gene->length, $gene->extra->{exonic_count}, $gene->exonic_length, $gene->extra->{exonic_count} / $gene->exonic_length );
	});
	close $OUT1;

	warn "Printing transcript counts\n" if $self->verbose;
	open(my $OUT2, '>', $self->o_prefix.'counts.transcript.tab');
	say $OUT2 join("\t", 'transcript_id', 'transcript_location', 'transcript_length', 'gene_name', 'transcript_count', 'transcript_count_per_nt', 'transcript_exonic_count', 'transcript_exonic_length', 'transcript_exonic_count_per_nt', 'transcript_intronic_count', 'transcript_intronic_length', 'transcript_intronic_count_per_nt');
	$transcript_collection->foreach_record_do( sub {
		my ($transcript) = @_;
		
		my $intronic_count_per_nt = $transcript->intronic_length > 0 ? $transcript->extra->{intronic_count} / $transcript->intronic_length : 'NA';
		
		say $OUT2 join("\t", $transcript->id, $transcript->location, $transcript->length, $transcript->gene->name, $transcript->extra->{count}, $transcript->extra->{count} / $transcript->length, $transcript->extra->{exonic_count}, $transcript->exonic_length, $transcript->extra->{exonic_count} / $transcript->exonic_length, $transcript->extra->{intronic_count}, $transcript->intronic_length, $intronic_count_per_nt);
	});
	close $OUT2;
	
	warn "Printing exon counts\n" if $self->verbose;
	open(my $OUT3, '>', $self->o_prefix.'counts.exon.tab');
	say $OUT3 join("\t", 'transcript_id', 'exon_location', 'exon_length', 'gene_name', 'exon_count', 'exon_count_per_nt');
	$transcript_collection->foreach_record_do( sub {
		my ($transcript) = @_;
		
		foreach my $part (@{$transcript->exons}) {
			say $OUT3 join("\t", $transcript->id, $part->location, $part->length, $transcript->gene->name, $part->extra->{count}, $part->extra->{count} / $part->length);
		}
	});
	close $OUT3;
	
	warn "Printing intron counts\n" if $self->verbose;
	open(my $OUT4, '>', $self->o_prefix.'counts.intron.tab');
	say $OUT4 join("\t", 'transcript_id', 'intron_location', 'intron_length', 'gene_name', 'intron_count', 'intron_count_per_nt');
	$transcript_collection->foreach_record_do( sub {
		my ($transcript) = @_;
		
		foreach my $part (@{$transcript->introns}) {
			say $OUT4 join("\t", $transcript->id, $part->location, $part->length, $transcript->gene->name, $part->extra->{count}, $part->extra->{count} / $part->length);
		}
	});
	close $OUT4;
}


1;
