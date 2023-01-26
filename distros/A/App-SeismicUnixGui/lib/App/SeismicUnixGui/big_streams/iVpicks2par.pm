package App::SeismicUnixGui::big_streams::iVpicks2par;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::big_streams::iWrite_All_iva_out';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iVpicks2par 
 AUTHOR: Juan Lorenzo
 DATE:   Nov 1 2012,
         sept. 13 2013
         oct. 21 2013
         July 15 2015

 DESCRIPTION: 
 Version: 1.1
 Package used for interactive velocity analysis
 Convert pick files into a format suvelan can use

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES


=cut

=pod

=head3 STEPS

 1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

=cut

=pod

set defaults

VELAN DATA 
 m/s

 
=cut

my $iVpicks2par = {
    _cdp_num => '',
    _file_in => '',
    _base_file_name => '',
};

=pod =head3

 Import directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $in $to $go);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();
my ($PL_SEISMIC) = $Project->PL_SEISMIC();


my $get = L_SU_global_constants->new();
my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=pod

 instantiate programs

=cut

my $iWrite_All_iva_out = iWrite_All_iva_out->new();
my $test               = manage_files_by2->new();

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $iVpicks2par->{_cdp_num} = '';
    $iVpicks2par->{_file_in} = '';
    $iVpicks2par->{_base_file_name}   = '';
}
my ( @suffix,      @file_in,  @sortfile_in, @inbound );
my ( @parfile_out, @outbound, @sort,        @mkparfile );
my (@flow);


=pod

=head2 subroutine cdp

  sets cdp number to consider  

=cut

sub cdp_num {
    my ( $variable, $cdp_num ) = @_;
    $iVpicks2par->{_cdp_num} = $cdp_num if defined($cdp_num);
}

=pod =head3

 subroutine file_in
 Required file name
 on which to perform velocity analyses 

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iVpicks2par->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iVpicks2par->{_file_in} \n\n");
}

=pod 
=head3

  sort and properly format picks for seismic unix
  Sunmo will need these values properly formatted

=cut

sub flows {

    # suffixes
    $suffix[1] = '_cdp' . $iVpicks2par->{_cdp_num};

    # sort file names
    $file_in[1]     = $iVpicks2par->{_file_in};
    $sortfile_in[1] = 'ivpicks_old' . '_' . $file_in[1] . $suffix[1];

    #  $sortfile_out[1] = 'ivpicks_sorted_'.$file_in[1];
    $inbound[1] = $PL_SEISMIC . '/' . $sortfile_in[1];

    # par file names
    $parfile_out[1] = 'ivpicks_sorted_par_' . $file_in[1] . $suffix[1];
    $outbound[1]    = $PL_SEISMIC . '/' . $parfile_out[1];

	# my $data_scale = _get_data_scale();
	# print("2. iVpicks2par, data_scale = $data_scale\n");

# 		| awk '{print $1, $2* ${data_scale} }'	
    # SORT a TEXT FILE
    $sort[1] = q(
        sort -n	);

    # CONVERT TEXT FILE TO PAR FILE
    $mkparfile[1] = (
        "mkparfile			\\
		string1=tnmo 						\\
		string2=vnmo 						\\
		"
    );

    # Prepare picks for sunmo
    #  DEFINE FLOW(S)
    $flow[1] = (
        " 						\\
		$sort[1]  						\\
		< $inbound[1] |					\\
		$mkparfile[1] 					\\
		>$outbound[1] 	 				\\
		&						\\
		"
    );

    # RUN FLOW(S)
    system $flow[1];

    # system 'echo', $flow[1];
}


#end flows
# following line returns a "true" logical value to the program
1;
