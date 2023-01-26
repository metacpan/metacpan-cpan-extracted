package App::SeismicUnixGui::big_streams::iWrite_All_iva_out;

use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iWrite_All_iva_out 
 AUTHOR: Juan Lorenzo
 DATE: April 9 2009 
         sept. 13 2013
         oct. 21 2013
         July 15 2015
 Purpose: Write out best vpicked files from iWrite_All_iva_out 

 DESCRIPTION: 
 Version: 1.1
 update to oop

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

my $iWrite_All_iva_out = {
    _cdp_num => '',
    _file_in => ''
};

=pod =head3

 Import directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $in $to $go);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();
my ($PL_SEISMIC) = $Project->PL_SEISMIC();

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $iWrite_All_iva_out->{_cdp_num} = '';
    $iWrite_All_iva_out->{_file_in} = '';
}

=pod

 declare local variables

=cut

my ( @sufile_in, @suffix,     @vpicks_stdin );
my ( @cpfile_in, @cpfile_out, @catfile_inbound );
my ( @storefile_outbound,     @flow );
my ( @textfile_in,            @duplicatefile_in, @duplicatefile_out );
my ( @Tvel_duplicate_inbound, @Tvel_duplicate_outbound );

=pod

=head2 subroutine cdp

  sets cdp number to consider  

=cut

sub cdp_num {
    my ( $variable, $cdp_num ) = @_;
    $iWrite_All_iva_out->{_cdp_num} = $cdp_num if defined($cdp_num);
}

=pod =head3

 subroutine file_in
 Required file name
 on which to perform velocity analyses 

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iWrite_All_iva_out->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iWrite_All_iva_out->{_file_in} \n\n");
}

=pod =head3

 subroutine flows
  read in :   ivpicks_old from the PL directory
  write out: 'Final_ivpicks_iva' to the PL directory

            'ivpicks_old' is stored locally

=cut

sub flows {

    # sufile names
    $sufile_in[1] = $iWrite_All_iva_out->{_file_in};

    # file suffixes
    $suffix[1]       = '_cdp' . $iWrite_All_iva_out->{_cdp_num};
    $vpicks_stdin[1] = 'ivpicks_old';

    # cp text file names
    $cpfile_in[1]  = $vpicks_stdin[1];
    $cpfile_out[1] = 'Final_ivpicks_iva';

    # cat file names
    $catfile_inbound[1] =
      $PL_SEISMIC . '/' . $cpfile_in[1] . '_' . $sufile_in[1] . $suffix[1];
    $storefile_outbound[1] =
      $PL_SEISMIC . '/' . $cpfile_out[1] . '_' . $sufile_in[1] . $suffix[1];

    $textfile_in[1] =
      'ivpicks_old' . '_' . $iWrite_All_iva_out->{_file_in} . $suffix[1];

    $duplicatefile_in[1] =
      'ivpicks_' . $iWrite_All_iva_out->{_file_in} . $suffix[1];

    $Tvel_duplicate_inbound[1] = $PL_SEISMIC . '/' . $duplicatefile_in[1];

    $duplicatefile_out[1] =
      'ivpicks_old' . '_' . $iWrite_All_iva_out->{_file_in} . $suffix[1];

    $Tvel_duplicate_outbound[1] = $PL_SEISMIC . '/' . $duplicatefile_out[1];

    # DEFINE FLOW(S)

    $flow[1] = (
        "							\\
		cp $Tvel_duplicate_inbound[1]  $Tvel_duplicate_outbound[1];	\\
		"
    );
    $flow[2] = (
        "							\\
		cp $catfile_inbound[1]  $storefile_outbound[1];	\\
		"
    );

    # RUN FLOW(S)
    system $flow[1];
    system $flow[2];

    # system 'echo', $flow[1];
    # system 'echo', $flow[2];

}    #end flows

1;
