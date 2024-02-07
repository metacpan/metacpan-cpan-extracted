package App::SeismicUnixGui::sunix::model::elamodel;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 ELAMODEL - make piecewise homogeneous anisotropic model    		



 elamodel >modelfile fill= [optional parameters]   			



 Input Parameters: 							

 xmin=0.0               minimum horizontal coordinate (x) 		

 xmax=1.0               maximum horizontal coordinate (x) 		

 zmin=0.0               minimum vertical coordinate (z) 		

 zmax=1.0               maximum vertical coordinate (z) 		

 xedge=                 x coordinates of an edge 			

 zedge=                 z coordinates of an edge 			

 kedge=                 array of indices used to identify edges 	

 fill=    iso      	 x,z,v_p,v_s,rho   				

          tiso      	 x,z,v_p,v_s,epsilon,delta,gamma,phi,rho	

          ani           x,z,a1111,a3333,a1133,a1313,a1113,a3313        

                            a1212,a2323,a1223,rho                      

 maxangle=5.0           maximum angle (deg) between adjacent edge segments 



 Notes: 								

 More than set of xedge and zedge parameters may be 		        

 specified, but the numbers of these parameters must be equal. 	



 Within each set, vertices will be connected by fixed edges. 		



 Edge indices in the k array are used to identify edges 		

 specified by the x and z parameters.  The first k index 		

 corresponds to the first set of x and z parameters, the 		

 second k index corresponds to the second set, and so on. 		



 After all vertices have been inserted into the model,	the fill        

 parameters is used to fill closed regions bounded by fixed edges.     

 Three input modes are available:                                      

 Isotropic blocks:     x,z,v_p,v_s,rho                                 

 Transversely iso:     x,z,v_p,v_s,epsilon,delta,gamma,phi,rho         

 General 2D aniso:     x,z,a1111,a3333,a1133,a1313,a1113,a3313         

                       a1212,a2323,a1223,rho                           

 Hereby:  

 x,z			   coordinates of one point in a bounded region 

 v_p,v_s		   P, S-wave velocity along symmetry axis       

 epsilon, delta, gammma   Thomsen's parameters              

 rho 			   density 			     

 phi			   angle of symmetry axes with vertical 

 aijkl			   density normalized stiffness coefficients 



 Each block can be defined by different input modes. The number of     

 input parameters defines the input type. Incorrect number of input    

 parameters result in an Error-message					









Author: Dave Hale, Colorado School of Mines, 02/12/91

 modified : Andreas Rueger, Colorado School of Mines, 01/18/94

 built anisotropic models





=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $elamodel			= {
	_fill					=> '',
	_kedge					=> '',
	_maxangle					=> '',
	_xedge					=> '',
	_xmax					=> '',
	_xmin					=> '',
	_zedge					=> '',
	_zmax					=> '',
	_zmin					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$elamodel->{_Step}     = 'elamodel'.$elamodel->{_Step};
	return ( $elamodel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$elamodel->{_note}     = 'elamodel'.$elamodel->{_note};
	return ( $elamodel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$elamodel->{_fill}			= '';
		$elamodel->{_kedge}			= '';
		$elamodel->{_maxangle}			= '';
		$elamodel->{_xedge}			= '';
		$elamodel->{_xmax}			= '';
		$elamodel->{_xmin}			= '';
		$elamodel->{_zedge}			= '';
		$elamodel->{_zmax}			= '';
		$elamodel->{_zmin}			= '';
		$elamodel->{_Step}			= '';
		$elamodel->{_note}			= '';
 }


=head2 sub fill 


=cut

 sub fill {

	my ( $self,$fill )		= @_;
	if ( $fill ne $empty_string ) {

		$elamodel->{_fill}		= $fill;
		$elamodel->{_note}		= $elamodel->{_note}.' fill='.$elamodel->{_fill};
		$elamodel->{_Step}		= $elamodel->{_Step}.' fill='.$elamodel->{_fill};

	} else { 
		print("elamodel, fill, missing fill,\n");
	 }
 }


=head2 sub kedge 


=cut

 sub kedge {

	my ( $self,$kedge )		= @_;
	if ( $kedge ne $empty_string ) {

		$elamodel->{_kedge}		= $kedge;
		$elamodel->{_note}		= $elamodel->{_note}.' kedge='.$elamodel->{_kedge};
		$elamodel->{_Step}		= $elamodel->{_Step}.' kedge='.$elamodel->{_kedge};

	} else { 
		print("elamodel, kedge, missing kedge,\n");
	 }
 }


=head2 sub maxangle 


=cut

 sub maxangle {

	my ( $self,$maxangle )		= @_;
	if ( $maxangle ne $empty_string ) {

		$elamodel->{_maxangle}		= $maxangle;
		$elamodel->{_note}		= $elamodel->{_note}.' maxangle='.$elamodel->{_maxangle};
		$elamodel->{_Step}		= $elamodel->{_Step}.' maxangle='.$elamodel->{_maxangle};

	} else { 
		print("elamodel, maxangle, missing maxangle,\n");
	 }
 }


=head2 sub xedge 


=cut

 sub xedge {

	my ( $self,$xedge )		= @_;
	if ( $xedge ne $empty_string ) {

		$elamodel->{_xedge}		= $xedge;
		$elamodel->{_note}		= $elamodel->{_note}.' xedge='.$elamodel->{_xedge};
		$elamodel->{_Step}		= $elamodel->{_Step}.' xedge='.$elamodel->{_xedge};

	} else { 
		print("elamodel, xedge, missing xedge,\n");
	 }
 }


=head2 sub xmax 


=cut

 sub xmax {

	my ( $self,$xmax )		= @_;
	if ( $xmax ne $empty_string ) {

		$elamodel->{_xmax}		= $xmax;
		$elamodel->{_note}		= $elamodel->{_note}.' xmax='.$elamodel->{_xmax};
		$elamodel->{_Step}		= $elamodel->{_Step}.' xmax='.$elamodel->{_xmax};

	} else { 
		print("elamodel, xmax, missing xmax,\n");
	 }
 }


=head2 sub xmin 


=cut

 sub xmin {

	my ( $self,$xmin )		= @_;
	if ( $xmin ne $empty_string ) {

		$elamodel->{_xmin}		= $xmin;
		$elamodel->{_note}		= $elamodel->{_note}.' xmin='.$elamodel->{_xmin};
		$elamodel->{_Step}		= $elamodel->{_Step}.' xmin='.$elamodel->{_xmin};

	} else { 
		print("elamodel, xmin, missing xmin,\n");
	 }
 }


=head2 sub zedge 


=cut

 sub zedge {

	my ( $self,$zedge )		= @_;
	if ( $zedge ne $empty_string ) {

		$elamodel->{_zedge}		= $zedge;
		$elamodel->{_note}		= $elamodel->{_note}.' zedge='.$elamodel->{_zedge};
		$elamodel->{_Step}		= $elamodel->{_Step}.' zedge='.$elamodel->{_zedge};

	} else { 
		print("elamodel, zedge, missing zedge,\n");
	 }
 }


=head2 sub zmax 


=cut

 sub zmax {

	my ( $self,$zmax )		= @_;
	if ( $zmax ne $empty_string ) {

		$elamodel->{_zmax}		= $zmax;
		$elamodel->{_note}		= $elamodel->{_note}.' zmax='.$elamodel->{_zmax};
		$elamodel->{_Step}		= $elamodel->{_Step}.' zmax='.$elamodel->{_zmax};

	} else { 
		print("elamodel, zmax, missing zmax,\n");
	 }
 }


=head2 sub zmin 


=cut

 sub zmin {

	my ( $self,$zmin )		= @_;
	if ( $zmin ne $empty_string ) {

		$elamodel->{_zmin}		= $zmin;
		$elamodel->{_note}		= $elamodel->{_note}.' zmin='.$elamodel->{_zmin};
		$elamodel->{_Step}		= $elamodel->{_Step}.' zmin='.$elamodel->{_zmin};

	} else { 
		print("elamodel, zmin, missing zmin,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
