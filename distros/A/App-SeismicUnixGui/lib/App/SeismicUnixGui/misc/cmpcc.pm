package App::SeismicUnixGui::misc::cmpcc;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

ccmpcc Hayashi and Suzuki, 2013 

 PERL PROGRAM NAME: ccmpcc.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		Dec. 2021

 DESCRIPTION 
     

 BASED ON:

=cut

=head2 USE

=head3 NOTES

offsets are -1 off their mark so that
suaddhead inputs the correct value into the 
headers... TODO ... don't understand why yet.

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash
 
=cut

=head2 declare libraries

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $append
  $suffix_segy $suffix_sgy $suffix_segd $suffix_txt $suffix_bin $cdp $gx $txt $offset
  $su $sx $suffix_su $suffix_txt $tracl);

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::array';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::shell::cat_su';
use aliased 'App::SeismicUnixGui::sunix::shell::cat_txt';
use aliased 'App::SeismicUnixGui::sunix::data::data_out';
use aliased 'App::SeismicUnixGui::sunix::data::data_in';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::header::sushw';
use aliased 'App::SeismicUnixGui::sunix::header::sulhead';
use aliased 'App::SeismicUnixGui::sunix::statsMath::suxcor';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

=head2

instantiate modules

=cut

my $Project = Project_config->new();
my $control = control->new();
my $get     = L_SU_global_constants->new();

=head2

define local variables

=cut

my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var   = $get->var();
my $true  = $var->{_true};
my $false = $var->{_false};

=head2 define private hash
to share

=cut

my @array1;
my @array2;

my $cmpcc = {
	_appendix               => '',
	_aref4cc_pt1            => '',
	_aref4cc_pt2            => '',
	_aref4cc_pt3            => '',
	_aref4cc_pt4            => '',
	_aref4cc_pt5            => '',
	_base_file_name_gx      => '',
	_base_file_name_sx      => '',
	_cat_base_file_name_out => '',
	_cmpcc_number_of        => '',
	_cmpcc_spread_m         => '',
	_cmpcc_x_inc_m          => '',

	# _cross_correlation_base_file_name_line_in => '',
	_data_base_file_name_in                   => '',
	_data_base_file_name_out                  => '',
	_delete_base_file_name                    => '',
	_ep_idx                                   => '',
	_ep_number_of                             => '',
	_filter_base_file_name_in                 => ' filter ',
	_filter_base_file_name_out                => ' filter ',
	_first_geo_x_inc_m4calc                   => '',
	_first_geo_x_m4calc                       => 7.5,
	_first_geo_idx                            => 0,
	_first_line                               => 1,
	_for_loading_base_file_name_line_in       => '',
	_is_aref4cc_pt1                           => $false,
	_is_aref4cc_pt1_trcl                      => $false,
	_is_aref4cc_pt2                           => $false,
	_is_aref4cc_pt3                           => $false,
	_is_aref4cc_pt4                           => $false,
	_is_aref4cc_pt5                           => $false,
	_line_geometry_base_file_name             => ' line_geometry ',
	_geo_spread_m4calc                        => 69,
	_geo_x_inc_m4calc                         => 3,
	_geo_x_m_aref                             => '',
	_geo_x_m_aref4cc                          => \@array1,
	_geo_number_of                            => 24,
	_header_word                              => $tracl,
	_last_line                                => 6,
	_last_geo_x_m4calc                        => 76.5,
	_loaded_w_headers_base_file_name_line_out => '',
	_shove_line_geom_base_file_name_out       => '',
	_shove_sp_gather_geom_base_file_name_out  => '',
	_shove_sp_gather_geom_outbound            => '',
	_sp_x_m_aref                              => '',
	_sp_x_m_aref4cc                           => \@array2,
	_suffix_type                              => '',
	_suwind_max_header_value                  => '',
	_suwind_min_header_value                  => '',
	_suwind_skip                              => 1,
	_tracl_order_base_file_name_in            => '',
	_tracl_order_base_file_name_out           => '',
	_offset_x_m_aref4cc                       => '',
	_vector_pt1_aref                          => '',
	_vector_pt2_aref                          => '',
	_vector_pt3_aref                          => '',
	_vector_pt4_aref                          => '',
	_vector_pt5_aref                          => '',
};

=head2 sub clean

delete a pre-existing file
directory of a file

=cut

sub clean {
	my ($self) = @_;

	if (    length $cmpcc->{_delete_base_file_name}
		and length $cmpcc->{_suffix_type} )
	{

		my $Project = Project_config->new();
		my $file    = manage_files_by2->new();

		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;
		my $file_name         = $cmpcc->{_delete_base_file_name};
		my $suffix_type       = $cmpcc->{_suffix_type};
		my $outbound;

		if ( $suffix_type eq $txt ) {

			$outbound = $DATA_SEISMIC_TXT . ' / ' . $file_name . $suffix_txt;

		}
		elsif ( $suffix_type eq $su ) {

			$outbound = $DATA_SEISMIC_SU . ' / ' . $file_name . $suffix_su;

		}
		else {
			print("cmpcc, clean, unexpected\n");
		}

		my $ans = $file->exists($outbound);

		#			print(
		#				"cmpcc, clean, file_name= $file_name does exist\n"
		#			);

		if ($ans) {

			$file->delete($outbound);
			print("cmpcc, clean, Cleaning for pre-existing $file_name \n");

		}
		else {
			#			print("cmpcc, clean, file does not exist NADA\n");
		}

	}
	else {
		print("cmpcc, set_geom4calc, missing values\n");
		print(
"cmpcc, clean, delete_base_file_name=$cmpcc->{_delete_base_file_name}\n"
		);

	}

}

=head2 sub clear
all memory

=cut

sub clear {
	my $self = @_;
	$cmpcc->{_appendix}               = '';
	$cmpcc->{_aref4cc_pt1}            = '';
	$cmpcc->{_aref4cc_pt2}            = '';
	$cmpcc->{_aref4cc_pt3}            = '';
	$cmpcc->{_aref4cc_pt4}            = '';
	$cmpcc->{_aref4cc_pt5}            = '';
	$cmpcc->{_base_file_name_gx}      = '';
	$cmpcc->{_base_file_name_sx}      = '';
	$cmpcc->{_cat_base_file_name_out} = '';
	$cmpcc->{_delete_base_file_name}  = '';
	$cmpcc->{_cmpcc_number_of}        = '';
	$cmpcc->{_cmpcc_spread_m}         = '';
	$cmpcc->{_cmpcc_x_inc_m}          = '';

	#	$cmpcc->{_cross_correlation_base_file_name_line_in} = '';
	$cmpcc->{_ep_idx}                                   = '';
	$cmpcc->{_ep_number_of}                             = '';
	$cmpcc->{_data_base_file_name_in}                   = '';
	$cmpcc->{_data_base_file_name_out}                  = '';
	$cmpcc->{_filter_base_file_name_in}                 = ' filter ';
	$cmpcc->{_filter_base_file_name_out}                = ' filter ';
	$cmpcc->{_first_geo_x_inc_m4calc}                   = '';
	$cmpcc->{_first_geo_x_m4calc}                       = 7.5;
	$cmpcc->{_first_geo_idx}                            = 0;
	$cmpcc->{_first_line}                               = 1;
	$cmpcc->{_for_loading_base_file_name_line_in}       = '';
	$cmpcc->{_geo_spread_m4calc}                        = 69;
	$cmpcc->{_geo_x_inc_m4calc}                         = 3;
	$cmpcc->{_geo_x_m_aref}                             = '';
	$cmpcc->{_geo_x_m_aref4cc}                          = '';
	$cmpcc->{_geo_number_of}                            = 24;
	$cmpcc->{_header_word}                              = $tracl;
	$cmpcc->{_is_aref4cc_pt1}                           = $false;
	$cmpcc->{_is_aref4cc_pt1_trcl}                      = $false;
	$cmpcc->{_is_aref4cc_pt2}                           = $false;
	$cmpcc->{_is_aref4cc_pt3}                           = $false;
	$cmpcc->{_is_aref4cc_pt4}                           = $false;
	$cmpcc->{_is_aref4cc_pt5}                           = $false;
	$cmpcc->{_last_geo_x_m4calc}                        = ' 76.5 ';
	$cmpcc->{_last_line}                                = 6;
	$cmpcc->{_last_geo_x_m4calc}                        = 76.5;
	$cmpcc->{_line_geometry_base_file_name}             = '';
	$cmpcc->{_loaded_w_headers_base_file_name_line_out} = '';
	$cmpcc->{_shove_line_geom_base_file_name_out}       = '';
	$cmpcc->{_shove_sp_gather_geom_base_file_name_out}  = '';
	$cmpcc->{_shove_sp_gather_geom_outbound}            = '';
	$cmpcc->{_sp_x_m_aref}                              = '';
	$cmpcc->{_sp_x_m_aref4cc}                           = '';
	$cmpcc->{_suffix_type}                              = '';
	$cmpcc->{_suwind_max_header_value}                  = '';
	$cmpcc->{_suwind_min_header_value}                  = '';
	$cmpcc->{_suwind_skip}                              = 1;
	$cmpcc->{_offset_x_m_aref4cc}                       = '';
	$cmpcc->{_tracl_order_base_file_name_in}            = '';
	$cmpcc->{_tracl_order_base_file_name_out}           = '';
	$cmpcc->{_vector_pt1_aref}                          = '';
	$cmpcc->{_vector_pt2_aref}                          = '';
	$cmpcc->{_vector_pt3_aref}                          = '';
	$cmpcc->{_vector_pt4_aref}                          = '';
	$cmpcc->{_vector_pt5_aref}                          = '';

}

=head2 sub get_cmp_x_m_aref4cc

For a SINGLE SP gather,
build cmp index and value arrays
for a correlation of a specific
trace against all the rest
The specific trace varies so all
combinations are estimated

print("cmpcc,get_cmp_x_m_aref4cc, cmp_x_m_array2= @{$cmp_x_m_array2[$geo_ref]}\n");
print("cmpcc,get_cmp_x_m_aref4cc,  geo_ref=$geo_ref \n");
print("cmpcc,get_cmp_x_m_aref4cc, every  = $every\n");
print("cmpcc,get_cmp_x_m_aref4cc, cmp_x_m = $cmp_x_m[$geo_ref][$every]\n");

=cut

sub get_cmp_x_m_aref4cc {
	my ($self) = @_;

	my $result;

	if (    length $cmpcc->{_geo_number_of}
		and length $cmpcc->{_first_geo_idx}
		and length $cmpcc->{_geo_x_m_aref} )
	{

		my @cmp_x_m_array2;

		my $first_geo_idx = $cmpcc->{_first_geo_idx};
		my $last_geo_idx  = $cmpcc->{_geo_number_of};
		my $geo_number_of = $cmpcc->{_geo_number_of};
		my @geo_x_m       = @{ $cmpcc->{_geo_x_m_aref} };
		
#		print("geo_number_of=$geo_number_of\n");

		# combination of all geophones
		for (
			my $geo_ref = $first_geo_idx ;
			$geo_ref < $last_geo_idx ;
			$geo_ref++
		  )
		{
			my @cmp_x_m;

			# with every geophone,
			# two at a time
			for ( my $every = 0 ; $every < $geo_number_of ; $every++ ) {

				$cmp_x_m[$every] =
				  ( $geo_x_m[$geo_ref] + $geo_x_m[$every] ) / 2.;

			}    # end inner loop

			$cmp_x_m_array2[$geo_ref] = \@cmp_x_m;
		}    # end outer loop

		$cmpcc->{_cmp_x_m_aref4cc} = \@cmp_x_m_array2;
		$result = $cmpcc->{_cmp_x_m_aref4cc};
		return ($result);

	}
	else {
		print("cmpcc, get_cmp_x_m_aref4cc, missing values\n");
		print("cmpcc,geo_number_of=$cmpcc->{_geo_number_of}\n");
		print("cmpcc,first_geo_idx=$cmpcc->{_first_geo_idx}\n");
		print("cmpcc,cmp_x_m_aref=@{$cmpcc->{_geo_x_m_aref}}\n");
		return ($result);
	}

}

=head2 sub get_cmpcc_spread_m 

geometry values

=cut

sub get_cmpcc_spread_m {

	my ( $self, $cmp_spread_m ) = @_;

	my $result;

	if ( length $cmp_spread_m ) {

		$cmpcc->{_cmpcc_spread_m} = $cmp_spread_m;

	}
	else {
		print("cmpcc, cmp_spread_m=cmp_spread_m\n");
	}

	return ($result);
}

=head2 sub get_cmpcc_x_inc_m 

geometry values

=cut

sub get_cmpcc_x_inc_m {
	my ( $self, $cmp_x_inc_m ) = @_;

	my $result;

	if ( length $cmp_x_inc_m ) {

		$cmpcc->{_cmpcc_x_inc_m} = $cmp_x_inc_m;

	}
	else {
		print("cmpcc, cmp_x_inc_m=cmp_x_inc_m\n");
	}

	return ($result);
}

=head2 sub get_geo_number_of 

geometry values

=cut

sub get_geo_number_of {
	my ($self) = @_;

	my $result;

	if ( length $cmpcc->{_geo_number_of} ) {

		$result = $cmpcc->{_geo_number_of};

	}
	else {
		print("cmpcc, get_geo_number_of, missing value\n");
	}

	return ($result);
}

=head2 sub get_geo_x_m_aref

geometry values

=cut

sub get_geo_x_m_aref {
	my ($self) = @_;

	my $result;

	if ( length $cmpcc->{_geo_x_m_aref} ) {

		$result = $cmpcc->{_geo_x_m_aref};

	}
	else {
		print("cmpcc, get_geo_x_m_aref, missing value\n");
	}

	return ($result);
}

=head2 sub get_geo_x_m_aref4cc

geometry values

=cut

sub get_geo_x_m_aref4cc {
	my ($self) = @_;

	my $result;

	if ( length $cmpcc->{_geo_x_m_aref4cc} ) {

		$result = $cmpcc->{_geo_x_m_aref4cc};

	}
	else {
		print("cmpcc, get_geo_x_m_aref4cc, missing value\n");
	}

	return ($result);
}

=head2 sub get_offset_x_m_aref4cc

For a single SP gather,
build offset for all the following
combinations:
e.g., 24 geophones, combined 2 at a time

print("cmpcc,get_offset_x_m_aref4cc,
geo_ref=$geo_ref; every=$every; offset = $offset_x_m[$every]\n");
print("cmpcc,get_offset_x_m_aref4cc,geo_ref=0; offset = @{$array_ref2[0]}\n");
print("cmpcc,get_offset_x_m_aref4cc,geo_ref=1; offset = @{$array_ref2[1]}\n");	    
print("cmpcc,get_offset_x_m_aref4cc,geo_ref=1; offset = @{@{$cmpcc->{_offset_x_m_aref4cc}}[1]}\n");

=cut

sub get_offset_x_m_aref4cc {

	my ($self) = @_;

	my $result;

	if (    length $cmpcc->{_geo_number_of}
		and length $cmpcc->{_geo_x_m_aref}
		and length $cmpcc->{_sp_x_m_aref}
		and length $cmpcc->{_first_geo_idx}
		and length $cmpcc->{_geo_x_m_aref}
		and length $cmpcc->{_sp_x_m_aref} )
	{

		my @array_ref2;

		my $first_geo_idx = $cmpcc->{_first_geo_idx};
		my $geo_number_of = $cmpcc->{_geo_number_of};

		my @geo_x_m = @{ $cmpcc->{_geo_x_m_aref} };
		my @sp_x_m  = @{ $cmpcc->{_sp_x_m_aref} };
		my $sp_x_m  = $sp_x_m[0];                     # all values are the same

		# over every geophone within a shotpoint gather
		for (
			my $geo_ref = $first_geo_idx ;
			$geo_ref < $geo_number_of ;
			$geo_ref++
		  )
		{

			my @offset_x_m;

		  # Offset between 2 geophones at a time
		  # Use successively different first geophone
		  # To make pairs:
		  # fix the first geophone, then consider every geophone in a shot gather
			for ( my $every = 0 ; $every < $geo_number_of ; $every++ ) {

				$offset_x_m[$every] =
				  abs( $geo_x_m[$every] - $sp_x_m ) -
				  abs( $geo_x_m[$geo_ref] - $sp_x_m ) - 1;    # TODO fudge

			}

			$array_ref2[$geo_ref] = \@offset_x_m;

#		    print("cmpcc,get_offset_x_m_aref4cc,geo_ref=$geo_ref; offset = @{$array_ref2[$geo_ref]}\n");
		}

		$cmpcc->{_offset_x_m_aref4cc} = \@array_ref2;
		$result = $cmpcc->{_offset_x_m_aref4cc};

		return ($result);
	}
	else {
		print("cmpcc,get_offset_x_m_aref4cc, missing variables \n");
		print(
"cmpcc,get_offset_x_m_aref4cc, geo_number_of=$cmpcc->{_geo_number_of} \n"
		);
		print(
"cmpcc,get_offset_x_m_aref4cc, geo_x_m_aref=@{$cmpcc->{_geo_x_m_aref}} \n"
		);
		print(
"cmpcc,get_offset_x_m_aref4cc, sp_x_m_aref=$cmpcc->{_sp_x_m_aref} \n"
		);
		print(
"cmpcc,get_offset_x_m_aref4cc, first_geo_idx=$cmpcc->{_first_geo_idx} \n"
		);

		return ($result);

	}

}

=head2 sub get_sp_x_m_aref

geometry values

=cut

sub get_sp_x_m_aref {
	my ($self) = @_;

	my $result;

	if ( length $cmpcc->{_sp_x_m_aref} ) {

		$result = $cmpcc->{_sp_x_m_aref};

	}
	else {
		print("cmpcc, get_sp_x_m_aref, missing value\n");
	}

	return ($result);
}

=head2 sub get_sp_x_m_aref4cc

geometry values

=cut

sub get_sp_x_m_aref4cc {
	my ($self) = @_;

	my $result;

	if ( length $cmpcc->{_sp_x_m_aref4cc} ) {

		$result = $cmpcc->{_sp_x_m_aref4cc};

	}
	else {
		print("cmpcc, get_sp_x_m_aref4cc, missing value\n");
	}

	return ($result);
}

=head2 sub set_sp_gather_geom

write out a single sp gather's
geometry values for 24x24=576 possible
cross-correlation cases

=cut

sub set_sp_gather_geom_out {

	my ($self) = @_;

	my $result;
	my $count = 0;

	if ( length $cmpcc->{_shove_sp_gather_geom_outbound} ) {

		my $file = manage_files_by2->new();

		if ( length $cmpcc->{_vector_pt5_aref} ) {

			$count++;

		}
		if ( length $cmpcc->{_vector_pt4_aref} ) {

			$count++;

		}
		if ( length $cmpcc->{_vector_pt3_aref} ) {

			$count++;

		}
		if ( length $cmpcc->{_vector_pt2_aref} ) {

			$count++;

		}
		if ( length $cmpcc->{_vector_pt1_aref} ) {

			$count++;

		}

		if ( $count == 0 ) {

			print("cmpcc, count, ERROR=$count\n");

		}
		else {
#			print("cmpcc, NADA, count, $count\n");
		}

		my $file_name = $cmpcc->{_shove_sp_gather_geom_outbound};
		my $format    = "%d\t%f\t%d\t%d\t%f\n";

#		print("cmpc,set_sp_gather_geom_out, vector 1 @{$cmpcc->{_vector_pt1_aref}}\n");
#		print("cmpc,set_sp_gather_geom_out, vector 2 @{$cmpcc->{_vector_pt2_aref}}\n");
#		print("cmpc,set_sp_gather_geom_out, vector 3 @{$cmpcc->{_vector_pt3_aref}}\n");
#		print("cmpc,set_sp_gather_geom_out, vector 4 @{$cmpcc->{_vector_pt4_aref}}\n");
#		print("cmpc,set_sp_gather_geom_out, vector 5 @{$cmpcc->{_vector_pt5_aref}}\n");
#		print("cmpc,set_sp_gather_geom_out, file name $file_name\n");
#		print("cmpc,set_sp_gather_geom_out, format $format\n");		
		
		$file->write_5cols(
			$cmpcc->{_vector_pt1_aref}, $cmpcc->{_vector_pt2_aref},
			$cmpcc->{_vector_pt3_aref}, $cmpcc->{_vector_pt4_aref},
			$cmpcc->{_vector_pt5_aref}, $file_name,
			$format
		);

	}
	else {
		print("cmpcc, set_sp_gather_geom_out, missing value\n");
	}

	return ($result);
  }

=head2 sub set_appendix

set file for catting

=cut

  sub set_appendix {
	my ( $self, $appendix ) = @_;

	if ( length $appendix ) {

		$cmpcc->{_appendix} = $appendix;

		#		print("cmpcc, set_appendix, base_file_name_out = $appendix\n");
	}
	else {
		print("cmpcc, set_appendix, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_base_file_name_gx

=cut

sub set_base_file_name_gx {
	my ( $self, $base_file_name_gx ) = @_;

	if ( length $base_file_name_gx ) {

#	   		print(
#	   "cmpcc, set_base_file_name_gx, base_file_name_gx = $base_file_name_gx\n"
#	   		);

		$cmpcc->{_base_file_name_gx} = $base_file_name_gx;
	}
	else {
		print("cmpcc, set_base_file_name_gx, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_base_file_name_sx

=cut

sub set_base_file_name_sx {
	my ( $self, $base_file_name_sx ) = @_;

	if ( length $base_file_name_sx ) {

#	   		print(
#	   "cmpcc, set_base_file_name_sx, base_file_name_sx = $base_file_name_sx\n"
#	   		);

		$cmpcc->{_base_file_name_sx} = $base_file_name_sx;
	}
	else {
		print("cmpcc, set_base_file_name_sx, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_cat_base_file_name_out

=cut

sub set_cat_base_file_name_out {
	my ( $self, $base_file_name_out ) = @_;

	if ( length $base_file_name_out ) {

#		print(
#"cmpcc, set_cat_base_file_name_out, base_file_name_out = $base_file_name_out\n"
#		);

		$cmpcc->{_cat_base_file_name_out} = $base_file_name_out;
	}
	else {
		print("cmpcc, set_cat_base_file_name_out, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_delete_base_file_name

=cut

sub set_delete_base_file_name {
	my ( $self, $base_file_name ) = @_;

	if ( length $base_file_name ) {

#	print(
#   "cmpcc, set_delete_base_file_name, base_file_name_sx = $base_file_name_sx\n"
#	);

		$cmpcc->{_delete_base_file_name} = $base_file_name;

	}
	else {
		print("cmpcc, set_delete_base_file_name, missing variable\n");
	}

	my $result;
	return ($result);

}

=head2 sub set_cat_su

append individual output files to 
a major product file

=cut

sub set_cat_su {

	my ($self) = @_;

	if (    length $cmpcc->{_cat_base_file_name_out}
		and length $cmpcc->{_appendix} )
	{

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		my $log      = message->new();
		my $run      = flow->new();
		my $cat_su   = cat_su->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@cat_su);
		my (@data_out);

=head2 Set up

	cat_su parameter values

=cut

		$cat_su->clear();
		$cat_su->base_file_name1(
			quotemeta( $DATA_SEISMIC_SU . '/' . $cmpcc->{_appendix} )
			  . $suffix_su );

		#	$cat_su->base_file_name2(
		#		quotemeta( $DATA_SEISMIC_SU . '/' . '00000004' ) . $suffix_su );
		$cat_su[1] = $cat_su->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name(
			quotemeta( $cmpcc->{_cat_base_file_name_out} ) );
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $cat_su[1], $append, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print(",cmpcc, cat_su, missing variables \n");
		print(
",cmpcc, cat_su, cmpcc->{_cat_base_file_name_out}=$cmpcc->{_cat_base_file_name_out} \n"
		);
		print(",cmpcc, cat_su, cmpcc->{_appendix}=$cmpcc->{_appendix} \n");
	}

}    # end set_cat_su

=head2 sub set_cat_txt

append individual output files to 
a major product file

=cut

sub set_cat_txt {

	my ($self) = @_;

	if (    length $cmpcc->{_cat_base_file_name_out}
		and length $cmpcc->{_appendix} )
	{

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		my $log      = message->new();
		my $run      = flow->new();
		my $cat_txt  = cat_txt->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@cat_txt);
		my (@data_out);

=head2 Set up

	cat_txt parameter values

=cut

		$cat_txt->clear();
		$cat_txt->base_file_name1(
			quotemeta( $DATA_SEISMIC_TXT . '/' . $cmpcc->{_appendix} )
			  . $suffix_txt );

		$cat_txt[1] = $cat_txt->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name(
			quotemeta( $cmpcc->{_cat_base_file_name_out} ) );
		$data_out->suffix_type( quotemeta('txt') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $cat_txt[1], $append, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print(",cmpcc, cat_txt, missing variables \n");
		print(
",cmpcc, cat_txt, cmpcc->{_cat_base_file_name_out}=$cmpcc->{_cat_base_file_name_out} \n"
		);
		print(",cmpcc, cat_txt, cmpcc->{_appendix}=$cmpcc->{_appendix} \n");
	}

}    # end set_cat_txt

#=head2 sub set_cross_correlation_base_file_name_line_in
#
#geometry values
#
#=cut
#
#sub set_cross_correlation_base_file_name_line_in {
#	my ($self,$file) = @_;
#
#	my $result;
#
#	if ( length $file ) {
#
#		$cmpcc->{_cross_correlation_base_file_name_line_in} = $file;
#
#	}
#	else {
#		print("cmpcc, set_cross_correlation_base_file_name_line_in, missing value\n");
#	}
#
#	return ($result);
#}

=head2 sub set_loaded_w_headers_base_file_name_line_out

=cut

sub set_loaded_w_headers_base_file_name_line_out {
	my ( $self, $base_file_name_out ) = @_;

	if ( length $base_file_name_out ) {

#		print(
#"cmpcc, set_loaded_w_headers_base_file_name_line_out, base_file_name_out = $base_file_name_out\n"
#		);

		$cmpcc->{_loaded_w_headers_base_file_name_line_out} =
		  $base_file_name_out;
	}
	else {
		print(
"cmpcc, set_loaded_w_headers_base_file_name_line_out, missing variable\n"
		);

	}

	my $result;

	return ($result);

}

=head2 sub set_data

=cut

sub set_data {
	my ($self) = @_;

	my $result;

	if (    length $cmpcc->{_data_base_file_name_in}
		and length $cmpcc->{_data_base_file_name_out}
		and length $cmpcc->{_header_word}
		and length $cmpcc->{_suwind_skip}
		and length $cmpcc->{_suwind_max_header_value}
		and length $cmpcc->{_suwind_min_header_value} )
	{

		my $data_base_file_name_in  = $cmpcc->{_data_base_file_name_in};
		my $data_base_file_name_out = $cmpcc->{_data_base_file_name_out};
		my $header_word             = $cmpcc->{_header_word};
		my $suwind_skip             = $cmpcc->{_suwind_skip};
		my $suwind_min_header_value = $cmpcc->{_suwind_min_header_value};
		my $suwind_max_header_value = $cmpcc->{_suwind_max_header_value};

=head2 SYNOPSIS

PERL PROGRAM NAME: set_data.pm

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		my $log      = message->new();
		my $run      = flow->new();
		my $data_in  = data_in->new();
		my $suwind   = suwind->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@suwind);
		my (@data_out);

=head2 Set up

	data_in parameter values

=cut

		$data_in->clear();
		$data_in->base_file_name( quotemeta($data_base_file_name_in) );
		$data_in->suffix_type( quotemeta('su') );
		$data_in[1] = $data_in->Step();

=head2 Set up

	suwind parameter values

=cut

		$suwind->clear();
		$suwind->max( quotemeta($suwind_max_header_value) );
		$suwind->min( quotemeta($suwind_min_header_value) );
		$suwind->setheaderword( quotemeta($header_word) );
		$suwind[1] = $suwind->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name( quotemeta($data_base_file_name_out) );
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $suwind[1], $in, $data_in[1], $out, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print("cmpcc, set_data, unexpected\n");
	}

	return ($result);

}

=head2 sub set_data_base_file_name_in

=cut

sub set_data_base_file_name_in {
	my ( $self, $data_base_file_name_in ) = @_;

	my $result;

	if ( length $data_base_file_name_in ) {

		$cmpcc->{_data_base_file_name_in} = $data_base_file_name_in;

	}
	else {
		print("cmpcc, data_base_file_name_in=data_base_file_name_in\n");
	}

	return ($result);
}

=head2 sub set_data_base_file_name_out

=cut

sub set_data_base_file_name_out {
	my ( $self, $data_base_file_name_out ) = @_;

	my $result;

	if ( length $data_base_file_name_out ) {

		$cmpcc->{_data_base_file_name_out} = $data_base_file_name_out;

	}
	else {
		print("cmpcc, data_base_file_name_out=data_base_file_name_out\n");
	}

	return ($result);
}

=head2 sub set_ep_idx

=cut

sub set_ep_idx {
	my ( $self, $ep_idx ) = @_;

	if ( length $ep_idx ) {

		$cmpcc->{_ep_idx} = $ep_idx;

	}
	else {
		print("cmpcc,set_ep_idx-missing value\n");
	}

}

=head2 sub set_ep_number_of

=cut

sub set_ep_number_of {
	my ( $self, $ep_number_of ) = @_;

	my $result;

	if ( length $ep_number_of ) {

		$cmpcc->{_ep_number_of} = $ep_number_of;

	}
	else {
		print("cmpcc, ep_number_of=ep_number_of\n");
	}

	return ($result);
}

=head2 sub set_filter

=cut

sub set_filter {
	my ($self) = @_;

	my $result;

	if (    length $cmpcc->{_data_base_file_name_in}
		and length $cmpcc->{_filter_base_file_name_out}
		and length $cmpcc->{_header_word}
		and length $cmpcc->{_suwind_max_header_value}
		and length $cmpcc->{_suwind_min_header_value} )
	{

		my $data_base_file_name_in    = $cmpcc->{_data_base_file_name_in};
		my $filter_base_file_name_out = $cmpcc->{_filter_base_file_name_out};
		my $header_word               = $cmpcc->{_header_word};
		my $suwind_max_header_value   = $cmpcc->{_suwind_max_header_value};
		my $suwind_min_header_value   = $cmpcc->{_suwind_min_header_value};

=head2 SYNOPSIS

PERL PROGRAM NAME: set_filter.pm

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;


		my $log      = message->new();
		my $run      = flow->new();
		my $data_in  = data_in->new();
		my $suwind   = suwind->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@suwind);
		my (@data_out);

=head2 Set up

	data_in parameter values

=cut

		$data_in->clear();
		$data_in->base_file_name( quotemeta($data_base_file_name_in) );
		$data_in->suffix_type( quotemeta('su') );
		$data_in[1] = $data_in->Step();

=head2 Set up

	suwind parameter values

=cut

		$suwind->clear();
		$suwind->max( quotemeta($suwind_max_header_value) );
		$suwind->min( quotemeta($suwind_min_header_value) );
		$suwind->setheaderword( quotemeta($header_word) );
		$suwind[1] = $suwind->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name( quotemeta($filter_base_file_name_out) );
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $suwind[1], $in, $data_in[1], $out, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		#		  $log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print("cmpcc, set_filter, unexpected\n");
	}

	return ($result);
}

=head2 sub set_filter_base_file_name_in

=cut

sub set_filter_base_file_name_in {
	my ( $self, $filter_base_file_name_in ) = @_;

	my $result;

	if ( length $filter_base_file_name_in ) {

		$cmpcc->{_filter_base_file_name_in} = $filter_base_file_name_in;

	}
	else {
		print("cmpcc, filter_base_file_name_in=filter_base_file_name_in\n");
	}

	return ($result);
}

=head2 sub set_filter_base_file_name_out

=cut

sub set_filter_base_file_name_out {
	my ( $self, $filter_base_file_name_out ) = @_;

	my $result;

	if ( length $filter_base_file_name_out ) {

		$cmpcc->{_filter_base_file_name_out} = $filter_base_file_name_out;

	}
	else {
		print("cmpcc, filter_base_file_name_out=filter_base_file_name_out\n");
	}

	return ($result);
}

=head2 sub set_first_geo_idx

geometry values

=cut

sub set_first_geo_idx {
	my ( $self, $first_geo_idx ) = @_;

	my $result;

	if ( length $first_geo_idx ) {

		$cmpcc->{_first_geo_idx} = $first_geo_idx;

	}
	else {
		print("cmpcc, first_geo_idx=first_geo_idx\n");
	}

	return ($result);
}

=head2 sub set_first_geo_x_m4calc 

geometry values

=cut

sub set_first_geo_x_m4calc {
	my ( $self, $first_geo_x_m4calc ) = @_;

	my $result;

	if ( length $first_geo_x_m4calc ) {

		$cmpcc->{_first_geo_x_m4calc} = $first_geo_x_m4calc;

	}
	else {
		print("cmpcc, first_geo_x_m4calc=first_geo_x_m4calc\n");
	}

	return ($result);
}

=head2 sub set_first_line 

geometry values

=cut

sub set_first_line {
	my ( $self, $first_line ) = @_;

	my $result;

	if ( length $first_line ) {

		$cmpcc->{_first_line} = $first_line;

	}
	else {
		print("cmpcc, first_line=first_line\n");
	}

	return ($result);
}

=head2 sub set_geo_number_of

=cut

sub set_geo_number_of {
	my ( $self, $geo_number_of ) = @_;

	if ( length $geo_number_of ) {

		$cmpcc->{_geo_number_of} = $geo_number_of;

	}
	else {
		print("cmpcc,set_geo_number_of-- missing value\n");
	}

}

=head2 sub set_geo_x_m_aref

geometry values

=cut

sub set_geo_x_m_aref {
	my ( $self, $aref ) = @_;

	my $result;

	if ( length $aref ) {

		$cmpcc->{_geo_x_m_aref} = $aref;

	}
	else {
		print("cmpcc, set_geo_x_m_aref missing value\n");
	}

	return ($result);
}

=head2 sub set_geo_x_m_aref4cc

Assemble
gx data
for correlation across a sp
24choose2 = 276 traces
48choose2 = 1128 traces
geophone location does not change but is repeated
24, 48 times ( as many times as there are geophones)

=cut

sub set_geo_x_m_aref4cc {
	my ( $self, $aref ) = @_;

	if (    length $cmpcc->{_geo_x_m_aref}
		and length $cmpcc->{_geo_number_of} )
	{
		# initialize
		my @array;

		my $geo_x_m_aref  = $cmpcc->{_geo_x_m_aref};
		my $geo_number_of = $cmpcc->{_geo_number_of};

		for ( my $geo_idx = 0 ; $geo_idx < $geo_number_of ; $geo_idx++ ) {

			$array[$geo_idx] = $geo_x_m_aref;
		}

		$cmpcc->{_geo_x_m_aref4cc} = \@array;

#			print(
#"cmpcc, set_geo_x_m_aref4cc set_ cmpcc->{_geo_x_m_aref4cc} = @{@{$cmpcc->{_geo_x_m_aref4cc}}[1]}\n"
#			);

	}
	else {
		print("cmpcc, set_geo_x_m_aref--missing value(s)\n");
	}

}

=head2 sub set_loaded_geometry_headers

=cut

sub set_loaded_geometry_headers {
	my ($self) = @_;

	if (    length $cmpcc->{_loaded_w_headers_base_file_name_line_out}
		and $cmpcc->{_for_loading_base_file_name_line_in}
		and $cmpcc->{_line_geometry_base_file_name} )
	{

		my $base_file_name_out =
		  $cmpcc->{_loaded_w_headers_base_file_name_line_out};
		my $base_file_name_in = $cmpcc->{_for_loading_base_file_name_line_in};
		my $line_geometry     = $cmpcc->{_line_geometry_base_file_name};

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut




		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;




		my $log      = message->new();
		my $run      = flow->new();
		my $data_in  = data_in->new();
		my $sulhead  = sulhead->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@sulhead);
		my (@data_out);

=head2 Set up

	data_in parameter values

=cut

		$data_in->clear();
		$data_in->base_file_name( quotemeta($base_file_name_in) );
		$data_in->suffix_type( quotemeta('su') );
		$data_in[1] = $data_in->Step();

=head2 Set up

	sulhead parameter values

=cut

		$sulhead->clear();
		$sulhead->cf(
			quotemeta( $DATA_SEISMIC_TXT . '/' . $line_geometry )
			  . $suffix_txt );
		my $values = join( ",", $tracl, $gx, $sx, $offset, $cdp );
		$sulhead->key( quotemeta($values) );
		$sulhead->mc( quotemeta(1) );
		$sulhead[1] = $sulhead->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name($base_file_name_out);
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $sulhead[1], $in, $data_in[1], $out, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print("cmpcc,set_loaded_geometry_headers--missing value(s)\n");
		print(
"cmpcc,set_loaded_geometry_headers, loaded_w_headers_base_file_name_line_out: $cmpcc->{_loaded_w_headers_base_file_name_line_out}\n"
		);
		print(
"cmpcc,set_loaded_geometry_headers, tracl-ordered cross_correlations line: $cmpcc->{_for_loading_base_file_name_line_in}\n"
		);
		print(
"cmpcc,set_loaded_geometry_headers, line_geometry_base_file_name: $cmpcc->{_line_geometry_base_file_name}\n"
		);
	}

}

=head2 sub set_geom4calc

Build geophone index and value arrays

=cut

sub set_geom4calc {

	my ($self) = @_;

	if (    length $cmpcc->{_first_geo_x_m4calc}
		and length $cmpcc->{_last_geo_x_m4calc}
		and length $cmpcc->{_geo_x_inc_m4calc} )
	{

		my @geo_x_m;
		my $geo_number_of;

		my $first_geo_x_m4calc = $cmpcc->{_first_geo_x_m4calc};
		my $last_geo_x_m4calc  = $cmpcc->{_last_geo_x_m4calc};
		my $geo_x_inc_m4calc   = $cmpcc->{_geo_x_inc_m4calc};

		for (
			my $i = 0, my $geo = $first_geo_x_m4calc ;
			$geo <= $last_geo_x_m4calc ;
			$i++, $geo = $geo + $geo_x_inc_m4calc
		  )
		{
			$geo_x_m[$i] = $geo;

			print("geo_x_m=$geo_x_m[$i]\n");

		}

		$geo_number_of = scalar @geo_x_m;

		$cmpcc->{_geo_number_of} = $geo_number_of;
		$cmpcc->{_geo_x_m_aref}  = \@geo_x_m;

		print("geo_number_of = $geo_number_of\n");
	}
	else {
		print("cmpcc, set_geom4calc, missing values\n");
		print(
"cmpcc, set_geom4calc, first_geo_x_m4calc= $cmpcc->{_first_geo_x_m4calc}\n"
		);
		print("last_geo_x_m4calc = cmpcc->{_last_geo_x_m4calc}\n");
		print("geo_x_inc_m4calc  =cmpcc->{_geo_x_inc_m4calc} )\n");
	}

}

=head2 sub set_geom4data

Read geophone and shot locations

=cut

sub set_geom4data {
	my ($self) = @_;

	if (    length $cmpcc->{_base_file_name_gx}
		and length $cmpcc->{_base_file_name_sx} )
	{

		my $manage_files_by2 = manage_files_by2->new();

		my $base_file_name_gx = $cmpcc->{_base_file_name_gx};
		my $base_file_name_sx = $cmpcc->{_base_file_name_sx};

		my $inbound_sx =
		  $DATA_SEISMIC_TXT . '/' . $base_file_name_sx . $suffix_txt;
		my ( $sp_x_m_aref, $num_rows_sx ) =
		  $manage_files_by2->read_1col($inbound_sx);

		my $inbound_gx =
		  $DATA_SEISMIC_TXT . '/' . $base_file_name_gx . $suffix_txt;
		my ( $geo_x_m_aref, $num_rows_gx ) =
		  $manage_files_by2->read_1col($inbound_gx);

				my @sx = @$sp_x_m_aref;
#				print("sx= @sx\n");
#				print("gx= @{$geo_x_m_aref}\n");
#				print("num_rows_sx=$num_rows_sx\n");

		$cmpcc->{_geo_number_of} = $num_rows_gx;
		$cmpcc->{_geo_x_m_aref}  = $geo_x_m_aref;
		$cmpcc->{_sp_x_m_aref}   = $sp_x_m_aref;

	}
	else {
		print("cmpcc, set_geom4data, missing values\n");
		print(
"cmpcc, set_geom4data, base_file_name_gx= $cmpcc->{_base_file_name_gx} \n"
		);
		print(
"cmpcc, set_geom4data, base_file_name_sx= $cmpcc->{_base_file_name_sx} \n"
		);
	}

}

=head2 sub set_geo_spread_m4calc 

geometry values

=cut

sub set_geo_spread_m4calc {

	my ( $self, $geo_spread_m4calc ) = @_;

	my $result;

	if ( length $geo_spread_m4calc ) {

		$cmpcc->{_geo_spread_m4calc} = $geo_spread_m4calc;

	}
	else {
		print("cmpcc, missing value,geo_spread_m4calc=$geo_spread_m4calc\n");
	}

	return ($result);
}

=head2 sub set_geo_x_inc_m4calc

geometry values

=cut

sub set_geo_x_inc_m4calc {
	my ( $self, $geo_x_inc_m4calc ) = @_;

	my $result;

	if ( length $geo_x_inc_m4calc ) {

		$cmpcc->{_geo_x_inc_m4calc} = $geo_x_inc_m4calc;

	}
	else {
		print("cmpcc, missinga value,geo_x_inc_m4calc=geo_x_inc_m4calc\n");
	}

	return ($result);
}

=head2 sub set_header_word

=cut

sub set_header_word {
	my ( $self, $header ) = @_;

	my $result;

	if ( length $header ) {

		$cmpcc->{_header_word} = $header;

	}
	else {
		print("cmpcc, header=header\n");
	}

	return ($result);
}

=head2 sub set_last_geo_x_m4calc 

geometry values

=cut

sub set_last_geo_x_m4calc {
	my ( $self, $last_geo_x_m4calc ) = @_;

	my $result;

	if ( length $last_geo_x_m4calc ) {

		$cmpcc->{_last_geo_x_m4calc} = $last_geo_x_m4calc;

	}
	else {
		print("cmpcc, last_geo_x_m4calc=last_geo_x_m4calc\n");
	}

	return ($result);
}

=head2 sub set_last_line 

geometry values

=cut

sub set_last_line {
	my ( $self, $last_line ) = @_;

	my $result;
	if ( length $last_line ) {

		$cmpcc->{_last_line} = $last_line;

	}
	else {
		print("cmpcc, last_line=last_line\n");
	}

	return ($result);
}

=head2 sub set_line_geometry_base_file_name

Name of file to read

=cut

sub set_line_geometry_base_file_name {
	my ( $self, $geom_file ) = @_;

	if ( length $geom_file ) {

		$cmpcc->{_line_geometry_base_file_name} = $geom_file;

#		print(
#"cmpcc,set_line_geometry_base_file_name,cmpcc->{_line_geometry_base_file_name}=$cmpcc->{_line_geometry_base_file_name}\n"
#		);

	}
	else {
		print("cmpcc, set_line_geometry_base_file_name, missing file name\n");
	}

}

=head2 sub set_sp_x_m_aref

geometry values

=cut

sub set_sp_x_m_aref {
	my ( $self, $aref ) = @_;

	my $result;

	if ( length $aref ) {

		$cmpcc->{_sp_x_m_aref} = $aref;

	}
	else {
		print("cmpcc, set_sp_x_m_aref missing value\n");
	}

	return ($result);
}

=head2 sub set_sp_x_m_aref4cc

Assemble
sp data
for correlation across a sp
24choose2 = 276 traces
48choose2 = 1128 traces

=cut

sub set_sp_x_m_aref4cc {
	my ( $self, $aref ) = @_;

	if (    length $cmpcc->{_sp_x_m_aref}
		and length $cmpcc->{_geo_number_of} )
	{
		# initialize
		my @array;

		my $sp_x_m_aref   = $cmpcc->{_sp_x_m_aref};
		my $geo_number_of = $cmpcc->{_geo_number_of};

		for ( my $geo_idx = 0 ; $geo_idx < $geo_number_of ; $geo_idx++ ) {

			$array[$geo_idx] = $sp_x_m_aref;
		}

		$cmpcc->{_sp_x_m_aref4cc} = \@array;
#
#			print(
#"cmpcc, set_sp_x_m_aref4cc set_ cmpcc->{_sp_x_m_aref4cc} = @{@{$cmpcc->{_sp_x_m_aref4cc}}[0]}\n"
#			);

	}
	else {
		print("cmpcc, set_sp_x_m_aref--missing value(s)\n");
	}

}

=head2 sub suffix_type

geometry values

=cut

sub set_suffix_type {
	my ( $self, $suffix_type ) = @_;

	my $result;

	if ( length $suffix_type ) {

		$cmpcc->{_suffix_type} = $suffix_type;

	}
	else {
		print("cmpcc, missing suffix_type=$suffix_type\n");
	}

	return ($result);
}

=head2 sub set_suwind_max_header_value 

geometry values

=cut

sub set_suwind_max_header_value {
	my ( $self, $suwind_max_header_value ) = @_;

	my $result;

	if ( length $suwind_max_header_value ) {

		$cmpcc->{_suwind_max_header_value} = $suwind_max_header_value;

	}
	else {
		print("cmpcc, suwind_max_header_value=suwind_max_header_value\n");
	}

	return ($result);
}

=head2 sub set_suwind_min_header_value 

geometry values

=cut

sub set_suwind_min_header_value {
	my ( $self, $suwind_min_header_value ) = @_;

	my $result;

	if ( length $suwind_min_header_value ) {

		$cmpcc->{_suwind_min_header_value} = $suwind_min_header_value;

	}
	else {
		print("cmpcc, suwind_min_header_value=suwind_min_header_value\n");
	}

	return ($result);
}

=head2 sub set_suwind_skip 

geometry values

=cut

sub set_suwind_skip {
	my ( $self, $suwind_skip ) = @_;

	my $result;

	if ( length $suwind_skip ) {

		$cmpcc->{_suwind_skip} = $suwind_skip;

	}
	else {
		print("cmpcc, suwind_skip=suwind_skip\n");
	}

	return ($result);
}

=head2 sub set_tracl_order

=cut

sub set_tracl_order {
	my ($self) = @_;

	if (    length $cmpcc->{_tracl_order_base_file_name_in}
		and length $cmpcc->{_tracl_order_base_file_name_out} )
	{

		my $base_file_name_in = $cmpcc->{_tracl_order_base_file_name_in};

		my $base_file_name_out = $cmpcc->{_tracl_order_base_file_name_out};

#		print("cmpcc, set_tracl_order, cmpcc->{_tracl_order_base_file_name_out = $cmpcc->{_tracl_order_base_file_name_out}\n");

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut


		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		my $log      = message->new();
		my $run      = flow->new();
		my $data_in  = data_in->new();
		my $sushw    = sushw->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@sushw);
		my (@data_out);

=head2 Set up

	data_in parameter values

=cut

		$data_in->clear();
		$data_in->base_file_name( quotemeta($base_file_name_in) );
		$data_in->suffix_type( quotemeta('su') );
		$data_in[1] = $data_in->Step();

=head2 Set up

	sushw parameter values

=cut

		$sushw->clear();
		$sushw->first_value( quotemeta('1') );
		$sushw->gather_size( quotemeta(0) );
		$sushw->header_bias( quotemeta(0) );
		$sushw->headerwords( quotemeta($tracl) );
		$sushw->intra_gather_inc( quotemeta(1) );
		$sushw->inter_gather_inc( quotemeta(0) );
		$sushw[1] = $sushw->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name( quotemeta($base_file_name_out) );
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $sushw[1], $in, $data_in[1], $out, $data_out[1], $go );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print("cmpcc, set_tracl_order, missing variable\n");
		print(
"cmpcc, set_tracl_order, tracl_order_base_file_name_in = $cmpcc->{_tracl_order_base_file_name_in}\n"
		);
		print(
"cmpcc, set_tracl_order, tracl_order_base_file_name_out = $cmpcc->{_tracl_order_base_file_name_out}\n"
		);
	}
}

=head2 sub set_tracl_order_base_file_name_in

geometry values

=cut

sub set_tracl_order_base_file_name_in {
	my ( $self, $file ) = @_;

	my $result;

	if ( length $file ) {

		$cmpcc->{_tracl_order_base_file_name_in} = $file;

	}
	else {
		print("cmpcc, set_tracl_order_base_file_name_in, missing value\n");
	}

	return ($result);
}

=head2 sub set_tracl_order_base_file_name_out

geometry values

=cut

sub set_tracl_order_base_file_name_out {
	my ( $self, $file ) = @_;

	my $result;

	if ( length $file ) {

		$cmpcc->{_tracl_order_base_file_name_out} = $file;

	}
	else {
		print("cmpcc, set_tracl_order_base_file_name_out, missing value\n");
	}

	return ($result);
}

=head2 sub set_suxcor

=cut

sub set_suxcor {
	my ($self) = @_;

	my $result;

	if (    length $cmpcc->{_data_base_file_name_in}
		and length $cmpcc->{_data_base_file_name_out}
		and length $cmpcc->{_filter_base_file_name_in} )
	{

		my $data_base_file_name_in   = $cmpcc->{_data_base_file_name_in};
		my $data_base_file_name_out  = $cmpcc->{_data_base_file_name_out};
		my $filter_base_file_name_in = $cmpcc->{_filter_base_file_name_in};

=head2 SYNOPSIS

PERL PROGRAM NAME: set_suxcor.pm

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		my $Project           = Project_config->new();
		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		my $log      = message->new();
		my $run      = flow->new();
		my $data_in  = data_in->new();
		my $suxcor   = suxcor->new();
		my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@suxcor);
		my (@data_out);

=head2 Set up

	data_in parameter values

=cut

		$data_in->clear();
		$data_in->base_file_name( quotemeta($data_base_file_name_in) );
		$data_in->suffix_type( quotemeta('su') );
		$data_in[1] = $data_in->Step();

=head2 Set up

	suxcor parameter values

=cut

		$suxcor->clear();
		$suxcor->panel( quotemeta(0) );
		$suxcor->sufile(
			quotemeta( $DATA_SEISMIC_SU . '/' . $filter_base_file_name_in )
			  . $suffix_su );
		$suxcor[1] = $suxcor->Step();

=head2 Set up

	data_out parameter values

=cut

		$data_out->clear();
		$data_out->base_file_name( quotemeta($data_base_file_name_out) );
		$data_out->suffix_type( quotemeta('su') );
		$data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		@items = ( $suxcor[1], $in, $data_in[1], $out, $data_out[1] );
		$flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		$run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[1] );

		$log->file(localtime);
		$log->file( $flow[1] );

	}
	else {
		print("cmpcc, set_suxcor, \n");
	}

	return ($result);
}

=head2 sub set_shove_geom

=cut

sub set_shove_geom {

	my ($self) = @_;

	my $array                  = array->new();
	my $elements_number_of_pt5 = 0;
	my $elements_number_of_pt4 = 0;
	my $elements_number_of_pt3 = 0;
	my $elements_number_of_pt2 = 0;
	my $elements_number_of_pt1 = 0;

	if ( length $cmpcc->{_ep_idx} ) {

		if ( $cmpcc->{_is_aref4cc_pt5} ) {

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt5} );
			$elements_number_of_pt5 = $array->get_elements_number_of();
			my $vector_pt5_aref = $array->get_one_row_aref();
			$cmpcc->{_vector_pt5_aref} = $vector_pt5_aref;

		print("cmpcc,set_shove_geom,pt5, vector_pt5= @{$cmpcc->{_vector_pt5_aref}}\n");
		print("cmpcc,set_shove_geom,pt5, elements_number_of= $elements_number_of_pt5\n");
		print("cmpcc,set_shove_geom,pt5, plotting cmp locations\n");
		}
		else {
			print("cmpcc, set2shove_geom,pt5, missing variable \n");
		}

		if ( $cmpcc->{_is_aref4cc_pt4} ) {

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt4} );
			$elements_number_of_pt4 = $array->get_elements_number_of();
			my $vector_pt4_aref = $array->get_one_row_aref();
			$cmpcc->{_vector_pt4_aref} = $vector_pt4_aref;

		print("cmpcc,set_shove_geom,pt4, vector_pt4= @{$cmpcc->{_vector_pt4_aref}}\n");
		print("cmpcc,set_shove_geom,pt4, elements_number_of= $elements_number_of_pt4\n");
				print("cmpcc,set_shove_geom,pt5, plotting offset values\n");

		}
		else {
			print("cmpcc, set2shove_geom,pt4, missing variable \n");
		}

		if ( $cmpcc->{_is_aref4cc_pt3} ) {

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt3} );
			$elements_number_of_pt3 = $array->get_elements_number_of();
			my $vector_pt3_aref = $array->get_one_row_aref();
			$cmpcc->{_vector_pt3_aref} = $vector_pt3_aref;

		print("cmpcc,set_shove_geom,pt3, vector_pt3= @{$cmpcc->{_vector_pt3_aref}}\n");
		print("cmpcc,set_shove_geom,pt3, elements_number_of= $elements_number_of_pt3\n");
		print("cmpcc,set_shove_geom,pt5, plotting sx locations\n");

		}
		else {
			print("cmpcc, set2shove_geom,pt3, missing variable \n");
		}

		if ( $cmpcc->{_is_aref4cc_pt2} ) {

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt2} );
			$elements_number_of_pt2 = $array->get_elements_number_of();
			my $vector_pt2_aref = $array->get_one_row_aref();
			$cmpcc->{_vector_pt2_aref} = $vector_pt2_aref;

		print("cmpcc,set_shove_geom,pt2, vector_pt2= @{$cmpcc->{_vector_pt2_aref}}\n");
		print("cmpcc,set_shove_geom,pt2, elements_number_of= $elements_number_of_pt2\n");
		print("cmpcc,set_shove_geom,pt5, plotting gx locations\n");

		}
		else {
			print("cmpcc, set2shove_geom, pt2, missing variable \n");
		}

		if ( $cmpcc->{_is_aref4cc_pt1_tracl} ) {

			my @vector_pt1;

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt2} );
			$elements_number_of_pt2 = $array->get_elements_number_of();

			my $start = $cmpcc->{_ep_idx} * $elements_number_of_pt2 + 1;
			$vector_pt1[0] = $start;

			for (
				my $i = 1, my $j = 0 ;
				$i < $elements_number_of_pt2 ;
				$j++, $i++
			  )
			{

				$vector_pt1[$i] = ( $vector_pt1[$j] + 1 );
			}

			$cmpcc->{_vector_pt1_aref} = \@vector_pt1;

		print("cmpcc,set_shove_geom,with tracl,pt1(i.e.,2), vector_pt1= @{$cmpcc->{_vector_pt1_aref}}\n");
		print("cmpcc,set_shove_geom,with tracl, pt1(i.e.,2), elements_number_of= $elements_number_of_pt2\n");
		print("cmpcc,set_shove_geom,pt5, plotting trace sequential numbers\n");

		}
		else {
			print("cmpcc, set2shove_geom,pt1,tracl,missing variable \n");
		}

		if ( $cmpcc->{_is_aref4cc_pt1} ) {

			$array->clear();
			$array->set_ref( $cmpcc->{_aref4cc_pt1} );
			$elements_number_of_pt1 = $array->get_elements_number_of();
			my $vector_pt1_aref = $array->get_one_row_aref();
			$cmpcc->{_vector_pt1_aref} = $vector_pt1_aref;

		print("cmpcc,set_shove_geom,without tracl,pt2, vector_pt1= $cmpcc->{_vector_pt1_aref}}\n");
		print("cmpcc,set_shove_geom,without tracl, pt2, elements_number_of= $elements_number_of_pt1\n");

		}
		else {
			#NADA
#			 print("cmpcc, set2shove_geom,pt1.b, missing variable \n");
		}

	}
	else {
		print("cmpcc, set_shove_geom, missing variable(s) \n");
	}

}

=head2 sub set2shove_pt1

=cut

sub set2shove_pt1 {

	my ( $self, $aref4cc ) = @_;

	if ( length $aref4cc
		and $aref4cc eq $tracl )
	{

		$cmpcc->{_is_aref4cc_pt1_tracl} = $true;

	}
	elsif ( length $aref4cc ) {

		$cmpcc->{_aref4cc_pt1}          = $aref4cc;
		$cmpcc->{_is_aref4cc_pt1_tracl} = $false;

	}
	else {
		print("cmpcc, set2shove_pt1, missing file name \n");
	}
}

=head2 sub set2shove_pt2

=cut

sub set2shove_pt2 {

	my ( $self, $aref4cc ) = @_;

	if ( length $aref4cc ) {

		$cmpcc->{_aref4cc_pt2}    = $aref4cc;
		$cmpcc->{_is_aref4cc_pt2} = $true;

	}
	else {
		print("cmpcc, set2shove_pt2, missing file name \n");
	}
}

=head2 sub set2shove_pt3

=cut

sub set2shove_pt3 {

	my ( $self, $aref4cc ) = @_;

	if ( length $aref4cc ) {

		$cmpcc->{_aref4cc_pt3}    = $aref4cc;
		$cmpcc->{_is_aref4cc_pt3} = $true;

	}
	else {
		print("cmpcc, set2shove_pt3, missing file name \n");
	}
}

=head2 sub set2shove_pt4

=cut

sub set2shove_pt4 {

	my ( $self, $aref4cc ) = @_;

	if ( length $aref4cc ) {

		$cmpcc->{_aref4cc_pt4}    = $aref4cc;
		$cmpcc->{_is_aref4cc_pt4} = $true;

	}
	else {
		print("cmpcc, set2shove_pt4, missing file name \n");
	}
}

=head2 sub set2shove_pt5

=cut

sub set2shove_pt5 {

	my ( $self, $aref4cc ) = @_;

	if ( length $aref4cc ) {

		$cmpcc->{_aref4cc_pt5}    = $aref4cc;
		$cmpcc->{_is_aref4cc_pt5} = $true;

	}
	else {
		print("cmpcc, set2shove_pt5, missing file name \n");
	}
}

=head2 sub set4loading_base_file_name_line_in

=cut

sub set4loading_base_file_name_line_in {

	my ( $self, $file ) = @_;

	my $result;

	if ( length $file ) {

		$cmpcc->{_for_loading_base_file_name_line_in} = $file;

		#		print("cmpcc,set4loading_base_file_name_line_in,file=$file\n");

	}
	else {
		print("cmpcc,set4loading_base_file_name_line_in, missing file name \n");
	}

}

=head2 sub set4shove_line_geom_base_file_name_out

=cut

sub set4shove_line_geom_base_file_name_out {

	my ( $self, $file ) = @_;

	my $result;

	if ( length $file ) {

		$cmpcc->{_shove_line_geom_base_file_name_out} = $file;

	}
	else {
		print(
"cmpcc, set4shove_line_geom_base_file_name_out, missing file name \n"
		);
	}
}

=head2 sub set4shove_sp_gather_geom_base_file_name_out

=cut

sub set4shove_sp_gather_geom_base_file_name_out {

	my ( $self, $file ) = @_;

	my $result;

	if ( length $file ) {

		$cmpcc->{_shove_sp_gather_geom_base_file_name_out} = $file;
		$cmpcc->{_shove_sp_gather_geom_outbound} =
		  $DATA_SEISMIC_TXT . '/' . $file . $suffix_txt;

	}
	else {
		print(
"cmpcc, set4shove_sp_gather_geom_base_file_name_out, missing file name \n"
		);
	}
}

1;
