package App::SeismicUnixGui::sunix::shapeNcut::suflip;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUFLIP - flip a data set in various ways			



 suflip <data1 >data2 flip=1 verbose=0				



 Required parameters:						

 	none							



 Optional parameters:						

 	flip=1 	rotational sense of flip			

 			+1  = flip 90 deg clockwise		

 			-1  = flip 90 deg counter-clockwise	

 			 0  = transpose data			

 			 2  = flip right-to-left		

 			 3  = flip top-to-bottom		

 	tmpdir=	 if non-empty, use the value as a directory path

		 prefix for storing temporary files; else if	

	         the CWP_TMPDIR environment variable is set use	

	         its value for the path; else use tmpfile()	



 	verbose=0	verbose = 1 echoes flip info		



 NOTE:  tr.dt header field is lost if flip=-1,+1.  It can be	

        reset using sushw.					



 EXAMPLE PROCESSING SEQUENCES:					

   1.	suflip flip=-1 <data1 | sushw key=dt a=4000 >data2	



   2.	suflip flip=2 <data1 | suflip flip=2 >data1_again	



   3.	suflip tmpdir=/scratch <data1 | ...			



 Caveat:  may fail on large files.				



 Credits:

	CWP: Chris Liner, Jack K. Cohen, John Stockwell



 Caveat:

	right-left flip (flip = 2) and top-bottom flip (flip = 3)

	don't require the matrix approach.  We sacrificed efficiency

	for uniform coding.



 Trace header fields accessed: ns, dt

 Trace header fields modified: ns, dt, tracl



=head2 CHANGES and their DATES - JML

V0.0.2 April 2024

 incorporates a list of files to flip individually

=cut

use Moose;
our $VERSION = '0.0.2';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($flip $in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
#use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
#use aliased 'App::SeismicUnixGui::misc::readfiles';

=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
#my $control          	= control->new();
my $manage_files_by2    = manage_files_by2->new();
#my $readfiles        	= readfiles->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};


=head2 clear memeory


=cut

#$manage_files_by2->clear();

=head2 Encapsulated

hash of private variables

=cut

my $suflip			= {
	_flip					=> '',
	_inbound_list           => '',
	_tmpdir					=> '',
	_verbose				=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {
 	
	my ($self) = @_;
	
	# simple check
	if ( length $suflip->{_inbound_list} ) {
		my $file_num;
		my @Step;
		my $step;
		
		my ($inbound_aref)  = _get_inbound4base_file_names();
		my ($outbound_aref) = _get_outbound4base_file_names();
		my @inbound         = @$inbound_aref;
		my @outbound        = @$outbound_aref;		
		my $num_of_files    = scalar @outbound;

		print("Step,inbound: @inbound\n");
		print("Step,inbound: @outbound\n");

		my $last_idx        = $num_of_files - 1;

		# All cases when num_traces >=0
		# for first file
		$step     = " suflip $suflip->{_Step} < $inbound[0] > $outbound[0] ";

		if ( $last_idx >= 2 ) {

			# CASE: >= 3 operations
			for ( my $i = 1 ; $i < $last_idx ; $i++ ) {
				
				$step =
				  $step . "&  suflip $suflip->{_Step} < $inbound[$i] > $outbound[$i] ";

			}

			# for last file
			$suflip->{_Step} =
			  $step . "&  suflip $suflip->{_Step} < $inbound[$last_idx] > $outbound[$last_idx]";

		}
		elsif ( $last_idx == 1 ) {

			# for last file
			$suflip->{_Step} =
			  $step . "&  suflip $suflip->{_Step} < $inbound[$last_idx] > $outbound[$last_idx] ";

		}
		elsif ( $last_idx == 0 ) {

			$suflip->{_Step} = $step;

		}
		else {
			print("suflip,Step,unexpected case\n");
			return();
		}

		return ($suflip->{_Step});
		
	}
	elsif ( not length $suflip->{_inbound_list} ) {
			
	$suflip->{_Step}     = 'suflip'.$suflip->{_Step};
	return ( $suflip->{_Step} );
	}
	else {
		print("suflip, Step, incorrect parameters\n");
	}
 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suflip->{_note}     = 'suflip'.$suflip->{_note};
	return ( $suflip->{_note} );

 }


=head2 sub clear

=cut

 sub clear {

		$suflip->{_flip}			= '';
		$suflip->{_tmpdir}			= '';
		$suflip->{_verbose}			= '';
		$suflip->{_Step}			= '';
		$suflip->{_note}			= '';
 }

#=head2 sub _get_base_file_names_aref
#
#read a list of file names
#remove the su suffix
#return array reference of the
#list of names without su suffixes
#
#=cut
#
#sub _get_base_file_name_aref {
#	my ($self) = @_;
#
#	if ( length $suflip->{_inbound_list} ) {
#
#		my $inbound_list = $suflip->{_inbound_list};
#
#		my ( $file_names_aref, $num_files ) = $readfiles->cols_1p($inbound_list);
#		$control->set_aref($file_names_aref);
#		$control->remove_su_suffix4aref();
#		my $base_file_name_aref = $control->get_base_file_name_aref();
#
#		print("suflip, _get_base_file_names, values=@$base_file_name_aref\n");
#		
#		my $result_a = $base_file_name_aref;
#		my $result_b = $num_files;
#		return ( $result_a, $result_b);
#
#	}
#	else {
#		print("_get_base_file_name_aref, missing inbound lsit\n");
#		return ();
#	}
#}

#=head2 sub _get_file_names
#
#=cut
#
#sub _get_file_names {
#	my ($self) = @_;
#
#	if ( length $suflip->{_inbound_list} ) {
#
##		_set_inbound_list();
#
#		my $inbound_list = $suflip->{_inbound_list};
#
#		my ( $file_names_ref, $num_files ) = $readfiles->cols_1p($inbound_list);
#		my $result_a = $file_names_ref;
#		my $result_b = $num_files;
#
#		#		print("_get_file_names, values=@$file_names_ref\n");
#		return ( $result_a, $result_b );
#
#	}
#	else {
#		print("_get_file_names, missing inbound\n");
#		return ();
#	}
#
#}

=head2 sub _get_inbound4base_file_names

=cut

sub _get_inbound4base_file_names {
	my ($self) = @_;

#	my ( $array_ref, $num_files ) = _get_base_file_name_aref();
    my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( length $array_ref ) {

		my @base_file_name = @$array_ref;
		my @inbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$inbound[$i] = $DATA_SEISMIC_SU . '/' . $base_file_name[$i].$suffix_su;

		}
		return ( \@inbound );

	}
	else {
		print("suflip,_get_inbound4base_file_names, missing file names\n");
		return ();
	}

}

=head2 sub _get_outbound4base_file_names

=cut

sub _get_outbound4base_file_names {
	my ($self) = @_;

#	my ( $array_ref, $num_files ) = _get_base_file_name_aref();
	my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( length $array_ref ) {

		my @base_file_name = @$array_ref;
		my @outbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$outbound[$i] = $DATA_SEISMIC_SU . '/' . $base_file_name[$i]. '_'. $flip.$suffix_su;

		}
		return ( \@outbound );

	}
	else {
		print("suflip,_get_outbound4basefile_names, missing file names\n");
		return ();
	}

}

#=head2 sub _set_inbound_list
#
#=cut
#
#sub _set_inbound_list {
#	my ($self) = @_;
#
#	if ( length $suflip->{_inbound_list} ) {
#
#		my $inbound_list = $suflip->{_inbound_list};
#		$control->set_back_slashBgone($inbound_list);
#		$inbound_list = $control->get_back_slashBgone();
#		$suflip->{_inbound_list} = $inbound_list;
#
#	}
#	else {
#		print("_set_inbound_list, missing list\n");
#		return ();
#	}
#
#}

=head2 sub flip 


=cut

 sub flip {

	my ( $self,$flip )		= @_;
	if ( $flip ne $empty_string ) {

		$suflip->{_flip}		= $flip;
		$suflip->{_note}		= $suflip->{_note}.' flip='.$suflip->{_flip};
		$suflip->{_Step}		= $suflip->{_Step}.' flip='.$suflip->{_flip};

	} else { 
		print("suflip, flip, missing flip,\n");
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
		
		$suflip->{_inbound_list} = $list;
		
		$manage_files_by2->set_inbound_list($list);
		
#		_set_inbound_list(); #tbd

		#		print("suflip,list is $suflip->{_inbound_list}\n\n");

	}
	else {
		print("suflip, list, missing list,\n");
	}
	return ();
}

=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$suflip->{_tmpdir}		= $tmpdir;
		$suflip->{_note}		= $suflip->{_note}.' tmpdir='.$suflip->{_tmpdir};
		$suflip->{_Step}		= $suflip->{_Step}.' tmpdir='.$suflip->{_tmpdir};

	} else { 
		print("suflip, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suflip->{_verbose}		= $verbose;
		$suflip->{_note}		= $suflip->{_note}.' verbose='.$suflip->{_verbose};
		$suflip->{_Step}		= $suflip->{_Step}.' verbose='.$suflip->{_verbose};

	} else { 
		print("suflip, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 3;

    return($max_index);
}
 
 
1; 
