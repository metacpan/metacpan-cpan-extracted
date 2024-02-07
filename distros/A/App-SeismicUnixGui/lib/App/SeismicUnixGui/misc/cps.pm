package App::SeismicUnixGui::misc::cps;

=head1 DOCUMENTATION

=head2 SYNOPSIS 
 Auxiliar modules for Computer
 Programs in Seismology by 
 Hermann (2013)

 PROGRAM NAME: 
 AUTHOR: Juan Lorenzo
 DATE:   V 0.0.1 January 2024
         
 DESCRIPTION: 

 =head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 NOTES  

=head4 CHANGES and their DATES

=cut

use PDL;
use Moose;
our $VERSION = '0.0.1';

use App::SeismicUnixGui::misc::pm_io '0.0.1';
use aliased 'App::SeismicUnixGui::misc::pm_io';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';


=head2 

Define private hash
to share

=cut

my $cps = {
	_directory_in => '',
	_file_in      => '',
	_pathNfile_in => '',
};


=head2 Instantiation

=cut

my $pm_io = pm_io->new();
my $file  = manage_files_by2->new();

=head2 sub set_file_in

=cut 

sub set_file_in {
	
   my ($self, $file_in) = @_;
    
   $pm_io->set_file_in($file_in);
   
   return();
}

=head2 sub set_directory_in

=cut 

sub set_directory_in {
	
   my ($self, $file_in) = @_;
    
   $pm_io->set_directory_in($file_in);
   
   return();
}

=head2 sub get_fileNpath_in

=cut 

sub _get_pathNfile_in {
	
   my ($self) = @_;
    
   $cps->{_pathNfile_in} = $pm_io->get_pathNfile_in();
#   my $a = $cps->{_pathNfile_in};
#   print("cps->{_pathNfile_in}:$a\n");
   
   return($cps->{_pathNfile_in});
}
		

=head2 sub read a model file

=cut

sub get_model {
	
	my ($self) = @_;
	
=head2 

Definitions

=cut
	
	my $inbound   = _get_pathNfile_in();
#	print("$inbound\n");
	my $skip      = 12;
	my $row_aref2 = $file->get_10cols_aref( $inbound, $skip );
	my @row_aref  = @$row_aref2;
	my $num_rows  = scalar @row_aref;
	my $num_pdl   = 0;
	my $data_list_pdl;

	for ( my $i = 0 ; $i < $num_rows ; $i++ ) {

		my @data_block = @{ $row_aref[$i] };
		my @data_list  = split( '\s+', $data_block[0] );

		# convert data formats from the list
		my $scientific_notationQp = $data_list[4];
		my $decimal_notationQp    = sprintf( "%.10g", $scientific_notationQp );
		$data_list[4] = $decimal_notationQp;

		my $scientific_notationQs = $data_list[5];
		my $decimal_notationQs    = sprintf( "%.10g", $scientific_notationQs );
		$data_list[5] = $decimal_notationQs;
		my $temp_pdl = pdl @data_list;

		if ( $i == 0 ) {

			$data_list_pdl = $temp_pdl;

		}
		elsif ( $i > 0 ) {

			$data_list_pdl = $data_list_pdl->glue( 1, $temp_pdl );

		}
		else {
			print("invert, unexpected value\n");
		}


		$num_pdl = $num_pdl + 1;
	}
	
	my $result = $data_list_pdl;
	return($result);
}

1;
