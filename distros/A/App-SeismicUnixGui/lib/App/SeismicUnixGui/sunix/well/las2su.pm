package App::SeismicUnixGui::sunix::well::las2su;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  LAS2SU - convert las2 format well log curves to su traces	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 LAS2SU - convert las2 format well log curves to su traces	

  las2su <stdin nskip= ncurve= >stdout [optional params]	

 Required parameters:						
 none								
 Optional parameters:						
 ncurve=automatic	number of log curves in the las file	
 dz=0.5		input depth sampling (ft)		
 m=0			output (d1,f1) in feet			
			=1 output (d1,f1) in meters		
 ss=0			do not subsample (unless nz > 32767 )	
			=1 pass every other sample		
 verbose=0		=1 to echo las header lines to screen	
 outhdr=las_header.asc	name of file for las headers		

 Notes:							
 1. It is recommended to run LAS_CERTIFY available from CWLS	
    at http://cwls.org.					
 2. First log curve MUST BE depth.				
 3. If number of depth levels > 32767 (segy NT limit)		
    then input is subsampled by factor of 2 or 4 as needed	
 4. Logs may be isolated using tracl header word (1,2,...,ncurve) 
    tracl=1 is depth						

 If the input LAS file contains sonic data as delta t or interval
 transit time and you plan to use these data for generating a 
 reflection coefficient time series in suwellrf, convert the sonic
 trace to velocity using suop with op=s2v (sonic to velocity) 
 before input of the velocity trace to suwellrf.		", 

 Caveat:							", 
 No trap is made for the commonly used null value in LAS files 
 (-999.25). The null value will be output as ?999.25, which	
 really messes up a suxwigb display of density data because the
 ?999.25 skews the more or less 2.5 values of density.		
 The user needs to edit out null values (-999.25) before running
 other programs, such as "suwellrf".				


 Credits:
  *	Chris Liner based on code by Ferhan Ahmed and a2b.c (June 2005)
  *            (Based on code by Ferhan Ahmed and a2b.c)
  *            I gratefully acknowledge Saudi Aramco for permission
  *            to release this code developed while I worked for the
  *            EXPEC-ARC research division.
  *	CWP: John Stockwell 31 Oct 2006, combining lasstrip and
  *	CENPET: lasstrip 2006 by Werner Heigl
  *
  *     Rob Hardy: allow the ncurve parameter to work correctly if set
  *    - change string length to 400 characters to allow more curves
  *    - note nskip in header is totally ignored !
  *
  * Ideas for improvement:
  *	add option to chop off part of logs (often shallow
  *	   portions are not of interest
  *	cross check sampling interval from header against
  *	   values found from first log curve (=depth)
  *
 

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $las2su = {
    _dz      => '',
    _m       => '',
    _ncurve  => '',
    _nskip   => '',
    _outhdr  => '',
    _ss      => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $las2su->{_Step} = 'las2su' . $las2su->{_Step};
    return ( $las2su->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $las2su->{_note} = 'las2su' . $las2su->{_note};
    return ( $las2su->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $las2su->{_dz}      = '';
    $las2su->{_m}       = '';
    $las2su->{_ncurve}  = '';
    $las2su->{_nskip}   = '';
    $las2su->{_outhdr}  = '';
    $las2su->{_ss}      = '';
    $las2su->{_verbose} = '';
    $las2su->{_Step}    = '';
    $las2su->{_note}    = '';
}

=head2 sub dz 


=cut

sub dz {

    my ( $self, $dz ) = @_;
    if ( $dz ne $empty_string ) {

        $las2su->{_dz}   = $dz;
        $las2su->{_note} = $las2su->{_note} . ' dz=' . $las2su->{_dz};
        $las2su->{_Step} = $las2su->{_Step} . ' dz=' . $las2su->{_dz};

    }
    else {
        print("las2su, dz, missing dz,\n");
    }
}

=head2 sub m 


=cut

sub m {

    my ( $self, $m ) = @_;
    if ( $m ne $empty_string ) {

        $las2su->{_m}    = $m;
        $las2su->{_note} = $las2su->{_note} . ' m=' . $las2su->{_m};
        $las2su->{_Step} = $las2su->{_Step} . ' m=' . $las2su->{_m};

    }
    else {
        print("las2su, m, missing m,\n");
    }
}

=head2 sub ncurve 


=cut

sub ncurve {

    my ( $self, $ncurve ) = @_;
    if ( $ncurve ne $empty_string ) {

        $las2su->{_ncurve} = $ncurve;
        $las2su->{_note}   = $las2su->{_note} . ' ncurve=' . $las2su->{_ncurve};
        $las2su->{_Step}   = $las2su->{_Step} . ' ncurve=' . $las2su->{_ncurve};

    }
    else {
        print("las2su, ncurve, missing ncurve,\n");
    }
}

=head2 sub nskip 


=cut

sub nskip {

    my ( $self, $nskip ) = @_;
    if ( $nskip ne $empty_string ) {

        $las2su->{_nskip} = $nskip;
        $las2su->{_note}  = $las2su->{_note} . ' nskip=' . $las2su->{_nskip};
        $las2su->{_Step}  = $las2su->{_Step} . ' nskip=' . $las2su->{_nskip};

    }
    else {
        print("las2su, nskip, missing nskip,\n");
    }
}

=head2 sub outhdr 


=cut

sub outhdr {

    my ( $self, $outhdr ) = @_;
    if ( $outhdr ne $empty_string ) {

        $las2su->{_outhdr} = $outhdr;
        $las2su->{_note}   = $las2su->{_note} . ' outhdr=' . $las2su->{_outhdr};
        $las2su->{_Step}   = $las2su->{_Step} . ' outhdr=' . $las2su->{_outhdr};

    }
    else {
        print("las2su, outhdr, missing outhdr,\n");
    }
}

=head2 sub ss 


=cut

sub ss {

    my ( $self, $ss ) = @_;
    if ( $ss ne $empty_string ) {

        $las2su->{_ss}   = $ss;
        $las2su->{_note} = $las2su->{_note} . ' ss=' . $las2su->{_ss};
        $las2su->{_Step} = $las2su->{_Step} . ' ss=' . $las2su->{_ss};

    }
    else {
        print("las2su, ss, missing ss,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $las2su->{_verbose} = $verbose;
        $las2su->{_note} =
          $las2su->{_note} . ' verbose=' . $las2su->{_verbose};
        $las2su->{_Step} =
          $las2su->{_Step} . ' verbose=' . $las2su->{_verbose};

    }
    else {
        print("las2su, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 6;

    return ($max_index);
}

1;
