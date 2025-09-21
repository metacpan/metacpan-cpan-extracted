package App::SeismicUnixGui::sunix::header::segyclean;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SEGYCLEAN - zero out unassigned portion of header		
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SEGYCLEAN - zero out unassigned portion of header		

 segyclean <stdin >stdout 					

 Since "foreign" SEG-Y tapes may use the unassigned portion	
 of the trace headers and since SU now uses it too, this	
 program zeros out the fields meaningful to SU.		

  Example:							
  	segyread trmax=200 | segyclean | suximage		

 Credits:
	CWP: Jack Cohen


=head2 CHANGES and their DATES

SUG Version 0.0.02 allows a list of files to be cleaned

09.02.2025 - added list and su_base_file_name parameters
              to allow processing of a list of files
              (Juan Lorenzo)

=cut

=head2 NOTES

Version 0.0.02

Normally, segyclean acts on only one file at a time
 
 In V0.0.2 wraps an extension to process an arbitrary
 list of trace numbers. The automatic iteration includes
 two additional parameters: list and su_base_file_name
 
 The parameter "list" is the name of a text file.
 The file is automatically bound to the SEIMICS_DATA_TXT 
 directory path.
 
 "list" is the name of a file containing a numeric list
 of trace numbers of type "key" that are to be deleted:
 
 An example list
 file contains values, one per line.
    1 
    3 
    5

  "list" = a file name (in directory path: DATA_SEISMICS_TXT)
  "list" carries a ".txt" suffix automatically within the directory path,
  but the user does not enter it in the GUI.

  Neither does the user enter the ".su" suffix in the GUI.
  su_base_file_name =   e.g., 1001, which by defaults lies
  in directory path: DATA_SEISMIC_SU.

  A bare file name: '1001' will automatically be given an  ".su" suffix,
  that is, file name on the disk will be '1001.su'

  Within code, the imported "list" includes path and name;
  hence its name: _inbound_list. User enters a list name in 
  GUI using the mouse <MB3>.

=cut

use Moose;
our $VERSION = '0.0.2';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($_clean $go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';

=head2 instantiation of packages

=cut

my $get                 = L_SU_global_constants->new();
my $Project				= Project_config->new();
my $manage_files_by2    = manage_files_by2->new();
my $DATA_SEISMIC_SEGY	= $Project->DATA_SEISMIC_SEGY();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $segyclean = {

    _inbound_list => '',
    _trmax        => '',
    _Step         => '',
    _note         => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub  Step {
 	
	my ($self) = @_;
	
	# simple check
	if ( length $segyclean->{_inbound_list} ) {
		my $file_num;
		my @Step;
		my $step;
		
		my ($inbound_aref)  = _get_inbound4base_file_names();
		my ($outbound_aref) = _get_outbound4base_file_names();
		my @inbound         = @$inbound_aref;
		my @outbound        = @$outbound_aref;		
		my $num_of_files    = scalar @outbound;

		# print("Step,inbound: @inbound\n");
		# print("Step,inbound: @outbound\n");

		my $last_idx        = $num_of_files - 1;

		# All cases when num_files >=1
		# for first file
		$step     = " segyclean $segyclean->{_Step} < $inbound[0] > $outbound[0] ";

		if ( $last_idx >= 2 ) {

			# CASE: >= 3 operations
			for ( my $i = 1 ; $i < $last_idx ; $i++ ) {
				
				$step =
				  $step . "&  segyclean $segyclean->{_Step} < $inbound[$i] > $outbound[$i] ";

			}

			# for last file
			$segyclean->{_Step} =
			  $step . "&  segyclean $segyclean->{_Step} < $inbound[$last_idx] > $outbound[$last_idx]";

		}
		elsif ( $last_idx == 1 ) {

			# for last file
			$segyclean->{_Step} =
			  $step . "&  segyclean $segyclean->{_Step} < $inbound[$last_idx] > $outbound[$last_idx] ";

		}
		elsif ( $last_idx == 0 ) {

			$segyclean->{_Step} = "$step";

		}
		else {
			print("segyclean,Step,unexpected case\n");
			return();
		}

		return ($segyclean->{_Step});
		
	}
	elsif ( not length $segyclean->{_inbound_list} ) {
			
	$segyclean->{_Step}     = 'segyclean'.$segyclean->{_Step};
	return ( $segyclean->{_Step} );
	}
	else {
		print("segyclean, Step, incorrect parameters\n");
	}
 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $segyclean->{_note} = 'segyclean' . $segyclean->{_note};
    return ( $segyclean->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$segyclean->{_inbound_list}	= '',
    $segyclean->{_trmax}        = '';
    $segyclean->{_Step}         = '';
    $segyclean->{_note}         = '';
}

=head2 sub _get_inbound4base_file_names

=cut

sub _get_inbound4base_file_names {
	my ($self) = @_;

    my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( defined $array_ref && @$array_ref ) {

		my @base_file_name = @$array_ref;
		my @inbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$inbound[$i] = $DATA_SEISMIC_SU . '/' . $base_file_name[$i].$suffix_su;
		}
		return ( \@inbound );

	}
	else {
		print("segyclean,_get_inbound4base_file_names, missing file names\n");
		return ();
	}

}

=head2 sub _get_outbound4base_file_names

=cut

sub _get_outbound4base_file_names {
	my ($self) = @_;

	my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( length $array_ref ) {

		my @base_file_name = @$array_ref;
		my @outbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$outbound[$i] = $DATA_SEISMIC_SU . '/' . $base_file_name[$i].$_clean.$suffix_su;

		}
		return ( \@outbound );

	}
	else {
		print("segyclean,_get_outbound4basefile_names, missing file names\n");
		return ();
	}

}




=head2 sub list

 list array

=cut

sub list {
	my ( $self, $list ) = @_;

	if ( length $list ) {

		# clear memory
		$manage_files_by2->clear(); 
		
		$segyclean->{_inbound_list} = $list;
		
		$manage_files_by2->set_inbound_list($list);
		

	}
	else {
		print("segyclean, list, missing list,\n");
	}
	return ();
}

=head2 sub trmax 

maximum number of traces that are expected in the file

=cut

sub trmax {

    my ( $self, $trmax ) = @_;
    if ( $trmax ne $empty_string ) {

        $segyclean->{_trmax} = $trmax;
        $segyclean->{_note} =
          $segyclean->{_note} . ' trmax=' . $segyclean->{_trmax};
        $segyclean->{_Step} =
          $segyclean->{_Step} . ' trmax=' . $segyclean->{_trmax};

    }
    else {
        print("segyclean, trmax, missing trmax,\n");
    }
}

=head2 sub get_max_index
   max index = number of input variables - 1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 1;

    return ($max_index);
}

1;
