##test case using genbank as data source

use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;

BEGIN { 
	use_ok('Bio::Draw::FeatureStack'); 
	use_ok('Bio::DB::SeqFeature::Store'); 
	use_ok('Bio::Graphics::Glyph::decorated_gene'); 
	use_ok('Bio::Graphics::Glyph::decorated_transcript'); 
	use_ok('Bio::Graphics');
	{
		local $SIG{__WARN__} = sub { };  # suppress some strange warning of use statement...
		use_ok('Bio::SeqIO;');	
	} 
	use_ok('Bio::SeqFeature::Tools::Unflattener'); 
};

lives_ok { figure1() }  'Generation of genbank figure';

sub figure1
{
	my $output_basename = "t/images/genbank";
	
	my @gene_names = (qw (t/data/genbank_file1.gb)); #AH013929.2 Z48783.1 

	my @features = load_features(\@gene_names);

	my $feature_stack = new Bio::Draw::FeatureStack
	(
		-features => \@features,
		-glyph => 'decorated_gene',
		-panel_params => {
							-width => 1024,
							-pad_left => 80,
							-pad_right => 20
		},
		-glyph_params => {
							-description => 1,
							-label => 1,
							-sub_part => 'exon',  # Unflattener creates exon subparts, not CDS
							-decoration_visible => 1,
							-decoration_color => 'yellow'
						 }
	);

	my $png = $feature_stack->png;
	ok ($png, "PNG $output_basename" );
		
	my $png_file = $output_basename.".png";
	system("rm $png_file") if (-e $png_file);
	open(IMG,">$png_file") or die "could not write to file $png_file";
	print IMG $png;
	close(IMG);		
	ok (-e $png_file, "$png_file" );
	
}

sub load_features
{
	my $gene_names = shift;

	my @features;
		
	my $unflattener = Bio::SeqFeature::Tools::Unflattener->new;
	
	foreach my $name (@$gene_names)
	{
		my $db_obj = Bio::SeqIO->new(-file=>"$name", -format=>'Genbank');			
                   
		while (my $seq = $db_obj->next_seq()) {
			
			if (!defined $seq)
			{
				die "error in sequence of file\n";
				return ();
			}
	
			# unflatten flat genbank features into hierarchical gene structure
		  	$unflattener->unflatten_seq(-seq => $seq, -use_magic => 1);				
		  	     
		  	# grep gene and mRNA top-level features
			my @f = grep { $_->primary_tag =~ /(gene|mRNA)/ } $seq->top_SeqFeatures;
			
			# let's add some dummy decorations to first transcript...
			my $mrna = $f[0]->primary_tag eq 'mRNA' ? $f[0] : (grep { $_->primary_tag eq 'mRNA' } $f[0]->get_SeqFeatures)[0];
			$mrna->add_tag_value('protein_decorations', 'dummy:dummy:10:50:0') if ($mrna); 
			
			push(@features, @f);
		}
	}
	return @features;
}		

