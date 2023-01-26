package App::SeismicUnixGui::sunix::par::unisam;


=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  UNISAM - UNIformly SAMple a function y(x) specified as x,y pairs	
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 UNISAM - UNIformly SAMple a function y(x) specified as x,y pairs	

   unisam xin= yin= nout= [optional parameters] >binaryfile		
    ... or ...								
   unisam xfile= yfile= npairs= nout= [optional parameters] >binaryfile
    ... or ...								
   unisam xyfile= npairs= nout= [optional parameters] >binaryfile	

 Required Parameters:							
 xin=,,,	array of x values (number of xin = number of yin)	
 yin=,,,	array of y values (number of yin = number of xin)	
  ... or								
 xfile=	binary file of x values					
 yfile=	binary file of y values					
  ... or								
 xyfile=	binary file of x,y pairs				
 npairs=	number of pairs input (active only if xfile= and yfile=	
 		or xyfile= are set)					

 nout=		 number of y values output to binary file		

 Optional Parameters:							
 dxout=1.0	 output x sampling interval				
 fxout=0.0	 output first x						
 method=linear  =linear for linear interpolation (continuous y)	
		 =mono for monotonic cubic interpolation (continuous y')
		 =akima for Akima's cubic interpolation (continuous y') 
		 =spline for cubic spline interpolation (continuous y'')
 isint=,,,	 where these sine interpolations to apply		
 amp=,,,	 amplitude of sine interpolations			
 phase0=,,,	 starting phase (defaults: 0,0,0,...,0)			
 totalphase=,,, total phase (default pi,pi,pi,...,pi.)			
 nwidth=0       apply window smoothing if nwidth>0                     
 sloth=0	 apply interpolation in input (velocities)		
		 =1 apply interpolation to 1/input (slowness),		
 		 =2 apply interpolation to 1/input (sloth), and write	
 		 out velocities in each case.				
 smooth=0	 apply damped least squares smoothing to output		
 r=10		  ... damping coefficient, only active when smooth=1	


 AUTHOR:  Dave Hale, Colorado School of Mines, 07/07/89
          Zhaobo Meng, Colorado School of Mines, 
 	    added sine interpolation and window smoothing, 09/16/96 
          CWP: John Stockwell,  added file input options, 24 Nov 1997

 Remarks: In interpolation, suppose you need 2 pieces of 
 	    sine interpolation before index 3 to 4, and index 20 to 21
	    then set: isint=3,20. The sine interpolations use a sine
	    function with starting phase being phase0, total phase 
	    being totalphase (i.e. ending phase being phase0+totalphase
	    for each interpolation).
 	    

=head2 CHANGES and their DATES

=cut
 use Moose;
 our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

	my $get					= L_SU_global_constants->new();

	my $var				= $get->var();
	my $empty_string    	= $var->{_empty_string};


	my $unisam		= {
		_amp					=> '',
		_dxout					=> '',
		_fxout					=> '',
		_isint					=> '',
		_method					=> '',
		_nout					=> '',
		_npairs					=> '',
		_nwidth					=> '',
		_phase0					=> '',
		_r					=> '',
		_sloth					=> '',
		_smooth					=> '',
		_totalphase					=> '',
		_xfile					=> '',
		_xin					=> '',
		_xyfile					=> '',
		_yfile					=> '',
		_yin					=> '',
		_Step					=> '',
		_note					=> '',
    };


=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$unisam->{_Step}     = 'unisam'.$unisam->{_Step};
	return ( $unisam->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$unisam->{_note}     = 'unisam'.$unisam->{_note};
	return ( $unisam->{_note} );

 }


=head2 sub clear

=cut

 sub clear {

		$unisam->{_amp}			= '';
		$unisam->{_dxout}			= '';
		$unisam->{_fxout}			= '';
		$unisam->{_isint}			= '';
		$unisam->{_method}			= '';
		$unisam->{_nout}			= '';
		$unisam->{_npairs}			= '';
		$unisam->{_nwidth}			= '';
		$unisam->{_phase0}			= '';
		$unisam->{_r}			= '';
		$unisam->{_sloth}			= '';
		$unisam->{_smooth}			= '';
		$unisam->{_totalphase}			= '';
		$unisam->{_xfile}			= '';
		$unisam->{_xin}			= '';
		$unisam->{_xyfile}			= '';
		$unisam->{_yfile}			= '';
		$unisam->{_yin}			= '';
		$unisam->{_Step}			= '';
		$unisam->{_note}			= '';
 }


=head2 sub amp 


=cut

 sub amp {

	my ( $self,$amp )		= @_;
	if ( $amp ne $empty_string ) {

		$unisam->{_amp}		= $amp;
		$unisam->{_note}		= $unisam->{_note}.' amp='.$unisam->{_amp};
		$unisam->{_Step}		= $unisam->{_Step}.' amp='.$unisam->{_amp};

	} else { 
		print("unisam, amp, missing amp,\n");
	 }
 }


=head2 sub dxout 


=cut

 sub dxout {

	my ( $self,$dxout )		= @_;
	if ( $dxout ne $empty_string ) {

		$unisam->{_dxout}		= $dxout;
		$unisam->{_note}		= $unisam->{_note}.' dxout='.$unisam->{_dxout};
		$unisam->{_Step}		= $unisam->{_Step}.' dxout='.$unisam->{_dxout};

	} else { 
		print("unisam, dxout, missing dxout,\n");
	 }
 }


=head2 sub fxout 


=cut

 sub fxout {

	my ( $self,$fxout )		= @_;
	if ( $fxout ne $empty_string ) {

		$unisam->{_fxout}		= $fxout;
		$unisam->{_note}		= $unisam->{_note}.' fxout='.$unisam->{_fxout};
		$unisam->{_Step}		= $unisam->{_Step}.' fxout='.$unisam->{_fxout};

	} else { 
		print("unisam, fxout, missing fxout,\n");
	 }
 }


=head2 sub isint 


=cut

 sub isint {

	my ( $self,$isint )		= @_;
	if ( $isint ne $empty_string ) {

		$unisam->{_isint}		= $isint;
		$unisam->{_note}		= $unisam->{_note}.' isint='.$unisam->{_isint};
		$unisam->{_Step}		= $unisam->{_Step}.' isint='.$unisam->{_isint};

	} else { 
		print("unisam, isint, missing isint,\n");
	 }
 }


=head2 sub method 


=cut

 sub method {

	my ( $self,$method )		= @_;
	if ( $method ne $empty_string ) {

		$unisam->{_method}		= $method;
		$unisam->{_note}		= $unisam->{_note}.' method='.$unisam->{_method};
		$unisam->{_Step}		= $unisam->{_Step}.' method='.$unisam->{_method};

	} else { 
		print("unisam, method, missing method,\n");
	 }
 }


=head2 sub nout 


=cut

 sub nout {

	my ( $self,$nout )		= @_;
	if ( $nout ne $empty_string ) {

		$unisam->{_nout}		= $nout;
		$unisam->{_note}		= $unisam->{_note}.' nout='.$unisam->{_nout};
		$unisam->{_Step}		= $unisam->{_Step}.' nout='.$unisam->{_nout};

	} else { 
		print("unisam, nout, missing nout,\n");
	 }
 }


=head2 sub npairs 


=cut

 sub npairs {

	my ( $self,$npairs )		= @_;
	if ( $npairs ne $empty_string ) {

		$unisam->{_npairs}		= $npairs;
		$unisam->{_note}		= $unisam->{_note}.' npairs='.$unisam->{_npairs};
		$unisam->{_Step}		= $unisam->{_Step}.' npairs='.$unisam->{_npairs};

	} else { 
		print("unisam, npairs, missing npairs,\n");
	 }
 }


=head2 sub nwidth 


=cut

 sub nwidth {

	my ( $self,$nwidth )		= @_;
	if ( $nwidth ne $empty_string ) {

		$unisam->{_nwidth}		= $nwidth;
		$unisam->{_note}		= $unisam->{_note}.' nwidth='.$unisam->{_nwidth};
		$unisam->{_Step}		= $unisam->{_Step}.' nwidth='.$unisam->{_nwidth};

	} else { 
		print("unisam, nwidth, missing nwidth,\n");
	 }
 }


=head2 sub phase0 


=cut

 sub phase0 {

	my ( $self,$phase0 )		= @_;
	if ( $phase0 ne $empty_string ) {

		$unisam->{_phase0}		= $phase0;
		$unisam->{_note}		= $unisam->{_note}.' phase0='.$unisam->{_phase0};
		$unisam->{_Step}		= $unisam->{_Step}.' phase0='.$unisam->{_phase0};

	} else { 
		print("unisam, phase0, missing phase0,\n");
	 }
 }


=head2 sub r 


=cut

 sub r {

	my ( $self,$r )		= @_;
	if ( $r ne $empty_string ) {

		$unisam->{_r}		= $r;
		$unisam->{_note}		= $unisam->{_note}.' r='.$unisam->{_r};
		$unisam->{_Step}		= $unisam->{_Step}.' r='.$unisam->{_r};

	} else { 
		print("unisam, r, missing r,\n");
	 }
 }


=head2 sub sloth 


=cut

 sub sloth {

	my ( $self,$sloth )		= @_;
	if ( $sloth ne $empty_string ) {

		$unisam->{_sloth}		= $sloth;
		$unisam->{_note}		= $unisam->{_note}.' sloth='.$unisam->{_sloth};
		$unisam->{_Step}		= $unisam->{_Step}.' sloth='.$unisam->{_sloth};

	} else { 
		print("unisam, sloth, missing sloth,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$unisam->{_smooth}		= $smooth;
		$unisam->{_note}		= $unisam->{_note}.' smooth='.$unisam->{_smooth};
		$unisam->{_Step}		= $unisam->{_Step}.' smooth='.$unisam->{_smooth};

	} else { 
		print("unisam, smooth, missing smooth,\n");
	 }
 }


=head2 sub totalphase 


=cut

 sub totalphase {

	my ( $self,$totalphase )		= @_;
	if ( $totalphase ne $empty_string ) {

		$unisam->{_totalphase}		= $totalphase;
		$unisam->{_note}		= $unisam->{_note}.' totalphase='.$unisam->{_totalphase};
		$unisam->{_Step}		= $unisam->{_Step}.' totalphase='.$unisam->{_totalphase};

	} else { 
		print("unisam, totalphase, missing totalphase,\n");
	 }
 }


=head2 sub xfile 


=cut

 sub xfile {

	my ( $self,$xfile )		= @_;
	if ( $xfile ne $empty_string ) {

		$unisam->{_xfile}		= $xfile;
		$unisam->{_note}		= $unisam->{_note}.' xfile='.$unisam->{_xfile};
		$unisam->{_Step}		= $unisam->{_Step}.' xfile='.$unisam->{_xfile};

	} else { 
		print("unisam, xfile, missing xfile,\n");
	 }
 }


=head2 sub xin 


=cut

 sub xin {

	my ( $self,$xin )		= @_;
	if ( $xin ne $empty_string ) {

		$unisam->{_xin}		= $xin;
		$unisam->{_note}		= $unisam->{_note}.' xin='.$unisam->{_xin};
		$unisam->{_Step}		= $unisam->{_Step}.' xin='.$unisam->{_xin};

	} else { 
		print("unisam, xin, missing xin,\n");
	 }
 }


=head2 sub xyfile 


=cut

 sub xyfile {

	my ( $self,$xyfile )		= @_;
	if ( $xyfile ne $empty_string ) {

		$unisam->{_xyfile}		= $xyfile;
		$unisam->{_note}		= $unisam->{_note}.' xyfile='.$unisam->{_xyfile};
		$unisam->{_Step}		= $unisam->{_Step}.' xyfile='.$unisam->{_xyfile};

	} else { 
		print("unisam, xyfile, missing xyfile,\n");
	 }
 }


=head2 sub yfile 


=cut

 sub yfile {

	my ( $self,$yfile )		= @_;
	if ( $yfile ne $empty_string ) {

		$unisam->{_yfile}		= $yfile;
		$unisam->{_note}		= $unisam->{_note}.' yfile='.$unisam->{_yfile};
		$unisam->{_Step}		= $unisam->{_Step}.' yfile='.$unisam->{_yfile};

	} else { 
		print("unisam, yfile, missing yfile,\n");
	 }
 }


=head2 sub yin 


=cut

 sub yin {

	my ( $self,$yin )		= @_;
	if ( $yin ne $empty_string ) {

		$unisam->{_yin}		= $yin;
		$unisam->{_note}		= $unisam->{_note}.' yin='.$unisam->{_yin};
		$unisam->{_Step}		= $unisam->{_Step}.' yin='.$unisam->{_yin};

	} else { 
		print("unisam, yin, missing yin,\n");
	 }
 }


=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut
 
  sub get_max_index {
 	my ($self) = @_;
 	
 	my $max_index = 17;
	
 	return($max_index);
 }
 
 
1; 
