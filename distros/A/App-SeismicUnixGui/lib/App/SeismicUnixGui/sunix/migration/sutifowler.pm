package App::SeismicUnixGui::sunix::migration::sutifowler;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUTIFOWLER   VTI constant velocity prestack time migration		

	      velocity analysis via Fowler's method			



 sutifowler ncdps=250 vmin=1500 vmax=6000 dx=12.5			



 Required Parameter:							

 ncdps=		number of input cdp's				

 Optional Parameters:							

 choose=1	1 do full prestack time migration			

		2 do only DMO						

		3 do only post-stack migrations				

		4 do only stacking velocity analysis			

 getcvstacks=0	flag to set to 1 if inputting precomputed cvstacks	

		(vmin, nvstack, and ncdps must match SUCVS4FOWLER job)	

 vminstack=vmin	minimum velocity panel in m/s in input cvstacks	

 etamin=0.		minimum eta (see paper by Tariq Alkhalifah)	

 etamax=0.5	maximum eta (see paper by Tariq Alkhalifah)		

 neta=1	number of eta values to image				

 d=0.		Thomsen's delta						

 vpvs=0.5	assumed vp/vs ratio (not critical -- default almost always ok)

 dx=25.	cdp x increment						

 vmin=1500.	minimum velocity panel in m/s to output			

 vmax=8000.	maximum velocity panel in m/s to output			

 nv=75	 number of velocity panels to output				

 nvstack=180	number of stacking velocity panels to compute		

		     ( Let offmax be the maximum offset, fmax be	

		     the maximum freq to preserve, and tmute be		

		     the starting mute time in sec on offmax, then	

		     the recommended value for nvstack would be		

		     nvstack = 4 +(offmax*offmax*fmax)/(0.6*vmin*vmin*tmute)

		     ---you may want to make do with less---)		

 nxpad=0	  number of traces to padd for spatial fft		

		     Ideally nxpad = (0.5*tmax*vmax+0.5*offmax)/dx	

 lmute=24	 length of mute taper in ms				

 nonhyp=1	  1 if do mute at 2*offset/vmin to avoid non-hyperbolic 

				moveout, 0 otherwise			

 lbtaper=0	length of bottom taper in ms				

 lstaper=0	length of side taper in traces				

 dtout=1.5*dt	output sample rate in s,   note: typically		

				fmax=salias*0.5/dtout			

 mxfold=120	maximum number of offsets/input cmp			

 salias=0.8	fraction of output frequencies to force within sloth	

		     antialias limit.  This controls muting by offset of

		     the input data prior to computing the cv stacks	

		     for values of choose=1 or choose=2.		

 file=sutifowler	root name for temporary files			

 p=not		Enter a path name where to put temporary files.		

	  	specified  Can enter multiple times to use multiple disk

		systems.						

		     The default uses information from the .VND file	

		     in the current directory if it exists, or puts 	

		     unique temporary files in the current directory.	

 ngroup=20	Number of cmps per velocity analysis group.		

 printfile=stderr    The output file for printout from this program.	



 Required trace header words on input are ns, dt, cdp, offset.		

 On output, trace headers are rebuilt from scratch with		

 ns - number of samples						

 dt - sample rate in usec						

 cdp - the output cmp number (0 based)					

 offset - the output velocity						

 tracf	- the output velocity index (0 based)				

 fldr - index for velocity analysis group (0 based, groups of ngroup cdps)

 ep - central cmp for velocity analysis group				

 igc - index for choice of eta (0 based)				

 igi - eta*100								

 sx=gx	- x coordinate as icmp*dx					

 tracl=tracr -sequential trace count (1 based)				



 Note: Due to aliasing considerations, the small offset-to-depth	

 ratio assumption inherent in the TI DMO derivation, and the		

 poor stacking of some large-offset events associated with TI non-hyperbolic

 moveout, a fairly stiff initial mute is recommended for the		

 long offsets.  As a result, this method may not work well		

 where you have multiple reflections to remove via stacking.		



 Note: The temporary files can be split over multiple disks by building

 a .VND file in your working directory.  The .VND file is ascii text	

 with the first line giving the number of directories followed by	

 successive lines with one line per directory name.			



 Note: The output data order has primary key equal to cdp, secondary	

 key equal to eta, and tertiary key equal to velocity.			



 Credits:

	CWP: John Anderson (visitor to CSM from Mobil) Spring 1993





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

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $sutifowler			= {
	_choose					=> '',
	_d					=> '',
	_dtout					=> '',
	_dx					=> '',
	_etamax					=> '',
	_etamin					=> '',
	_file					=> '',
	_fmax					=> '',
	_getcvstacks					=> '',
	_lbtaper					=> '',
	_lmute					=> '',
	_lstaper					=> '',
	_mxfold					=> '',
	_ncdps					=> '',
	_neta					=> '',
	_ngroup					=> '',
	_nonhyp					=> '',
	_nv					=> '',
	_nvstack					=> '',
	_nxpad					=> '',
	_p					=> '',
	_printfile					=> '',
	_salias					=> '',
	_sx					=> '',
	_tracl					=> '',
	_vmax					=> '',
	_vmin					=> '',
	_vminstack					=> '',
	_vpvs					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sutifowler->{_Step}     = 'sutifowler'.$sutifowler->{_Step};
	return ( $sutifowler->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sutifowler->{_note}     = 'sutifowler'.$sutifowler->{_note};
	return ( $sutifowler->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sutifowler->{_choose}			= '';
		$sutifowler->{_d}			= '';
		$sutifowler->{_dtout}			= '';
		$sutifowler->{_dx}			= '';
		$sutifowler->{_etamax}			= '';
		$sutifowler->{_etamin}			= '';
		$sutifowler->{_file}			= '';
		$sutifowler->{_fmax}			= '';
		$sutifowler->{_getcvstacks}			= '';
		$sutifowler->{_lbtaper}			= '';
		$sutifowler->{_lmute}			= '';
		$sutifowler->{_lstaper}			= '';
		$sutifowler->{_mxfold}			= '';
		$sutifowler->{_ncdps}			= '';
		$sutifowler->{_neta}			= '';
		$sutifowler->{_ngroup}			= '';
		$sutifowler->{_nonhyp}			= '';
		$sutifowler->{_nv}			= '';
		$sutifowler->{_nvstack}			= '';
		$sutifowler->{_nxpad}			= '';
		$sutifowler->{_p}			= '';
		$sutifowler->{_printfile}			= '';
		$sutifowler->{_salias}			= '';
		$sutifowler->{_sx}			= '';
		$sutifowler->{_tracl}			= '';
		$sutifowler->{_vmax}			= '';
		$sutifowler->{_vmin}			= '';
		$sutifowler->{_vminstack}			= '';
		$sutifowler->{_vpvs}			= '';
		$sutifowler->{_Step}			= '';
		$sutifowler->{_note}			= '';
 }


=head2 sub choose 


=cut

 sub choose {

	my ( $self,$choose )		= @_;
	if ( $choose ne $empty_string ) {

		$sutifowler->{_choose}		= $choose;
		$sutifowler->{_note}		= $sutifowler->{_note}.' choose='.$sutifowler->{_choose};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' choose='.$sutifowler->{_choose};

	} else { 
		print("sutifowler, choose, missing choose,\n");
	 }
 }


=head2 sub d 


=cut

 sub d {

	my ( $self,$d )		= @_;
	if ( $d ne $empty_string ) {

		$sutifowler->{_d}		= $d;
		$sutifowler->{_note}		= $sutifowler->{_note}.' d='.$sutifowler->{_d};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' d='.$sutifowler->{_d};

	} else { 
		print("sutifowler, d, missing d,\n");
	 }
 }


=head2 sub dtout 


=cut

 sub dtout {

	my ( $self,$dtout )		= @_;
	if ( $dtout ne $empty_string ) {

		$sutifowler->{_dtout}		= $dtout;
		$sutifowler->{_note}		= $sutifowler->{_note}.' dtout='.$sutifowler->{_dtout};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' dtout='.$sutifowler->{_dtout};

	} else { 
		print("sutifowler, dtout, missing dtout,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sutifowler->{_dx}		= $dx;
		$sutifowler->{_note}		= $sutifowler->{_note}.' dx='.$sutifowler->{_dx};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' dx='.$sutifowler->{_dx};

	} else { 
		print("sutifowler, dx, missing dx,\n");
	 }
 }


=head2 sub etamax 


=cut

 sub etamax {

	my ( $self,$etamax )		= @_;
	if ( $etamax ne $empty_string ) {

		$sutifowler->{_etamax}		= $etamax;
		$sutifowler->{_note}		= $sutifowler->{_note}.' etamax='.$sutifowler->{_etamax};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' etamax='.$sutifowler->{_etamax};

	} else { 
		print("sutifowler, etamax, missing etamax,\n");
	 }
 }


=head2 sub etamin 


=cut

 sub etamin {

	my ( $self,$etamin )		= @_;
	if ( $etamin ne $empty_string ) {

		$sutifowler->{_etamin}		= $etamin;
		$sutifowler->{_note}		= $sutifowler->{_note}.' etamin='.$sutifowler->{_etamin};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' etamin='.$sutifowler->{_etamin};

	} else { 
		print("sutifowler, etamin, missing etamin,\n");
	 }
 }


=head2 sub file 


=cut

 sub file {

	my ( $self,$file )		= @_;
	if ( $file ne $empty_string ) {

		$sutifowler->{_file}		= $file;
		$sutifowler->{_note}		= $sutifowler->{_note}.' file='.$sutifowler->{_file};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' file='.$sutifowler->{_file};

	} else { 
		print("sutifowler, file, missing file,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sutifowler->{_fmax}		= $fmax;
		$sutifowler->{_note}		= $sutifowler->{_note}.' fmax='.$sutifowler->{_fmax};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' fmax='.$sutifowler->{_fmax};

	} else { 
		print("sutifowler, fmax, missing fmax,\n");
	 }
 }


=head2 sub getcvstacks 


=cut

 sub getcvstacks {

	my ( $self,$getcvstacks )		= @_;
	if ( $getcvstacks ne $empty_string ) {

		$sutifowler->{_getcvstacks}		= $getcvstacks;
		$sutifowler->{_note}		= $sutifowler->{_note}.' getcvstacks='.$sutifowler->{_getcvstacks};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' getcvstacks='.$sutifowler->{_getcvstacks};

	} else { 
		print("sutifowler, getcvstacks, missing getcvstacks,\n");
	 }
 }


=head2 sub lbtaper 


=cut

 sub lbtaper {

	my ( $self,$lbtaper )		= @_;
	if ( $lbtaper ne $empty_string ) {

		$sutifowler->{_lbtaper}		= $lbtaper;
		$sutifowler->{_note}		= $sutifowler->{_note}.' lbtaper='.$sutifowler->{_lbtaper};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' lbtaper='.$sutifowler->{_lbtaper};

	} else { 
		print("sutifowler, lbtaper, missing lbtaper,\n");
	 }
 }


=head2 sub lmute 


=cut

 sub lmute {

	my ( $self,$lmute )		= @_;
	if ( $lmute ne $empty_string ) {

		$sutifowler->{_lmute}		= $lmute;
		$sutifowler->{_note}		= $sutifowler->{_note}.' lmute='.$sutifowler->{_lmute};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' lmute='.$sutifowler->{_lmute};

	} else { 
		print("sutifowler, lmute, missing lmute,\n");
	 }
 }


=head2 sub lstaper 


=cut

 sub lstaper {

	my ( $self,$lstaper )		= @_;
	if ( $lstaper ne $empty_string ) {

		$sutifowler->{_lstaper}		= $lstaper;
		$sutifowler->{_note}		= $sutifowler->{_note}.' lstaper='.$sutifowler->{_lstaper};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' lstaper='.$sutifowler->{_lstaper};

	} else { 
		print("sutifowler, lstaper, missing lstaper,\n");
	 }
 }


=head2 sub mxfold 


=cut

 sub mxfold {

	my ( $self,$mxfold )		= @_;
	if ( $mxfold ne $empty_string ) {

		$sutifowler->{_mxfold}		= $mxfold;
		$sutifowler->{_note}		= $sutifowler->{_note}.' mxfold='.$sutifowler->{_mxfold};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' mxfold='.$sutifowler->{_mxfold};

	} else { 
		print("sutifowler, mxfold, missing mxfold,\n");
	 }
 }


=head2 sub ncdps 


=cut

 sub ncdps {

	my ( $self,$ncdps )		= @_;
	if ( $ncdps ne $empty_string ) {

		$sutifowler->{_ncdps}		= $ncdps;
		$sutifowler->{_note}		= $sutifowler->{_note}.' ncdps='.$sutifowler->{_ncdps};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' ncdps='.$sutifowler->{_ncdps};

	} else { 
		print("sutifowler, ncdps, missing ncdps,\n");
	 }
 }


=head2 sub neta 


=cut

 sub neta {

	my ( $self,$neta )		= @_;
	if ( $neta ne $empty_string ) {

		$sutifowler->{_neta}		= $neta;
		$sutifowler->{_note}		= $sutifowler->{_note}.' neta='.$sutifowler->{_neta};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' neta='.$sutifowler->{_neta};

	} else { 
		print("sutifowler, neta, missing neta,\n");
	 }
 }


=head2 sub ngroup 


=cut

 sub ngroup {

	my ( $self,$ngroup )		= @_;
	if ( $ngroup ne $empty_string ) {

		$sutifowler->{_ngroup}		= $ngroup;
		$sutifowler->{_note}		= $sutifowler->{_note}.' ngroup='.$sutifowler->{_ngroup};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' ngroup='.$sutifowler->{_ngroup};

	} else { 
		print("sutifowler, ngroup, missing ngroup,\n");
	 }
 }


=head2 sub nonhyp 


=cut

 sub nonhyp {

	my ( $self,$nonhyp )		= @_;
	if ( $nonhyp ne $empty_string ) {

		$sutifowler->{_nonhyp}		= $nonhyp;
		$sutifowler->{_note}		= $sutifowler->{_note}.' nonhyp='.$sutifowler->{_nonhyp};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' nonhyp='.$sutifowler->{_nonhyp};

	} else { 
		print("sutifowler, nonhyp, missing nonhyp,\n");
	 }
 }


=head2 sub nv 


=cut

 sub nv {

	my ( $self,$nv )		= @_;
	if ( $nv ne $empty_string ) {

		$sutifowler->{_nv}		= $nv;
		$sutifowler->{_note}		= $sutifowler->{_note}.' nv='.$sutifowler->{_nv};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' nv='.$sutifowler->{_nv};

	} else { 
		print("sutifowler, nv, missing nv,\n");
	 }
 }


=head2 sub nvstack 


=cut

 sub nvstack {

	my ( $self,$nvstack )		= @_;
	if ( $nvstack ne $empty_string ) {

		$sutifowler->{_nvstack}		= $nvstack;
		$sutifowler->{_note}		= $sutifowler->{_note}.' nvstack='.$sutifowler->{_nvstack};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' nvstack='.$sutifowler->{_nvstack};

	} else { 
		print("sutifowler, nvstack, missing nvstack,\n");
	 }
 }


=head2 sub nxpad 


=cut

 sub nxpad {

	my ( $self,$nxpad )		= @_;
	if ( $nxpad ne $empty_string ) {

		$sutifowler->{_nxpad}		= $nxpad;
		$sutifowler->{_note}		= $sutifowler->{_note}.' nxpad='.$sutifowler->{_nxpad};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' nxpad='.$sutifowler->{_nxpad};

	} else { 
		print("sutifowler, nxpad, missing nxpad,\n");
	 }
 }


=head2 sub p 


=cut

 sub p {

	my ( $self,$p )		= @_;
	if ( $p ne $empty_string ) {

		$sutifowler->{_p}		= $p;
		$sutifowler->{_note}		= $sutifowler->{_note}.' p='.$sutifowler->{_p};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' p='.$sutifowler->{_p};

	} else { 
		print("sutifowler, p, missing p,\n");
	 }
 }


=head2 sub printfile 


=cut

 sub printfile {

	my ( $self,$printfile )		= @_;
	if ( $printfile ne $empty_string ) {

		$sutifowler->{_printfile}		= $printfile;
		$sutifowler->{_note}		= $sutifowler->{_note}.' printfile='.$sutifowler->{_printfile};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' printfile='.$sutifowler->{_printfile};

	} else { 
		print("sutifowler, printfile, missing printfile,\n");
	 }
 }


=head2 sub salias 


=cut

 sub salias {

	my ( $self,$salias )		= @_;
	if ( $salias ne $empty_string ) {

		$sutifowler->{_salias}		= $salias;
		$sutifowler->{_note}		= $sutifowler->{_note}.' salias='.$sutifowler->{_salias};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' salias='.$sutifowler->{_salias};

	} else { 
		print("sutifowler, salias, missing salias,\n");
	 }
 }


=head2 sub sx 


=cut

 sub sx {

	my ( $self,$sx )		= @_;
	if ( $sx ne $empty_string ) {

		$sutifowler->{_sx}		= $sx;
		$sutifowler->{_note}		= $sutifowler->{_note}.' sx='.$sutifowler->{_sx};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' sx='.$sutifowler->{_sx};

	} else { 
		print("sutifowler, sx, missing sx,\n");
	 }
 }


=head2 sub tracl 


=cut

 sub tracl {

	my ( $self,$tracl )		= @_;
	if ( $tracl ne $empty_string ) {

		$sutifowler->{_tracl}		= $tracl;
		$sutifowler->{_note}		= $sutifowler->{_note}.' tracl='.$sutifowler->{_tracl};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' tracl='.$sutifowler->{_tracl};

	} else { 
		print("sutifowler, tracl, missing tracl,\n");
	 }
 }


=head2 sub vmax 


=cut

 sub vmax {

	my ( $self,$vmax )		= @_;
	if ( $vmax ne $empty_string ) {

		$sutifowler->{_vmax}		= $vmax;
		$sutifowler->{_note}		= $sutifowler->{_note}.' vmax='.$sutifowler->{_vmax};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' vmax='.$sutifowler->{_vmax};

	} else { 
		print("sutifowler, vmax, missing vmax,\n");
	 }
 }


=head2 sub vmin 


=cut

 sub vmin {

	my ( $self,$vmin )		= @_;
	if ( $vmin ne $empty_string ) {

		$sutifowler->{_vmin}		= $vmin;
		$sutifowler->{_note}		= $sutifowler->{_note}.' vmin='.$sutifowler->{_vmin};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' vmin='.$sutifowler->{_vmin};

	} else { 
		print("sutifowler, vmin, missing vmin,\n");
	 }
 }


=head2 sub vminstack 


=cut

 sub vminstack {

	my ( $self,$vminstack )		= @_;
	if ( $vminstack ne $empty_string ) {

		$sutifowler->{_vminstack}		= $vminstack;
		$sutifowler->{_note}		= $sutifowler->{_note}.' vminstack='.$sutifowler->{_vminstack};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' vminstack='.$sutifowler->{_vminstack};

	} else { 
		print("sutifowler, vminstack, missing vminstack,\n");
	 }
 }


=head2 sub vpvs 


=cut

 sub vpvs {

	my ( $self,$vpvs )		= @_;
	if ( $vpvs ne $empty_string ) {

		$sutifowler->{_vpvs}		= $vpvs;
		$sutifowler->{_note}		= $sutifowler->{_note}.' vpvs='.$sutifowler->{_vpvs};
		$sutifowler->{_Step}		= $sutifowler->{_Step}.' vpvs='.$sutifowler->{_vpvs};

	} else { 
		print("sutifowler, vpvs, missing vpvs,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 28;

    return($max_index);
}
 
 
1;
