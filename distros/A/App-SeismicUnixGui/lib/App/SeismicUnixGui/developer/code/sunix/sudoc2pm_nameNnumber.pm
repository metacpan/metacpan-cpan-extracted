package App::SeismicUnixGui::developer::code::sunix::sudoc2pm_nameNnumber;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: sudoc2pm_nameNnumber.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 7 2022 

 DESCRIPTION 
 Name of the program
 and its program-group number
 which will be used to incorporate this sunix module 
 into the L_SU GUIB

 BASED ON:
 Version 0.1 
 
 
=cut

=head2 USE
 state program name and its program name group

=head3 NOTES

Array of program group names,
and their directory namesakes:
 		
$developer_sunix_categories[0]  = 'data';
$developer_sunix_categories[1]  = 'datum';
$developer_sunix_categories[2]  = 'plot';
$developer_sunix_categories[3]  = 'filter';
$developer_sunix_categories[4]  = 'header';
$developer_sunix_categories[5]  = 'inversion';
$developer_sunix_categories[6]  = 'migration';
$developer_sunix_categories[7]  = 'model';
$developer_sunix_categories[8]  = 'NMO_Vel_Stk';
$developer_sunix_categories[9]  = 'par';
$developer_sunix_categories[10] = 'picks';
$developer_sunix_categories[11] = 'shapeNcut';
$developer_sunix_categories[12] = 'shell';
$developer_sunix_categories[13] = 'statsMath';
$developer_sunix_categories[14] = 'transform';
$developer_sunix_categories[15] = 'well';
$developer_sunix_categories[16] = 'unix';
$developer_sunix_categories[17] = '';

=head4 Examples

  sudoc2pm_pt1.pl uses this package
  
  
  sudoc 

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.1.0';

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
my $file     = manage_files_by2->new();

#my $sunix_category_number = 8;
#my $selected_program_name = 'sustkvel';

my $inbound = './' . 'nameNnumber'.'.txt';

		my $spacer            		    = " ";
		my $aref              		    = $file->read_2cols_aref( $inbound, $spacer );
		my @array             		    = @$aref;
		my $selected_program_name_aref  = $array[0];
		my $sunix_category_number_aref  = $array[1];
		my @selected_program_name       = @$selected_program_name_aref;
		my @sunix_category_number	    = @$sunix_category_number_aref;
		
		
#print("sudoc2pm_nameNnumber,selected_program_name=@{$array[0]}\n");			
#print("sudoc2pm_nameNnumber,selected_program_name=@selected_program_name\n");
#print("sudoc2pm_nameNnumber,sunix_category_number=@sunix_category_number\n");		

sub get_selected_program_name {

	my ($self) = @_;
	my $result;

	if ( length $selected_program_name[0] ) {
		
       $result = $selected_program_name[0];
       
	}
	else {
		print("sudoc2pm missing  program name\n");
	}
	return ($result);
}

sub get_category_number {

	my ($self) = @_;
	my $result;

	if ( length $sunix_category_number[0] ) {
		
		$result = $sunix_category_number[0];
	}
	else {
		print("sudoc2pm missing sunix category number\n");
	}

	return ($result);

}

1;
