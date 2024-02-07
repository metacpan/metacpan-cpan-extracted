package App::SeismicUnixGui::sunix::transform::succwt;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUCCWT - Complex continuous wavelet transform of seismic traces	
 AUTHOR: Juan Lorenzo (Perl module only) 
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUCCWT - Complex continuous wavelet transform of seismic traces	

 succwt < tdata.su > tfdata.su	[optional parameters]			

 Required Parameters:							
 None									

 Optional Parameters:							
 noct=5	Number of octaves (int)					
 nv=10		Number of voices per octave (int)			
 fmax=Nyq	Highest frequency in transform				
 p=-0.5	Power of scale value normalizing CWT			
		=0 for amp-preserved spec. decomp.			
 c=1/(2*fmax)	Time-domain inverse gaussian damping parameter		
		(bigger c means more wavelet oscillations,		
		default gives minimal oscillations)			
 k=1		Use complex Morlet as wavelet transform kernel		
		=2 use Fourier kernel ... Exp[i 2 pi f t]		
 fs=1		Use dyadic freq sampling (CWT standard, 36honors		
		noct, nv)						
		=2 use linear freq sampling (Fourier standard)		
 df=1		Frequency sample interval in Hz (used only for fs=2)	
			NOTE: not yet implimented (hardwired to df=1) 	
 dt=(from tr.dt)	Sample interval override (in secs, if time data)
 verbose=0	 Run silent, except echo c value. (=1 for more info)	

 Examples:								
 This generates amplitude spec of the CWT impulse response (IR).	
  suspike ntr=1 ix1=1 nt=125 | succwt | suamp | suximage & 		
 Real part of Fourier IR with linear freq sampling:			
 suspike ntr=1 ix1=1 nt=125 | succwt k=2 fs=2 | suamp mode=real | suximage &
 Real part of Fourier IR with dyadic freq sampling: 			
 suspike ntr=1 ix1=1 nt=125 | succwt k=2 | suamp mode=real | suximage &

 Inverse CWT: (within a constant scale factor)				
	... | succwt p=-1 | suamp mode=real | sustack key=cdp > inv.su	

 Notes:								
 1. Total number of scales: nscale = noct*nv				
 2. Each input trace spawns nscale complex output traces		
 3. Lowest frequency in the transform is fmax/( 2^(noct-1/nv) )	
 4. Header field (cdp) used as cwt spectrum counter			
 5. Header field (cdpt) used as scale counter within cwt spectrum	
 6. Header field (gut) holds number of cwt scales `na'			
 7. Header field (unscale) holds CWT scale `a'				

 Header fields set: tracl, cdp, cdpt, unscale, gut			



 Copyright (c) University of Tulsa, 2003-4.
 All rights reserved.			
 Author:	UTulsa: Chris Liner, SEP: Bob Clapp

 todo:
	fix fs=2 case to allow df not equal to 1
 History:36
 6/18/04
	major overhaul by Clapp, including fourier implementation.
	Speedup ~ 41 times	(4100 %)
 2/20/04
	made p=-0.5 default
 2/16/04
	added p option to experiment with CWT normalization
 2/12/04
	replace fb (bandwidth parameter) with c (t-domain gaussian damping const.)
 2/10/04 --- in sync with EAS paper in prep
	changed morlet scaling (c = 1) to preserve time-domain peak amplitude
	changed morlet exp sign to std CWT definition (conjugate) and 
	mathematica result that only gives positive freq gaussian with neg exp
 1/26/04
	added linear frequency sampling option36
 1/23/04
	figured out fb and made it a getpar
	key: Look at real ccwt output and determine fb by number of 
		oscillations desired:	Default gives -+-+-+-
 1/20/04
	beefed up verbose output 
	dimension wavelet to length 2*nt and change correlation call
	... this is done to avoid conv edge effects
 1/19/04
	added fourier wavlet option for comparison with Fourier Transform action
 1/17/04
	complex morlet amp scaling now set to preserve first scale amp with IR 
 1/16/04
	added dt getpar to handle depth input properly
	preserves first tracl so tracl is ok after spice
 11/11/03
	initial version

 Trace header fields set: tracl, cdp, cdpt, unscale, gut

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $succwt = {
    _c       => '',
    _df      => '',
    _dt      => '',
    _fmax    => '',
    _fs      => '',
    _k       => '',
    _noct    => '',
    _nscale  => '',
    _ntr     => '',
    _nv      => '',
    _p       => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $succwt->{_Step} = 'succwt' . $succwt->{_Step};
    return ( $succwt->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $succwt->{_note} = 'succwt' . $succwt->{_note};
    return ( $succwt->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $succwt->{_c}       = '';
    $succwt->{_df}      = '';
    $succwt->{_dt}      = '';
    $succwt->{_fmax}    = '';
    $succwt->{_fs}      = '';
    $succwt->{_k}       = '';
    $succwt->{_noct}    = '';
    $succwt->{_nscale}  = '';
    $succwt->{_ntr}     = '';
    $succwt->{_nv}      = '';
    $succwt->{_p}       = '';
    $succwt->{_verbose} = '';
    $succwt->{_Step}    = '';
    $succwt->{_note}    = '';
}

=head2 sub c 


=cut

sub c {

    my ( $self, $c ) = @_;
    if ( defined $c
        && $c ne $empty_string )
    {

        $succwt->{_c}    = $c;
        $succwt->{_note} = $succwt->{_note} . ' c=' . $succwt->{_c};
        $succwt->{_Step} = $succwt->{_Step} . ' c=' . $succwt->{_c};

    }
    else {
        print("succwt, c, missing c,\n");
    }
}

=head2 sub df 


=cut

sub df {

    my ( $self, $df ) = @_;
    if ( defined $df
        && $df ne $empty_string )
    {

        $succwt->{_df}   = $df;
        $succwt->{_note} = $succwt->{_note} . ' df=' . $succwt->{_df};
        $succwt->{_Step} = $succwt->{_Step} . ' df=' . $succwt->{_df};

    }
    else {
        print("succwt, df, missing df,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( defined $dt
        && $dt ne $empty_string )
    {

        $succwt->{_dt}   = $dt;
        $succwt->{_note} = $succwt->{_note} . ' dt=' . $succwt->{_dt};
        $succwt->{_Step} = $succwt->{_Step} . ' dt=' . $succwt->{_dt};

    }
    else {
        print("succwt, dt, missing dt,\n");
    }
}

=head2 sub fmax 


=cut

sub fmax {

    my ( $self, $fmax ) = @_;
    if ( defined $fmax
        && $fmax ne $empty_string )
    {

        $succwt->{_fmax} = $fmax;
        $succwt->{_note} = $succwt->{_note} . ' fmax=' . $succwt->{_fmax};
        $succwt->{_Step} = $succwt->{_Step} . ' fmax=' . $succwt->{_fmax};

    }
    else {
        print("succwt, fmax, missing fmax,\n");
    }
}

=head2 sub fs 


=cut

sub fs {

    my ( $self, $fs ) = @_;
    if ( defined $fs
        && $fs ne $empty_string )
    {

        $succwt->{_fs}   = $fs;
        $succwt->{_note} = $succwt->{_note} . ' fs=' . $succwt->{_fs};
        $succwt->{_Step} = $succwt->{_Step} . ' fs=' . $succwt->{_fs};

    }
    else {
        print("succwt, fs, missing fs,\n");
    }
}

=head2 sub k 


=cut

sub k {

    my ( $self, $k ) = @_;
    if ( defined $k
        && $k ne $empty_string )
    {

        $succwt->{_k}    = $k;
        $succwt->{_note} = $succwt->{_note} . ' k=' . $succwt->{_k};
        $succwt->{_Step} = $succwt->{_Step} . ' k=' . $succwt->{_k};

    }
    else {
        print("succwt, k, missing k,\n");
    }
}

=head2 sub noct 


=cut

sub noct {

    my ( $self, $noct ) = @_;
    if ( defined $noct
        && $noct ne $empty_string )
    {

        $succwt->{_noct} = $noct;
        $succwt->{_note} = $succwt->{_note} . ' noct=' . $succwt->{_noct};
        $succwt->{_Step} = $succwt->{_Step} . ' noct=' . $succwt->{_noct};

    }
    else {
        print("succwt, noct, missing noct,\n");
    }
}

=head2 sub nscale 


=cut

sub nscale {

    my ( $self, $nscale ) = @_;
    if ( defined $nscale
        && $nscale ne $empty_string )
    {

        $succwt->{_nscale} = $nscale;
        $succwt->{_note}   = $succwt->{_note} . ' nscale=' . $succwt->{_nscale};
        $succwt->{_Step}   = $succwt->{_Step} . ' nscale=' . $succwt->{_nscale};

    }
    else {
        print("succwt, nscale, missing nscale,\n");
    }
}

=head2 sub ntr 


=cut

sub ntr {

    my ( $self, $ntr ) = @_;
    if ( defined $ntr
        && $ntr ne $empty_string )
    {

        $succwt->{_ntr}  = $ntr;
        $succwt->{_note} = $succwt->{_note} . ' ntr=' . $succwt->{_ntr};
        $succwt->{_Step} = $succwt->{_Step} . ' ntr=' . $succwt->{_ntr};

    }
    else {
        print("succwt, ntr, missing ntr,\n");
    }
}

=head2 sub nv 


=cut

sub nv {

    my ( $self, $nv ) = @_;
    if ( defined $nv
        && $nv ne $empty_string )
    {

        $succwt->{_nv}   = $nv;
        $succwt->{_note} = $succwt->{_note} . ' nv=' . $succwt->{_nv};
        $succwt->{_Step} = $succwt->{_Step} . ' nv=' . $succwt->{_nv};

    }
    else {
        print("succwt, nv, missing nv,\n");
    }
}

=head2 sub p 


=cut

sub p {

    my ( $self, $p ) = @_;
    if ( defined $p
        && $p ne $empty_string )
    {

        $succwt->{_p}    = $p;
        $succwt->{_note} = $succwt->{_note} . ' p=' . $succwt->{_p};
        $succwt->{_Step} = $succwt->{_Step} . ' p=' . $succwt->{_p};

    }
    else {
        print("succwt, p, missing p,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( defined $verbose
        && $verbose ne $empty_string )
    {

        $succwt->{_verbose} = $verbose;
        $succwt->{_note} =
          $succwt->{_note} . ' verbose=' . $succwt->{_verbose};
        $succwt->{_Step} =
          $succwt->{_Step} . ' verbose=' . $succwt->{_verbose};

    }
    else {
        print("succwt, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 11;

    return ($max_index);
}

1;
