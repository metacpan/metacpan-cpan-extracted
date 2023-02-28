package App::SeismicUnixGui::sunix::transform::sutaup;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUTAUP - forward and inverse T-X and F-K global slant stacks		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUTAUP - forward and inverse T-X and F-K global slant stacks		

    sutaup <infile >outfile  [optional parameters]                 	

 Optional Parameters:                                                  
 option=1			=1 for forward F-K domian computation	
				=2 for forward T-X domain computation	
				=3 for inverse F-K domain computation	
				=4 for inverse T-X domain computation	
 dt=tr.dt (from header) 	time sampling interval (secs)           
 nx=ntr   (counted from data)	number of horizontal samples (traces)	
 dx=1				horizontal sampling interval (m)	
 npoints=71			number of points for rho filter		
 pmin=0.0			minimum slope for Tau-P transform (s/m)	
 pmax=.006			maximum slope for Tau-P transform (s/m)	
 np=nx				number of slopes for Tau-P transform	
 ntau=nt			number of time samples in Tau-P domain  
 fmin=3			minimum frequency of interest 	        
 xmin=0			offset on first trace	 	        

 verbose=0	verbose = 1 echoes information				

 tmpdir= 	 if non-empty, use the value as a directory path	
		 prefix for storing temporary files; else if the	
	         the CWP_TMPDIR environment variable is set use		
	         its value for the path; else use tmpfile()		

 Notes:                                                                
 The cascade of a forward and inverse  tau-p transform preserves the	
 relative amplitudes in a data panel, but not the absolute amplitudes  
 meaning that a scale factor must be applied to data output by such a  
 a cascade before the output may be compared to the original data.	
 This is a characteristic of the algorithm employed in this program.	
 (Suradon does not have this problem.)					



 Credits: CWP: Gabriel Alvarez, 1995.

 Reference:       
    Levin, F., editor, 1991, Slant-Stack Processing, Geophysics Reprint 
         Series #14, SEG Press, Tulsa.

 Trace header fields accessed: ns, dt
 Trace header fields modified: dt,d2,f2

Additional substitute subroutines: Juan Lorenzo March 1 2019

inverse_via_fk=3

inverse_via_tx=4

forward_via_fk=1

forward_via_tx=2

compute_via_in=number

outbound_pickfile=pick

dp=1
vmin=1
vmax=2

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sutaup = {
    _compute_via_in    => '',
    _dp                => '',
    _dt                => '',
    _dx                => '',
    _fmin              => '',
    _forward_via_fk    => '1',
    _forward_via_tx    => '2',
    _inverse_via_fk    => '3',
    _inverse_via_tx    => '4',
    _np                => '',
    _npoints           => '',
    _ntau              => '',
    _nx                => '',
    _option            => '',
    _outbound_pickfile => '',
    _pmax              => '',
    _pmin              => '',
    _tmpdir            => '',
    _verbose           => '',
    _vmax              => '',
    _vmin              => '',
    _xmin              => '',
    _Step              => '',
    _note              => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sutaup->{_Step} = 'sutaup' . $sutaup->{_Step};
    return ( $sutaup->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sutaup->{_note} = 'sutaup' . $sutaup->{_note};
    return ( $sutaup->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sutaup->{_compute_via_in}    = '';
    $sutaup->{_dp}                = '';
    $sutaup->{_dt}                = '';
    $sutaup->{_dx}                = '';
    $sutaup->{_fmin}              = '';
    $sutaup->{_forward_via_fk}    = '';
    $sutaup->{_forward_via_tx}    = '';
    $sutaup->{_inverse_via_fk}    = '';
    $sutaup->{_inverse_via_tx}    = '';
    $sutaup->{_np}                = '';
    $sutaup->{_npoints}           = '';
    $sutaup->{_ntau}              = '';
    $sutaup->{_nx}                = '';
    $sutaup->{_option}            = '';
    $sutaup->{_outbound_pickfile} = '';
    $sutaup->{_pmax}              = '';
    $sutaup->{_pmin}              = '';
    $sutaup->{_tmpdir}            = '';
    $sutaup->{_verbose}           = '';
    $sutaup->{_vmax}              = '';
    $sutaup->{_vmin}              = '';
    $sutaup->{_xmin}              = '';
    $sutaup->{_Step}              = '';
    $sutaup->{_note}              = '';
}

=head2 sub compute_via_in 


=cut

sub compute_via_in {

    my ( $self, $compute_via_in ) = @_;
    if ( $compute_via_in ne $empty_string ) {

        $sutaup->{_compute_via_in} = $compute_via_in;
        $sutaup->{_note} =
          $sutaup->{_note} . ' compute_via_in=' . $sutaup->{_compute_via_in};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' compute_via_in=' . $sutaup->{_compute_via_in};

    }
    else {
        print("sutaup, compute_via_in, missing compute_via_in,\n");
    }
}

=head2 sub dp 

Old was:
    if (defined($sutaup->{_pmin}) && $sutaup->{_pmax} && $sutaup->{_np} ) {
       $sutaup->{_note} 	= $sutaup->{_note}.' dp='.$sutaup->{_dp};
       $sutaup->{_dp}	    	= ($sutaup->{_pmax} - $sutaup->{_pmin})/ ($sutaup->{_np} -1) ; 
	print("dp is $sutaup->{_dp}\n\n");
    }
    else {
	print("Warning: dp requires np, and pmax and pmin\n");
	print("Declare pmax and pmin and np earlier \n\n");
	print("\tnp is $sutaup->{_np}\n\n");
	print("\tpmax is $sutaup->{_pmax} and pmin is $sutaup->{_pmin}\n\n");
    }
return $sutaup->{_dp};
=cut

sub dp {

    my ( $self, $dp ) = @_;
    if ( $dp ne $empty_string ) {
        if (   defined( $sutaup->{_pmin} )
            && $sutaup->{_pmax}
            && $sutaup->{_np} )
        {
            $sutaup->{_note} = $sutaup->{_note} . ' dp=' . $sutaup->{_dp};
            $sutaup->{_dp} =
              ( $sutaup->{_pmax} - $sutaup->{_pmin} ) / ( $sutaup->{_np} - 1 );
            print("dp is $sutaup->{_dp}\n\n");
        }
        else {
            print("Warning: dp requires np, and pmax and pmin\n");
            print("Declare pmax and pmin and np earlier \n\n");
            print("\tnp is $sutaup->{_np}\n\n");
            print(
                "\tpmax is $sutaup->{_pmax} and pmin is $sutaup->{_pmin}\n\n");
        }
        return $sutaup->{_dp};

    }
    else {
        print("sutaup, dp, missing dp,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $sutaup->{_dt}   = $dt;
        $sutaup->{_note} = $sutaup->{_note} . ' dt=' . $sutaup->{_dt};
        $sutaup->{_Step} = $sutaup->{_Step} . ' dt=' . $sutaup->{_dt};

    }
    else {
        print("sutaup, dt, missing dt,\n");
    }
}

=head2 sub dx 


=cut

sub dx {

    my ( $self, $dx ) = @_;
    if ( $dx ne $empty_string ) {

        $sutaup->{_dx}   = $dx;
        $sutaup->{_note} = $sutaup->{_note} . ' dx=' . $sutaup->{_dx};
        $sutaup->{_Step} = $sutaup->{_Step} . ' dx=' . $sutaup->{_dx};

    }
    else {
        print("sutaup, dx, missing dx,\n");
    }
}

=head2 sub fmin 


=cut

sub fmin {

    my ( $self, $fmin ) = @_;
    if ( $fmin ne $empty_string ) {

        $sutaup->{_fmin} = $fmin;
        $sutaup->{_note} = $sutaup->{_note} . ' fmin=' . $sutaup->{_fmin};
        $sutaup->{_Step} = $sutaup->{_Step} . ' fmin=' . $sutaup->{_fmin};

    }
    else {
        print("sutaup, fmin, missing fmin,\n");
    }
}

=head2 sub forward_via_fk 
        same as subroutine option=1


=cut

sub forward_via_fk {

    my ( $self, $forward_via_fk ) = @_;
    if ( $forward_via_fk ne $empty_string ) {

        $sutaup->{_note} =
          $sutaup->{_note} . ' option=' . $sutaup->{_forward_via_fk};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' option=' . $sutaup->{_forward_via_fk};

    }
    else {
        print("sutaup, forward_via_fk, missing forward_via_fk,\n");
    }
}

=head2 sub forward_via_tx 

        same as subroutine option=2

=cut

sub forward_via_tx {

    my ( $self, $forward_via_tx ) = @_;
    if ( $forward_via_tx ne $empty_string ) {

        $sutaup->{_note} =
          $sutaup->{_note} . ' option=' . $sutaup->{_forward_via_tx};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' option=' . $sutaup->{_forward_via_tx};

    }
    else {
        print("sutaup, forward_via_tx, missing forward_via_tx,\n");
    }
}

=head2 sub inverse_via_fk 

        same as subroutine option=3

=cut

sub inverse_via_fk {

    my ( $self, $inverse_via_fk ) = @_;
    if ( $inverse_via_fk ne $empty_string ) {

        $sutaup->{_note} =
          $sutaup->{_note} . ' option=' . $sutaup->{_inverse_via_fk};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' option=' . $sutaup->{_inverse_via_fk};

    }
    else {
        print("sutaup, inverse_via_fk, missing inverse_via_fk,\n");
    }
}

=head2 sub inverse_via_tx 

        same as subroutine option
	=4
	
=cut

sub inverse_via_tx {

    my ( $self, $inverse_via_tx ) = @_;
    if ( $inverse_via_tx ne $empty_string ) {
    	
    	print("made it, sutaup\n");

        $sutaup->{_note}  = 
          $sutaup->{_note} . ' option=' . $sutaup->{_inverse_via_tx};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' option=' . $sutaup->{_inverse_via_tx};

    }
    else {
        print("sutaup, inverse_via_tx, missing inverse_via_tx,\n");
    }
}

=head2 sub np 


=cut

sub np {

    my ( $self, $np ) = @_;
    if ( $np ne $empty_string ) {

        $sutaup->{_np}   = $np;
        $sutaup->{_note} = $sutaup->{_note} . ' np=' . $sutaup->{_np};
        $sutaup->{_Step} = $sutaup->{_Step} . ' np=' . $sutaup->{_np};

    }
    else {
        print("sutaup, np, missing np,\n");
    }
}

=head2 sub npoints 


=cut

sub npoints {

    my ( $self, $npoints ) = @_;
    if ( $npoints ne $empty_string ) {

        $sutaup->{_npoints} = $npoints;
        $sutaup->{_note} =
          $sutaup->{_note} . ' npoints=' . $sutaup->{_npoints};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' npoints=' . $sutaup->{_npoints};

    }
    else {
        print("sutaup, npoints, missing npoints,\n");
    }
}

=head2 sub ntau 


=cut

sub ntau {

    my ( $self, $ntau ) = @_;
    if ( $ntau ne $empty_string ) {

        $sutaup->{_ntau} = $ntau;
        $sutaup->{_note} = $sutaup->{_note} . ' ntau=' . $sutaup->{_ntau};
        $sutaup->{_Step} = $sutaup->{_Step} . ' ntau=' . $sutaup->{_ntau};

    }
    else {
        print("sutaup, ntau, missing ntau,\n");
    }
}

=head2 sub nx 


=cut

sub nx {

    my ( $self, $nx ) = @_;
    if ( $nx ne $empty_string ) {

        $sutaup->{_nx}   = $nx;
        $sutaup->{_note} = $sutaup->{_note} . ' nx=' . $sutaup->{_nx};
        $sutaup->{_Step} = $sutaup->{_Step} . ' nx=' . $sutaup->{_nx};

    }
    else {
        print("sutaup, nx, missing nx,\n");
    }
}

=head2 sub option 


=cut

sub option {

    my ( $self, $option ) = @_;
    if ( $option ne $empty_string ) {

        $sutaup->{_option} = $option;
        $sutaup->{_note}   = $sutaup->{_note} . ' option=' . $sutaup->{_option};
        $sutaup->{_Step}   = $sutaup->{_Step} . ' option=' . $sutaup->{_option};

    }
    else {
        print("sutaup, option, missing option,\n");
    }
}

=head2 sub outbound_pickfile 

  Provides a default output file name
  for picking data points

  i/p requires a base-file name (i.e. no *.su extension)
	e.g. All_cmp
  o/p  ~/seismics_LSU/FalseRiver/seismics/pl/Bueche/All/H/1/gom/All_cmp_fp_picks
    if  ($file_in) {

Use directory navigation system
        and default parameter file names from
	SeismicUnix class


sub outbound_pickfile {
  my ($variable,$file_in) = @_;
		use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
		my $Project = Project_config->new();
        my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
        my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
        use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_fp $suffix_su) ;

        my $sufile_in			= $file_in.$suffix_su;
  	my $inbound			= $DATA_SEISMIC_SU.'/'.$sufile_in;
  	my $file_out			= $file_in.$suffix_fp;
        $sutaup->{_outbound_pickfile}	= $PL_SEISMIC.'/'.$file_out.'_picks';

	return ($sutaup->{_outbound_pickfile});

     }
}
  
=cut

sub outbound_pickfile {

    my ( $self, $outbound_pickfile ) = @_;

    if ( $outbound_pickfile ne $empty_string ) {

=head2 Use directory navigation system
        and default parameter file names from
		SeismicUnix class

=cut

        use App::SeismicUnixGui::configs::big_streams::Project_config;
        my $Project           = Project_config->new();
        my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
        my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
        use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_fp $suffix_su);

        my $sufile_in = $outbound_pickfile . $suffix_su;
        my $inbound   = $DATA_SEISMIC_SU . '/' . $sufile_in;
        my $file_out  = $outbound_pickfile . $suffix_fp;
        $sutaup->{_outbound_pickfile} =
          $PL_SEISMIC . '/' . $file_out . '_picks';

        return ( $sutaup->{_outbound_pickfile} );

    }
    else {
        print("sutaup, outbound_pickfile, missing outbound_pickfile,\n");
    }
}

=head2 sub pmax 


=cut

sub pmax {

    my ( $self, $pmax ) = @_;
    if ( $pmax ne $empty_string ) {

        $sutaup->{_pmax} = $pmax;
        $sutaup->{_note} = $sutaup->{_note} . ' pmax=' . $sutaup->{_pmax};
        $sutaup->{_Step} = $sutaup->{_Step} . ' pmax=' . $sutaup->{_pmax};

    }
    else {
        print("sutaup, pmax, missing pmax,\n");
    }
}

=head2 sub pmin 


=cut

sub pmin {

    my ( $self, $pmin ) = @_;
    if ( $pmin ne $empty_string ) {

        $sutaup->{_pmin} = $pmin;
        $sutaup->{_note} = $sutaup->{_note} . ' pmin=' . $sutaup->{_pmin};
        $sutaup->{_Step} = $sutaup->{_Step} . ' pmin=' . $sutaup->{_pmin};

    }
    else {
        print("sutaup, pmin, missing pmin,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $sutaup->{_tmpdir} = $tmpdir;
        $sutaup->{_note}   = $sutaup->{_note} . ' tmpdir=' . $sutaup->{_tmpdir};
        $sutaup->{_Step}   = $sutaup->{_Step} . ' tmpdir=' . $sutaup->{_tmpdir};

    }
    else {
        print("sutaup, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sutaup->{_verbose} = $verbose;
        $sutaup->{_note} =
          $sutaup->{_note} . ' verbose=' . $sutaup->{_verbose};
        $sutaup->{_Step} =
          $sutaup->{_Step} . ' verbose=' . $sutaup->{_verbose};

    }
    else {
        print("sutaup, verbose, missing verbose,\n");
    }
}

=head2 sub vmax 


=cut

sub vmax {

    my ( $self, $vmax ) = @_;
    if ( $vmax ne $empty_string ) {

        if ( $vmax > 0 || $vmax < 0 ) {

            $sutaup->{_vmax} = $vmax;
            $sutaup->{_vmax} = $vmax;
            $sutaup->{_pmin} = 1 / $sutaup->{_vmax};
            $sutaup->{_note} =
                $sutaup->{_note}
              . ' vmax='
              . $sutaup->{_vmax}
              . ' pmin='
              . $sutaup->{_pmin};
            $sutaup->{_Step} = $sutaup->{_Step} . ' pmin=' . $sutaup->{_pmin};

        }
        elsif ( $vmax == 0 ) {
            $vmax = $vmax + .001;
        }
        else {
            print("sutaup, vmax, unexpected vmax,\n");
        }

    }
    else {
        print("sutaup, vmax, missing vmax,\n");
    }
}

=head2 sub vmin 

     print("vmin is $sutaup->{_vmin}}\n\n");
=cut

sub vmin {

    my ( $self, $vmin ) = @_;
    if ( $vmin ne $empty_string ) {
    	use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
    	my $control = control->new();
    	
    	$control->set_back_slashBgone($vmin );
    	$vmin = $control->get_back_slashBgone();

        if ( $vmin > 0 || $vmin < 0 ) {

            $sutaup->{_vmin} = $vmin;
            $sutaup->{_pmax} = 1 / $sutaup->{_vmin};
            $sutaup->{_Step} = $sutaup->{_Step} . ' pmax=' . $sutaup->{_pmax};
            $sutaup->{_note} =
                $sutaup->{_note}
              . ' vmin='
              . $sutaup->{_vmin}
              . ' pmax='
              . $sutaup->{_pmax};

        }
        elsif ( $vmin == 0 ) {
            $vmin = $vmin + .001;
        }
        else {
            print("sutaup, vmin, unexpected vmin,\n");
        }
    }
    else {
        print("sutaup, vmin, missing vmin,\n");
    }
}

=head2 sub xmin 


=cut

sub xmin {

    my ( $self, $xmin ) = @_;
    if ( $xmin ne $empty_string ) {

        $sutaup->{_xmin} = $xmin;
        $sutaup->{_note} = $sutaup->{_note} . ' xmin=' . $sutaup->{_xmin};
        $sutaup->{_Step} = $sutaup->{_Step} . ' xmin=' . $sutaup->{_xmin};

    }
    else {
        print("sutaup, xmin, missing xmin,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 18;

    return ($max_index);
}

1;
