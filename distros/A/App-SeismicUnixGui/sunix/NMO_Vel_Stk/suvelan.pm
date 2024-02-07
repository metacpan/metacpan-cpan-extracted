package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suvelan;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUVELAN - compute stacking velocity semblance for cdp gathers	
 	     
AUTHOR: Juan Lorenzo (Perl module only)
 
 DATE:   Dec 1 2013, Nov. 2, 2018, Chang Liu
 
 DESCRIPTION:
 
 Version: 

=head2 USE

=head3 NOTES

 Distances (and velocities) need to be scaled by the user
 a scaling factor is needed to match 
 scalel found in data headers
 suvelan DOES not take scaleco or scalel into consdieration
 automatically

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUVELAN - compute stacking velocity semblance for cdp gathers		     

 suvelan <stdin >stdout [optional parameters]				     

 Optional Parameters:							     
 nv=50                   number of velocities				     
 dv=50.0                 velocity sampling interval			     
 fv=1500.0               first velocity				     
 anis1=0.0               quartic term, numerator of an extended quartic term
 anis2=0.0               in denominator of an extended quartic term         
 smute=1.5               samples with NMO stretch exceeding smute are zeroed
 dtratio=5               ratio of output to input time sampling intervals   
 nsmooth=dtratio*2+1     length of semblance num and den smoothing window   
 verbose=0               =1 for diagnostic print on stderr		     
 pwr=1.0                 semblance value to the power      		     

 Notes:								     
 Velocity analysis is usually a two-dimensional screen for optimal values of
 the vertical two-way traveltime and stacking velocity. But if the travel-  
 time curve is no longer close to a hyperbola, the quartic term of the      
 traveltime series should be considered. In its easiest form (with anis2=0) 
 the optimizion of all parameters requires a three-dimensional screen. This 
 is done by a repetition of the conventional two-dimensional screen with a  
 though the function is no more a polynomial. When screening for optimal    
 values the theoretical dependencies between these paramters can be taken   
 into account. The traveltime function is defined by                        

                1            anis1                                          
 t^2 = t_0^2 + --- x^2 + ------------- x^4                                  
               v^2       1 + anis2 x^2                                      

 The coefficients anis1, anis2 are assumed to be small, that means the non- 
 hyperbolicity is assumed to be small. Triplications cannot be handled.     

 Semblance is defined by the following quotient:			     

                 n-1                 					     
               [ sum q(t,j) ]^2      					     
                 j=0                 					     
       s(t) = ------------------     					     
                 n-1                 					     
               n sum [q(t,j)]^2      					     
                 j=0                 					     

 where n is the number of non-zero samples after muting.		     
 Smoothing (nsmooth) is applied separately to the numerator and denominator 
 before computing this semblance quotient.				     

 Then, the semblance is set to the power of the parameter pwr. With pwr > 1 
 the difference between semblance values is stretched in the upper half of  
 the range of semblance values [0,1], but compressed in the lower half of   
 it; thus, the few large semblance values are enhanced. With pwr < 1 the    
 many small values are enhanced, thus more discernible against background   
 noise. Of course, always at the expense of the respective other feature.   

 Input traces should be sorted by cdp - suvelan outputs a group of	     
 semblance traces every time cdp changes.  Therefore, the output will	     
 be useful only if cdp gathers are input.				     

 Credits:
	CWP, Colorado School of Mines:
           Dave Hale (everything except ...)
           Bjoern Rommel (... the quartic term)
      SINTEF, IKU Petroleumsforskning
           Bjoern Rommel (... the power-of-semblance function)

 Trace header fields accessed:  ns, dt, delrt, offset, cdp
 Trace header fields modified:  ns, dt, offset, cdp

=head2 CHANGES and their DATES



=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suvelan = {
    _anis1   => '',
    _anis2   => '',
    _dtratio => '',
    _dv      => '',
    _fv      => '',
    _nsmooth => '',
    _nv      => '',
    _pwr     => '',
    _smute   => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suvelan->{_Step} = 'suvelan' . $suvelan->{_Step};
    return ( $suvelan->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suvelan->{_note} = 'suvelan' . $suvelan->{_note};
    return ( $suvelan->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suvelan->{_anis1}   = '';
    $suvelan->{_anis2}   = '';
    $suvelan->{_dtratio} = '';
    $suvelan->{_dv}      = '';
    $suvelan->{_fv}      = '';
    $suvelan->{_nsmooth} = '';
    $suvelan->{_nv}      = '';
    $suvelan->{_pwr}     = '';
    $suvelan->{_smute}   = '';
    $suvelan->{_verbose} = '';
    $suvelan->{_Step}    = '';
    $suvelan->{_note}    = '';
}

=head2 sub anis1 


=cut

sub anis1 {

    my ( $self, $anis1 ) = @_;
    if ( $anis1 ne $empty_string ) {

        $suvelan->{_anis1} = $anis1;
        $suvelan->{_note} =
          $suvelan->{_note} . ' anis1=' . $suvelan->{_anis1};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' anis1=' . $suvelan->{_anis1};

    }
    else {
        print("suvelan, anis1, missing anis1,\n");
    }
}

=head2 sub anis2 


=cut

sub anis2 {

    my ( $self, $anis2 ) = @_;
    if ( $anis2 ne $empty_string ) {

        $suvelan->{_anis2} = $anis2;
        $suvelan->{_note} =
          $suvelan->{_note} . ' anis2=' . $suvelan->{_anis2};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' anis2=' . $suvelan->{_anis2};

    }
    else {
        print("suvelan, anis2, missing anis2,\n");
    }
}

=head2 sub dtratio 


=cut

sub dtratio {

    my ( $self, $dtratio ) = @_;
    if ($dtratio) {

        $suvelan->{_dtratio} = $dtratio;
        $suvelan->{_note} =
          $suvelan->{_note} . ' dtratio=' . $suvelan->{_dtratio};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' dtratio=' . $suvelan->{_dtratio};

    }
    else {
        print("suvelan, dtratio, missing dtratio,\n");
    }
}

=head2 sub dv 

 defines the size of the velocity steps 
 to use in the semblance analysis

=cut

sub dv {

    my ( $self, $dv ) = @_;
    if ($dv) {

        $suvelan->{_dv}   = $dv;
        $suvelan->{_note} = $suvelan->{_note} . ' dv=' . $suvelan->{_dv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' dv=' . $suvelan->{_dv};

    }
    else {
        print("suvelan, dv, missing dv,\n");
    }
}

=head2 sub first_velocity

defines the first velocity value to use in the semblance analysis


=cut

sub first_velocity {

    my ( $self, $fv ) = @_;
    if ($fv) {

        $suvelan->{_fv}   = $fv;
        $suvelan->{_note} = $suvelan->{_note} . ' fv=' . $suvelan->{_fv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' fv=' . $suvelan->{_fv};

    }
    else {
        print("suvelan, first_velocity, missing first_velocity,\n");
    }
}

=head2 sub fv 

defines the first velocity value to use in the semblance analysis


=cut

sub fv {

    my ( $self, $fv ) = @_;
    if ($fv) {

        $suvelan->{_fv}   = $fv;
        $suvelan->{_note} = $suvelan->{_note} . ' fv=' . $suvelan->{_fv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' fv=' . $suvelan->{_fv};

    }
    else {
        print("suvelan, fv, missing fv,\n");
    }
}

=head2 sub nsmooth 


=cut

sub nsmooth {

    my ( $self, $nsmooth ) = @_;
    if ( $nsmooth ne $empty_string ) {

        $suvelan->{_nsmooth} = $nsmooth;
        $suvelan->{_note} =
          $suvelan->{_note} . ' nsmooth=' . $suvelan->{_nsmooth};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' nsmooth=' . $suvelan->{_nsmooth};

    }
    else {
        print("suvelan, nsmooth, missing nsmooth,\n");
    }
}

=head2 sub number_of_velocities

   sets the number of velocities

=cut

sub number_of_velocities {

    my ( $self, $nv ) = @_;
    if ($nv) {

        $suvelan->{_nv}   = $nv;
        $suvelan->{_note} = $suvelan->{_note} . ' nv=' . $suvelan->{_nv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' nv=' . $suvelan->{_nv};

    }
    else {
        print("suvelan, number_of_velocities missing number_of_velocities\n");
    }
}

=head2 sub nv

   sets the number of velocities

=cut

sub nv {

    my ( $self, $nv ) = @_;
    if ($nv) {

        $suvelan->{_nv}   = $nv;
        $suvelan->{_note} = $suvelan->{_note} . ' nv=' . $suvelan->{_nv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' nv=' . $suvelan->{_nv};

    }
    else {
        print("suvelan, nv, missing nv,\n");
    }
}

=head2 sub pwr 


=cut

sub pwr {

    my ( $self, $pwr ) = @_;
    if ($pwr) {

        $suvelan->{_pwr}  = $pwr;
        $suvelan->{_note} = $suvelan->{_note} . ' pwr=' . $suvelan->{_pwr};
        $suvelan->{_Step} = $suvelan->{_Step} . ' pwr=' . $suvelan->{_pwr};

    }
    else {
        print("suvelan, pwr, missing pwr,\n");
    }
}

=head2 sub smute 


=cut

sub smute {

    my ( $self, $smute ) = @_;
    if ($smute) {

        $suvelan->{_smute} = $smute;
        $suvelan->{_note} =
          $suvelan->{_note} . ' smute=' . $suvelan->{_smute};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' smute=' . $suvelan->{_smute};

    }
    else {
        print("suvelan, smute, missing smute,\n");
    }
}

=head2 sub velocity_incrementdv 

 defines the size of the velocity steps 
 to use in the semblance analysis

=cut

sub velocity_increment {

    my ( $self, $dv ) = @_;
    if ($dv) {

        $suvelan->{_dv}   = $dv;
        $suvelan->{_note} = $suvelan->{_note} . ' dv=' . $suvelan->{_dv};
        $suvelan->{_Step} = $suvelan->{_Step} . ' dv=' . $suvelan->{_dv};

    }
    else {
        print("suvelan, velocity_increment, missing velocity_increment,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $suvelan->{_verbose} = $verbose;
        $suvelan->{_note} =
          $suvelan->{_note} . ' verbose=' . $suvelan->{_verbose};
        $suvelan->{_Step} =
          $suvelan->{_Step} . ' verbose=' . $suvelan->{_verbose};

    }
    else {
        print("suvelan, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 9;

    return ($max_index);
}

1;
