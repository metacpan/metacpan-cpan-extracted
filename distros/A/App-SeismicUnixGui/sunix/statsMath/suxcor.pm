package App::SeismicUnixGui::sunix::statsMath::suxcor;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUXCOR - correlation with user-supplied filter			
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUXCOR - correlation with user-supplied filter			

 suxcor <stdin >stdout  filter= [optional parameters]			

 Required parameters: ONE of						
 sufile=		file containing SU traces to use as filter	
 filter=		user-supplied correlation filter (ascii)	

 Optional parameters:							
 vibroseis=0		=nsout for correlating vibroseis data		
 first=1		supplied trace is default first element of	
 			correlation.  =0 for it to be second.		
 panel=0		use only the first trace of sufile as filter 	
 			=1 xcor trace by trace an entire gather		
 ftwin=0		first sample on the first trace of the window 	
 				(only with panel=1)		 	
 ltwin=0		first sample on the last trace of the window 	
 				(only with panel=1)		 	
 ntwin=nt		number of samples in the correlation window	
 				(only with panel=1)		 	
 ntrc=48		number of traces on a gather 			
 				(only with panel=1)		 	

 Trace header fields accessed: ns					
 Trace header fields modified: ns					

 Notes: It is quietly assumed that the time sampling interval on the	
 single trace and the output traces is the same as that on the traces	
 in the input file.  The sufile may actually have more than one trace,	
 but only the first trace is used when panel=0. When panel=1 the number
 of traces in the sufile MUST be the same as the number of traces in 	
 the input.								

 Examples:								
	suplane | suwind min=12 max=12 >TRACE				
	suxcor<DATA sufile=TRACE |...					
 Here, the su data file, "DATA", is correlated trace by trace with the
 the single su trace, "TRACE".					

	suxcor<DATA filter=1,2,1 | ...					
 Here, the su data file, "DATA", is correlated trace by trace with the
 the filter shown.							

 Correlating vibroseis data with a vibroseis sweep:			
 suxcor < data sufile=sweep vibroseis=nsout  |...			

 is equivalent to, but more efficient than:				

 suxcor < data sufile=sweep |						
 suwind itmin=nsweep itmax=nsweep+nsout | sushw key=delrt a=0.0 |...   

 sweep=vibroseis sweep in SU format, nsweep=number of samples on	
 the vibroseis sweep, nsout eqis equal to the
 desired number of samples on output	

 or									
 suxcor < data sufile=sweep |						
 suwind itmin=nsweep itmax=nsweep+nsout | sushw key=delrt a=0.0 |...   

 tsweep=sweep length in seconds, tout=desired output trace length in seconds

 In the spatially variant case (panel=1), a window with linear slope 	
 can be defined:						 	
 	ftwin is the first sample of the first trace in the gather,  	
 	ltwin is the first sample of the last trace in the gather,	
 	ntwin is the lengthe of the window, 				
 	ntrc is the the number of traces in a gather. 			

 	If the data consists of a number gathers which need to be 	
	correlated with the same number gathers in the sufile, ntrc	
	assures that the correlating window re-starts for each gather.	

	The default window is non-sloping and takes the entire trace	
	into account (ftwin=ltwin=0, ntwin=nt).				


 Credits:
	CWP: Jack K. Cohen, Michel Dietrich
      CWP: modified by Ttjan to include cross correlation of panels
	   permitting spatially and temporally varying cross correlation.
      UTK: modified by Rick Williams for vibroseis correlation option.

  CAVEATS: 
     In the option, panel=1 the number of traces in the sufile must be 
     the same as the number of traces on the input.

 Trace header fields accessed: ns
 Trace header fields modified: ns

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

my $get     = L_SU_global_constants->new();
my $Project = Project_config->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suxcor = {
    _filter    => '',
    _first     => '',
    _ftwin     => '',
    _itmin     => '',
    _ltwin     => '',
    _nsout     => '',
    _ntrc      => '',
    _ntwin     => '',
    _panel     => '',
    _sufile    => '',
    _sweep     => '',
    _tsweep    => '',
    _vibroseis => '',
    _Step      => '',
    _note      => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name
		Keeps track of actions for execution in the system

=cut

sub Step {

    $suxcor->{_Step} = 'suxcor' . $suxcor->{_Step};
    return ( $suxcor->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suxcor->{_note} = 'suxcor' . $suxcor->{_note};
    return ( $suxcor->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suxcor->{_filter}    = '';
    $suxcor->{_first}     = '';
    $suxcor->{_ftwin}     = '';
    $suxcor->{_itmin}     = '';
    $suxcor->{_ltwin}     = '';
    $suxcor->{_nsout}     = '';
    $suxcor->{_ntrc}      = '';
    $suxcor->{_ntwin}     = '';
    $suxcor->{_panel}     = '';
    $suxcor->{_sufile}    = '';
    $suxcor->{_sweep}     = '';
    $suxcor->{_tsweep}    = '';
    $suxcor->{_vibroseis} = '';
    $suxcor->{_Step}      = '';
    $suxcor->{_note}      = '';
}

=head2 sub filter 

	ASCII data filter

=cut

sub filter {

    my ( $self, $filter ) = @_;
    if ( $filter ne $empty_string ) {

        $suxcor->{_filter} = $filter;
        $suxcor->{_note}   = $suxcor->{_note} . ' filter=' . $suxcor->{_filter};
        $suxcor->{_Step}   = $suxcor->{_Step} . ' filter=' . $suxcor->{_filter};

    }
    else {
        print("suxcor, filter, missing filter,\n");
    }
}

=head2 sub first 

	supplied trace is default first element of correlation if 1
	0 for it to be second

=cut

sub first {

    my ( $self, $first ) = @_;
    if ( $first ne $empty_string ) {

        $suxcor->{_first} = $first;
        $suxcor->{_note}  = $suxcor->{_note} . ' first=' . $suxcor->{_first};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' first=' . $suxcor->{_first};

    }
    else {
        print("suxcor, first, missing first,\n");
    }
}

=head2 sub ftwin 

	first sample on the first trace of the window
	panel =1

=cut

sub ftwin {

    my ( $self, $ftwin ) = @_;
    if ( $ftwin ne $empty_string ) {

        $suxcor->{_ftwin} = $ftwin;
        $suxcor->{_note}  = $suxcor->{_note} . ' ftwin=' . $suxcor->{_ftwin};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' ftwin=' . $suxcor->{_ftwin};

    }
    else {
        print("suxcor, ftwin, missing ftwin,\n");
    }
}

=head2 sub itmin 


=cut

sub itmin {

    my ( $self, $itmin ) = @_;
    if ( $itmin ne $empty_string ) {

        $suxcor->{_itmin} = $itmin;
        $suxcor->{_note}  = $suxcor->{_note} . ' itmin=' . $suxcor->{_itmin};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' itmin=' . $suxcor->{_itmin};

    }
    else {
        print("suxcor, itmin, missing itmin,\n");
    }
}

=head2 sub ltwin 

	first sample on the last trace of the window
	panel =1

=cut

sub ltwin {

    my ( $self, $ltwin ) = @_;
    if ( $ltwin ne $empty_string ) {

        $suxcor->{_ltwin} = $ltwin;
        $suxcor->{_note}  = $suxcor->{_note} . ' ltwin=' . $suxcor->{_ltwin};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' ltwin=' . $suxcor->{_ltwin};

    }
    else {
        print("suxcor, ltwin, missing ltwin,\n");
    }
}

=head2 sub nsout 


=cut

sub nsout {

    my ( $self, $nsout ) = @_;
    if ( $nsout ne $empty_string ) {

        $suxcor->{_nsout} = $nsout;
        $suxcor->{_note}  = $suxcor->{_note} . ' nsout=' . $suxcor->{_nsout};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' nsout=' . $suxcor->{_nsout};

    }
    else {
        print("suxcor, nsout, missing nsout,\n");
    }
}

=head2 sub ntrc 


=cut

sub ntrc {

    my ( $self, $ntrc ) = @_;
    if ( $ntrc ne $empty_string ) {

        $suxcor->{_ntrc} = $ntrc;
        $suxcor->{_note} = $suxcor->{_note} . ' ntrc=' . $suxcor->{_ntrc};
        $suxcor->{_Step} = $suxcor->{_Step} . ' ntrc=' . $suxcor->{_ntrc};

    }
    else {
        print("suxcor, ntrc, missing ntrc,\n");
    }
}

=head2 sub ntwin 


=cut

sub ntwin {

    my ( $self, $ntwin ) = @_;
    if ( $ntwin ne $empty_string ) {

        $suxcor->{_ntwin} = $ntwin;
        $suxcor->{_note}  = $suxcor->{_note} . ' ntwin=' . $suxcor->{_ntwin};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' ntwin=' . $suxcor->{_ntwin};

    }
    else {
        print("suxcor, ntwin, missing ntwin,\n");
    }
}

=head2 sub panel 

	decide whether to use first trace of sufile as filter (=0) 
	or to xcor trace by trace an entire gather

=cut

sub panel {

    my ( $self, $panel ) = @_;
    if ( $panel ne $empty_string ) {

        $suxcor->{_panel} = $panel;
        $suxcor->{_note}  = $suxcor->{_note} . ' panel=' . $suxcor->{_panel};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' panel=' . $suxcor->{_panel};

    }
    else {
        print("suxcor, panel, missing panel,\n");
    }
}

=head2 sub sufile 

	Define the data to be used as the correlation
	This is the 'filter'

=cut

sub sufile {

    my ( $self, $sufile ) = @_;
    if ( $sufile ne $empty_string ) {

        use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_su);
        use File::Basename;

        my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
        my $new_file_name = $sufile;

        # forcing a suffix  12.8.21
        $new_file_name = basename($sufile);

        #print("1. suxcor sufile, new_file_name= $new_file_name\n");

        $suxcor->{_sufile} = $DATA_SEISMIC_SU . '/' . $new_file_name;

        $suxcor->{_note} = $suxcor->{_note} . ' sufile=' . $suxcor->{_sufile};
        $suxcor->{_Step} = $suxcor->{_Step} . ' sufile=' . $suxcor->{_sufile};

    }
    else {
        print("suxcor, sufile, missing sufile,\n");
    }
}

=head2 sub sweep 


=cut

sub sweep {

    my ( $self, $sweep ) = @_;
    if ( $sweep ne $empty_string ) {

        $suxcor->{_sweep} = $sweep;
        $suxcor->{_note}  = $suxcor->{_note} . ' sweep=' . $suxcor->{_sweep};
        $suxcor->{_Step}  = $suxcor->{_Step} . ' sweep=' . $suxcor->{_sweep};

    }
    else {
        print("suxcor, sweep, missing sweep,\n");
    }
}

=head2 sub tsweep 


=cut

sub tsweep {

    my ( $self, $tsweep ) = @_;
    if ( $tsweep ne $empty_string ) {

        $suxcor->{_tsweep} = $tsweep;
        $suxcor->{_note}   = $suxcor->{_note} . ' tsweep=' . $suxcor->{_tsweep};
        $suxcor->{_Step}   = $suxcor->{_Step} . ' tsweep=' . $suxcor->{_tsweep};

    }
    else {
        print("suxcor, tsweep, missing tsweep,\n");
    }
}

=head2 sub vibroseis 


=cut

sub vibroseis {

    my ( $self, $vibroseis ) = @_;
    if ( $vibroseis ne $empty_string ) {

        $suxcor->{_vibroseis} = $vibroseis;
        $suxcor->{_note} =
          $suxcor->{_note} . ' vibroseis=' . $suxcor->{_vibroseis};
        $suxcor->{_Step} =
          $suxcor->{_Step} . ' vibroseis=' . $suxcor->{_vibroseis};

    }
    else {
        print("suxcor, vibroseis, missing vibroseis,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 7;

    return ($max_index);
}

1;
