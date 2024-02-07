package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sunmo;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: sunmo 
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   Dec 1 2013
 DESCRIPTION: 
 Version: 0.0.1
          0.0.2 July 15, 2015 (JML)
 		  0.0.3 Jan 14, 2020 (DLL)
 		  0.0.4 Feb 06, 2020 (DLL)
=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES

 SUNMO - NMO for an arbitrary velocity function of time and CDP	     

  sunmo <stdin >stdout [optional parameters]				     

 Optional Parameters:							     
 tnmo=0,...		NMO times corresponding to velocities in vnmo	     
 vnmo=1500,...		NMO velocities corresponding to times in tnmo	     
 cdp=			CDPs for which vnmo & tnmo arApp::SeismicUnixGui::sunix::NMO_Vel_Stk::e specified (see Notes) 
 smute=1.5		samples with NMO stretch exceeding smute are zeroed  
 lmute=25		length (in samples) of linear ramp for stretch mute  
 sscale=1		=1 to divide output samples by NMO stretch factor    
 invert=0		=1 to perform (approximate) inverse NMO		     
 upward=0		=1 to scan upward to find first sample to kill	     
 voutfile=		if set, interplolated velocity function v[cdp][t] is 
			output to named file.			     	     
 Notes:								     
 For constant-velocity NMO, specify only one vnmo=constant and omit tnmo.   

 NMO interpolation error is less than 1 0.000000or frequencies less than 600f   
 the Nyquist frequency.						     

 Exact inverse NMO is impossible, particularly for early times at large     
 offsets and for frequencies near Nyquist witApp::SeismicUnixGui::sunix::NMO_Vel_Stk::h large interpolation errors.  

 The "offset" header field must be set.				     
 Use suazimuth to set offset header field when sx,sy,gx,gy are all	     
 nonzero. 							   	     

 For NMO with a velocity function of time only, specify the arrays	     
	   vnmo=v1,v2,... tnmo=t1,t2,...				     
 where v1 is the velocity at time t1, v2 is the velocity at time t2, ...    
 The times specified in the tnmo array must be monotonically increasing.    
 Linear interpolation and constant extrapolation of the specified velocities
 is used to compute the velocities at times not specified.		     
 The same holds for the anisotropy coefficients as a function of time only. 

 For NMO with a velocity function of time and CDP, specify the array	     
	   cdp=cdp1,cdp2,...						     
 and, for each CDP specified, specify the vnmo and tnmo arrays as described 
 above. The first (vnmo,tnmo) pair corresponds to the first cdp, and so on. 
 Linear interpolation and constant extrapolation of 1/velocity^2 is used    
 to compute velocities at CDPs not specified.				     

 The format of the output interpolated velocity file is unformatted C floats
 with vout[cdp][t], with time as the fast dimension and may be used as an   
 input velocity file for further processing.				     

 Note that this version of sunmo does not attempt to deal with	anisotropy.  
 The version of sunmo with experimental anisotropy support is "sunmo_a


 Credits:
	SEP: Shuki Ronen, Chuck Sword
	CWP: Shuki Ronen, Jack, Dave Hale, Bjoern Rommel
      Modified: 08/08/98 - Carlos E. Theodoro - option for lateral offset
      Modified: 07/11/02 - Sang-yong Suh -
	  added "upward" option to handle decreasing velocity function.
      CWP: Sept 2010: John Stockwell
	  1. replaced Carlos Theodoro's fix 
	  2. added  the instruction in the selfdoc to use suazimuth to set 
	      offset so that it accounts for lateral offset. 
        3. removed  Bjoren Rommel's anisotropy stuff. sunmo_a is the 
           version with the anisotropy parameters left in.
        4. note that scalel does not scale the offset field in
           the segy standard.
 Technical Reference:
	The Common Depth Point Stack
	William A. Schneider
	Proc. IEEE, v. 72, n. 10, p. 1238-1254
	1984

 Trace header fields accessed: ns, dt, delrt, offset, cdp, scalel


=head4 CHANGES and their DATES

 Juan Lorenzo July 15 2015
 introduced "par" subroutine
 
 V0.0.3 Jan 14 2020 automatic use of scalel

=cut

use Moose;
our $VERSION = '0.0.3';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::sunix::header::header_values';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

my $get          = L_SU_global_constants->new();
my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sunmo = {
	_base_file_name       => '',
	_cdp                  => '',
	_invert               => '',
	_lmute                => '',
	_multi_gather_parfile => '',
	_par                  => '',
	_smute                => '',
	_sscale               => '',
	_scaled_par           => '',
	_tnmo                 => '',
	_upward               => '',
	_vnmo                 => '',
	_voutfile             => '',
	_Step                 => '',
	_note                 => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sunmo->{_Step} = 'sunmo' . $sunmo->{_Step};
	return ( $sunmo->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sunmo->{_note} = 'sunmo' . $sunmo->{_note};
	return ( $sunmo->{_note} );

}

=head2 sub clear

=cut

sub clear {
	$sunmo->{_base_file_name}       = '';
	$sunmo->{_cdp}                  = '';
	$sunmo->{_invert}               = '';
	$sunmo->{_lmute}                = '';
	$sunmo->{_smute}                = '';
	$sunmo->{_sscale}               = '';
	$sunmo->{_multi_gather_parfile} = '';
	$sunmo->{_scaled_par}           = '';
	$sunmo->{_tnmo}                 = '';
	$sunmo->{_upward}               = '';
	$sunmo->{_vnmo}                 = '';
	$sunmo->{_voutfile}             = '';
	$sunmo->{_Step}                 = '';
	$sunmo->{_note}                 = '';
}

=head2 sub _get_data_scale

get scalco or scalel from file header

=cut

sub _get_data_scale {
	my ($self) = @_;

=head2 instantiate class

=cut

 #	print("sunmo, _get_data_scale, _base_file_name=$sunmo->{_base_file_name}\n");

	my $sunmo = header_values->new();

	if ( defined $sunmo->{_base_file_name}
		&& $sunmo->{_base_file_name} ne $empty_string )
	{
		$sunmo->set_base_file_name( $sunmo->{_base_file_name} );
		$sunmo->set_header_name('scalel');
		my $data_scale = $sunmo->get_number();

		my $result = $data_scale;

		# print("sunmo, _get_data_scale, data_scale = $data_scale\n");
		return ($result);

	}
	else {

		my $data_scale = 1;
		my $result     = $data_scale;

		# print("sunmo, _get_data_scale, data_scale = 1:1\n");
		return ($result);

	}
}

=head2 sub cdp 


=cut

sub cdp {

	my ( $self, $cdp ) = @_;
	if ($cdp) {

		$sunmo->{_cdp}  = $cdp;
		$sunmo->{_note} = $sunmo->{_note} . ' cdp=' . $sunmo->{_cdp};
		$sunmo->{_Step} = $sunmo->{_Step} . ' cdp=' . $sunmo->{_cdp};

	}
	else {
		print("sunmo, cdp, missing cdp,\n");
	}
}

=head2 sub invert 


=cut

sub invert {

	my ( $self, $invert ) = @_;
	if ( $invert ne $empty_string ) {

		$sunmo->{_invert} = $invert;
		$sunmo->{_note}   = $sunmo->{_note} . ' invert=' . $sunmo->{_invert};
		$sunmo->{_Step}   = $sunmo->{_Step} . ' invert=' . $sunmo->{_invert};

	}
	else {
		print("sunmo, invert, missing invert,\n");
	}
}

=head2 sub lmute 


=cut

sub lmute {

	my ( $self, $lmute ) = @_;
	if ($lmute) {

		$sunmo->{_lmute} = $lmute;
		$sunmo->{_note}  = $sunmo->{_note} . ' lmute=' . $sunmo->{_lmute};
		$sunmo->{_Step}  = $sunmo->{_Step} . ' lmute=' . $sunmo->{_lmute};

	}
	else {
		print("sunmo, lmute, missing lmute,\n");
	}
}

=head2 sub par 
V0.0.3 1-14-2020 DLL
automatic use of data_scale

read par file (assume in m/s or ft/s)
scale a new output par file * data-scale
assign new output par file

A typical parfile does only handles one gather
at a time

=cut

sub multi_gather_parfile {

	my ( $self, $par ) = @_;
	if ( $par ne $empty_string ) {

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $Project = Project_config->new();
		my $control = control->new();

=head2 declare local variables

=cut

		my @parfile_in;
		my @parfile_out;
		my ( $inbound, $outbound );

		my $PL_SEISMIC = $Project->PL_SEISMIC;

		# par file names
		$parfile_in[1] = $par;

=head2 private definitions

=cut

		$parfile_out[1]       = '.temp_scaled_multi_gather_parfile_iVA';
		$inbound              = $PL_SEISMIC . '/' . $parfile_in[1];
		$sunmo->{_scaled_par} = $PL_SEISMIC . '/' . $parfile_out[1];
		$outbound             = $sunmo->{_scaled_par};

=head2 read i/p file
=cut

		$control->set_back_slashBgone($inbound);
		$inbound = $control->get_back_slashBgone();

		my $ref_file_name = \$inbound;

		my ( $items_aref2, $numberOfItems_aref ) =
		  $files->read_par($ref_file_name);
		my $row0_aref     = @$items_aref2[0];
		my @array_cdp_row = @$row0_aref;

=head2 scale par file values

=cut

		my @row_out;
		my $row_out;
		my $row;

		my @cdp_array             = @array_cdp_row;
		my $number_of_cdp_per_row = scalar @cdp_array;

		$row_out[1] = '.temp_row0';

		$row = $PL_SEISMIC . '/' . $row_out[1];

		open( my $fh, '>', $row );

		print $fh ("cdp=$cdp_array[1]");

		for ( my $i = 2 ; $i < $number_of_cdp_per_row ; $i++ ) {

			print $fh (",$cdp_array[$i]");

		}

		print $fh ("\n");

		close($fh);

		my $row1_sample = @$items_aref2[1];

		my @array_row1_sample = @$row1_sample;

		my $length_row1_sample = scalar @array_row1_sample;

		my $rowoutbound;

		my $array_columns = scalar @$items_aref2;

		# print("sunmo,par, number of rows $array_columns\n");

		for ( my $j = 1 ; $j < $array_columns ; $j += 2 ) {

			$parfile_out[1] = '.temp_row' . $j;

			$row_out     = $PL_SEISMIC . '/' . $parfile_out[1];
			$rowoutbound = $row_out;

			my $row_tnmo_aref = @$items_aref2[$j];

			my $row_vnmo_aref = @$items_aref2[ $j + 1 ];

			my @array_tnmo_row = @$row_tnmo_aref;

			# print("sunmo,par, tnmo_row @array_tnmo_row\n");

			my @array_vnmo_row = @$row_vnmo_aref;

			# print("sunmo,par, vnmo_row @array_vnmo_row\n");

			my $data_scale = _get_data_scale();

			# $data_scale = 100;

			for ( my $i = 1 ; $i < $length_row1_sample ; $i++ ) {

				$array_vnmo_row[$i] = $array_vnmo_row[$i] * $data_scale;

			}

			# print("sunmo,par,par, data_scale=$data_scale\n");
			# print("$outbound, @array_tnmo_row, @array_vnmo_row \n");

=head2 write new par file


=cut

			my $first_name  = 'tnmo';
			my $second_name = 'vnmo';
			$files->write_multipar(
				\$rowoutbound,    \@array_cdp_row, \@array_tnmo_row,
				\@array_vnmo_row, $first_name,     $second_name
			);

		}

=head2 cat scaled par files

=cut

		my $DATA_SEISMIC_SU = $Project->DATA_SEISMIC_SU;

		my $log = message->new();
		my $run = flow->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my $list = '';

=head2 Set up a list of files for action

	my $file_name_list_in
	my $file_name_list_out
	my @file_name_list 
	
=cut 

		my $first_file_num = 1;
		my $maxfile_num    = $array_columns;

		# print("cat_max_file_num $maxfile_num \n");

		my $file_name_out = '.temp_scaled_multi_gather_parfile_iVA';
		my $outboundcat   = $PL_SEISMIC . '/' . $file_name_out;

		for ( my $i = $first_file_num ; $i < $maxfile_num ; $i = $i += 2 ) {

			$list = $list . $PL_SEISMIC . '/' . '.temp_row' . $i . ' ';

		}

=head2 Set up  FLOW 


=cut

		my $cat = "cat $PL_SEISMIC/.temp_row0 $list > $outboundcat";

=head2 RUN FLOW 


=cut

		system($cat);

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		print(" $cat\n");

=head2 send to sunmo

=cut

		# $sunmo->{_scaled_par} = $par;

		$sunmo->{_note} = $sunmo->{_note} . ' par=' . $sunmo->{_scaled_par};
		$sunmo->{_Step} = $sunmo->{_Step} . ' par=' . $sunmo->{_scaled_par};

	}
	else {
		print("sunmo, par, missing par,\n");
	}
}

=head2 sub par 
V0.0.3 1-14-2020 DLL
automatic use of data_scale

read par file (assume in m/s or ft/s)
scale a new output par file * data-scale
assign new output par file

A typical parfile does only handles one gather
at a time

=cut

sub par {

	my ( $self, $par ) = @_;
	if ( $par ne $empty_string ) {

		print("sunmo,  par file name in =$par\n");

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $Project = Project_config->new();
		my $control = control->new;

=head2 declare local variables

=cut

		my @parfile_in;
		my @parfile_out;
		my ( $inbound, $outbound );

		my $PL_SEISMIC = $Project->PL_SEISMIC;

		# par file names
		$parfile_in[1] = $par;

=head2 private definitions

=cut

		$parfile_out[1]       = '.temp_scaled_par_iVA';
		$inbound              = $PL_SEISMIC . '/' . $parfile_in[1];
		$sunmo->{_scaled_par} = $PL_SEISMIC . '/' . $parfile_out[1];
		$outbound             = $sunmo->{_scaled_par};

=head2 read i/p file
=cut

		$control->set_back_slashBgone($inbound);
		$inbound = $control->get_back_slashBgone();

		my $ref_file_name = \$inbound;

		print("sunmo $inbound\n");

		my ( $items_aref2, $numberOfItems_aref ) =
		  $files->read_par($ref_file_name);

		my $no_rows = scalar @$items_aref2;

		print("sunmo,par, no_rows=$no_rows\n");

		my $row0_aref = @$items_aref2[0];

		print("sunmo,par, ARRAY ref inside ROW 0 $row0_aref\n");
		my $row1_aref = @$items_aref2[1];

		print("sunmo,par, ARRAY ref inside ROW 1 $row1_aref\n");

		my @array_tnmo_row = @$row0_aref;

		print("sunmo,par, complete array values in row 0 @array_tnmo_row\n");
		my @array_vnmo_row = @$row1_aref;

		print("sunmo,par, complete array values in row 1 @array_vnmo_row\n");

		my $length_tnmo_row = scalar @array_tnmo_row;
		my $length_vnmo_row = scalar @array_vnmo_row;

=head2 scale par file values

=cut

		my $data_scale = _get_data_scale();

		# $data_scale = 100;

		for ( my $i = 1 ; $i < $length_vnmo_row ; $i++ ) {

			$array_vnmo_row[$i] = $array_vnmo_row[$i] * $data_scale;

		}

		print("sunmo,par,par, data_scale=$data_scale\n");

=head2 write new par file


=cut

		my $first_name  = 'tnmo';
		my $second_name = 'vnmo';
		$files->write_par( \$outbound, \@array_tnmo_row, \@array_vnmo_row,
			$first_name, $second_name );
		print("sunmo,par,first_name:$first_name,second_name:$second_name\n");

=head2 send to sunmo

=cut

		$sunmo->{_note} = $sunmo->{_note} . ' par=' . $sunmo->{_scaled_par};
		$sunmo->{_Step} = $sunmo->{_Step} . ' par=' . $sunmo->{_scaled_par};

	}
	else {
		print("sunmo, par, missing par,\n");
	}
}

=head2 sub smute 


=cut

sub smute {

	my ( $self, $smute ) = @_;
	if ($smute) {

		$sunmo->{_smute} = $smute;
		$sunmo->{_note}  = $sunmo->{_note} . ' smute=' . $sunmo->{_smute};
		$sunmo->{_Step}  = $sunmo->{_Step} . ' smute=' . $sunmo->{_smute};

	}
	else {
		print("sunmo, smute, missing smute,\n");
	}
}

=head2 sub sscale 


=cut

sub sscale {
	my ( $self, $sscale ) = @_;
	if ($sscale) {

		$sunmo->{_sscale} = $sscale;
		$sunmo->{_note}   = $sunmo->{_note} . ' sscale=' . $sunmo->{_sscale};
		$sunmo->{_Step}   = $sunmo->{_Step} . ' sscale=' . $sunmo->{_sscale};

	}
	else {
		print("sunmo, sscale, missing sscale,\n");
	}
}

=head2 sub set_base_file_name

=cut

sub set_base_file_name {

	my ( $self, $base_file_name ) = @_;

	if ( $base_file_name ne $empty_string ) {

		$sunmo->{_base_file_name} = $base_file_name;
		print("header_values,set_base_file_name,$sunmo->{_base_file_name}\n");

	}
	else {
		print("header_values,set_base_file_name, missing base file name\n");
	}

	return ();

}

=head2 sub tnmo 


=cut

sub tnmo {

	my ( $self, $tnmo ) = @_;
	if ( $tnmo ne $empty_string ) {

		$sunmo->{_tnmo} = $tnmo;
		$sunmo->{_note} = $sunmo->{_note} . ' tnmo=' . $sunmo->{_tnmo};
		$sunmo->{_Step} = $sunmo->{_Step} . ' tnmo=' . $sunmo->{_tnmo};

	}
	else {
		print("sunmo, tnmo, missing tnmo,\n");
	}
}

=head2 sub upward 


=cut

sub upward {

	my ( $self, $upward ) = @_;
	if ( $upward ne $empty_string ) {

		$sunmo->{_upward} = $upward;
		$sunmo->{_note}   = $sunmo->{_note} . ' upward=' . $sunmo->{_upward};
		$sunmo->{_Step}   = $sunmo->{_Step} . ' upward=' . $sunmo->{_upward};

	}
	else {
		print("sunmo, upward, missing upward,\n");
	}
}

=head2 sub vnmo 


=cut

sub vnmo {

	my ( $self, $vnmo ) = @_;
	if ($vnmo) {

		$sunmo->{_vnmo} = $vnmo;
		$sunmo->{_note} = $sunmo->{_note} . ' vnmo=' . $sunmo->{_vnmo};
		$sunmo->{_Step} = $sunmo->{_Step} . ' vnmo=' . $sunmo->{_vnmo};

	}
	else {
		print("sunmo, vnmo, missing vnmo,\n");
	}
}

=head2 sub vnmo_mps 


=cut

sub vnmo_mps {

	my ( $self, $vnmo ) = @_;
	if ($vnmo) {

		$sunmo->{_vnmo} = $vnmo;
		$sunmo->{_note} = $sunmo->{_note} . ' vnmo=' . $sunmo->{_vnmo};
		$sunmo->{_Step} = $sunmo->{_Step} . ' vnmo=' . $sunmo->{_vnmo};

	}
	else {
		print("sunmo, vnmo, missing vnmo,\n");
	}
}

=head2 sub voutfile 


=cut

sub voutfile {

	my ( $self, $voutfile ) = @_;
	if ($voutfile) {

		$sunmo->{_voutfile} = $voutfile;
		$sunmo->{_note} = $sunmo->{_note} . ' voutfile=' . $sunmo->{_voutfile};
		$sunmo->{_Step} = $sunmo->{_Step} . ' voutfile=' . $sunmo->{_voutfile};

	}
	else {
		print("sunmo, voutfile, missing voutfile,\n");
	}
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 10;

	return ($max_index);
}

1;
