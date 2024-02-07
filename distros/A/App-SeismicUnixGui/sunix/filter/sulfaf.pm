package App::SeismicUnixGui::sunix::filter::sulfaf;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SULFAF -  Low frequency array forming					", 



  sulfaf < stdin > stdout [optional parameters]			



 Optional Parameters:	  						

 key=ep	header keyword describing the gathers			

 f1=3		lower frequency	cutof					

 f2=20		high frequency cutof					

 fr=5		frequency ramp						



 vel=1000	surface wave velocity					

 dx=10		trace spacing						

 maxmix=tr.ntr	default is the entire gather				

 adb=1.0	add back ratio 1.0=pure filtered 0.0=origibal		



 tri=0		1 Triangular weight in mixing window			



 Notes:		  						

 The traces transformed into the freqiency domain			

 where a trace mix is performed in the specifed frequency range	

 as Mix=vel/(freq*dx)							



 This program uses "get_gather" and "put_gather" so requires that  

 the  data be sorted into ensembles designated by "key", with the ntr

 field set to the number of traces in each respective ensemble.	



 Example:								 

 susort ep offset < data.su > datasorted.su				

 suputgthr dir=Data verbose=1 < datasorted.su			  

 sugetgthr dir=Data verbose=1 > dataupdated.su			 

 sulfaf  < dataupdated.su > ccfiltdata.su				



 (Work in progress, editing required)                 			



define LOOKFAC 1	/* Look ahead factor for npfaro

define PFA_MAX 720720  /* Largest allowed nfft		*/

define PIP2 PI/2.0	/* IP/2				*/



int 

main( int argc, char *argv[] )

{

	cwp_String key;		/* header key word from segy.h		*/

	cwp_String type;	/* ... its type				*/

	Value val;		/* ... its value			*/

	segy **rec_o;		/* trace header+data matrix		*/

	int first=0;		/* true when we passed the first gather

	int ng=0;

	float dt;		/* time sampling interval	*/

	int nt;			/* num time samples per trace	*/

	int ntr;		/* num of traces per ensemble	*/

	

	int nfft=0;		/* lenghth of padded array	*/

	float snfft;		/* scale factor for inverse fft

	int nf=0;		/* number of frequencies	*/

	float d1;		/* frequency sampling interval.	*/

	float *rt=NULL;		/* real trace			*/

	complex *ct=NULL;	/* complex trace		*/

	float **ffdr=NULL;	/* frequency domain data	*/

	float **ffdi=NULL;	/* frequency domain data	*/

	float **ffdrm=NULL;	/* frequency domain mixed data	*/

	float **ffdim=NULL;	/* frequency domain mixed data	*/

	

	int verbose;		/* flag: =0 silent; =1 chatty	*/

	

	

	float f1;		/* minimum frequency		*/

	int if1;		/* ...    ...  integerized	*/

	float f2;		/* maximum frequency		*/

	int if2;		/* ...    ...  integerized	*/

	float fr;		/* slope of frequency ramp	*/

	int ifr;		/* ...    ...  integerized	*/

	float vel;		/* velocity of guided waves	*/

	float dx;		/* spatial sampling intervall	*/

	int maxmix;		/* size of mix			*/

	int tri;		/* flag: =1 trianglular window	*/

	float adb;		/* add back ratio		*/

		

	/* Initialize

	initargs(argc, argv);

	requestdoc(1);

	

	if (!getparstring("key", &key))		key = "ep";

	if (!getparfloat("f1", &f1))		f1 = 3.0;

	if (!getparfloat("f2", &f2))		f2 = 20.0;

	if (!getparfloat("dx", &dx))		dx = 10;

	if (!getparfloat("vel", &vel))		vel = 1000;

	if (!getparfloat("fr", &fr))		fr = 5;

	if (!getparint("maxmix", &maxmix))	maxmix = -1;

	if (!getparint("tri", &tri))		tri = 0;

	if (!getparfloat("adb", &adb))		adb = 1.0;

	

	if (!getparint("verbose", &verbose)) verbose = 0;



	/* get the first record

	rec_o = get_gather(&key,&type,&val,&nt,&ntr,&dt,&first);

	if(ntr==0) err("Can't get first record\n");

		

	/* set up the fft

	nfft = npfaro(nt, LOOKFAC * nt);

	 if (nfft >= SU_NFLTS || nfft >= PFA_MAX)

		 	err("Padded nt=0--too big", nfft);

	 nf = nfft/2 + 1;

	 snfft=1.0/nfft;

	d1=1.0/(nfft*dt);

	

	ct=ealloc1complex(nf);

	rt=ealloc1float(nfft);

	

	if1=NINT(f1/d1);

	if2=NINT(f2/d1);

	ifr=NINT(fr/d1);

	

	do {

		if(maxmix==-1) maxmix=ntr;

		ng++;

		

		/* Allocate arrays for fft

		ffdr = ealloc2float(nf,ntr);

		ffdi = ealloc2float(nf,ntr);

		ffdrm = ealloc2float(if2+ifr,ntr);

		ffdim = ealloc2float(if2+ifr,ntr);

		{ int itr,iw;

			for(itr=0;itr<ntr;itr++) {

				

				memcpy( (void *) rt, (const void *) (*rec_o[itr]).data, nt*FSIZE);



				memset( (void *) &rt[nt], 0,(nfft-nt)*FSIZE);

				

				pfarc(1,nfft,rt,ct);

				

				for(iw=0;iw<nf;iw++) {

					ffdr[itr][iw] = ct[iw].r;

					ffdi[itr][iw] = ct[iw].i;

				}

			}

		}

		

		/* Mixing

		{ int mix,iw,nmix;

		  int ims,ime;

		  int itr,itrm,iww,ws;

		  float tmpr,tmpi,wh;

		

			for(iw=if1;iw<if2+ifr;iw++) {

				

				mix=MIN(NINT(vel/iw*d1*dx),maxmix);

				if(!ISODD(mix)) mix -=1;

				if (verbose) warn(" 0.000000 0",iw*d1,mix);

				

				for(itr=0;itr<ntr;itr++) {

						

					ims=MAX(itr-mix/2,0);

					ime=MIN(ims+mix,ntr-1);



					tmpr=0.0; tmpi=0.0;

					wh=1.0; ws=mix/2;

					nmix=0;

					for(itrm=ims,iww=-mix/2;itrm<ime;++itrm,++iww) {

						++nmix;

						if(tri) wh = (float)(ws-abs(iww));

						tmpr+=ffdr[itrm][iw]*wh;

						tmpi+=ffdi[itrm][iw]*wh;

					}

					ffdrm[itr][iw]=tmpr/nmix;

					ffdim[itr][iw]=tmpi/nmix;

				}

			}

			

			for(iw=if1;iw<if2;iw++) {

				for(itr=0;itr<ntr;itr++) {

					ffdr[itr][iw]=ffdrm[itr][iw]*adb+ffdr[itr][iw]*(1.0-adb);

					ffdi[itr][iw]=ffdim[itr][iw]*adb+ffdi[itr][iw]*(1.0-adb);

				}

			}

			

			for(iw=if2,iww=0;iw<if2+ifr;iw++,iww++) {

				

				wh=(float)(1.0-(float)iww/(float)ifr);

				

				for(itr=0;itr<ntr;itr++) {

					ffdr[itr][iw] = (wh*ffdrm[itr][iw]+ffdr[itr][iw]*(1.0-wh))*adb+ffdr[itr][iw]*(1.0-adb);

					ffdi[itr][iw] = (wh*ffdim[itr][iw]+ffdi[itr][iw]*(1.0-wh))*adb+ffdi[itr][iw]*(1.0-adb);

				}

			}

		

		}

		  

		

		{ int itr,iw;

			for(itr=0;itr<ntr;itr++) {

				

				for(iw=0;iw<nf;iw++) {

					ct[iw].r = ffdr[itr][iw]*snfft;

					ct[iw].i = ffdi[itr][iw]*snfft;

				} 

				

				pfacr(-1,nfft,ct,rt);

				memcpy( (void *) (*rec_o[itr]).data, (const void *) rt, nt*FSIZE);

				

			}

		}

		

			rec_o = put_gather(rec_o,&nt,&ntr);



		free2float(ffdr);

		free2float(ffdi);

		free2float(ffdrm);

		free2float(ffdim);

		rec_o = get_gather(&key,&type,&val,&nt,&ntr,&dt,&first);

		

	} while(ntr);



	warn("Number of gathers          0\n",ng);

	 

	return EXIT_SUCCESS;

}



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

my $sulfaf			= {
	_adb					=> '',
	_ct					=> '',
	_d1					=> '',
	_dir					=> '',
	_dx					=> '',
	_f1					=> '',
	_f2					=> '',
	_ffdi					=> '',
	_ffdim					=> '',
	_ffdr					=> '',
	_ffdrm					=> '',
	_first					=> '',
	_fr					=> '',
	_i					=> '',
	_if1					=> '',
	_if2					=> '',
	_ifr					=> '',
	_ime					=> '',
	_ims					=> '',
	_itr					=> '',
	_itrm					=> '',
	_iw					=> '',
	_key					=> '',
	_maxmix					=> '',
	_mix					=> '',
	_nf					=> '',
	_nfft					=> '',
	_ng					=> '',
	_nmix					=> '',
	_nt					=> '',
	_ntr					=> '',
	_r					=> '',
	_rec_o					=> '',
	_rt					=> '',
	_snfft					=> '',
	_tmpr					=> '',
	_tri					=> '',
	_vel					=> '',
	_verbose					=> '',
	_wh					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sulfaf->{_Step}     = 'sulfaf'.$sulfaf->{_Step};
	return ( $sulfaf->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sulfaf->{_note}     = 'sulfaf'.$sulfaf->{_note};
	return ( $sulfaf->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sulfaf->{_adb}			= '';
		$sulfaf->{_ct}			= '';
		$sulfaf->{_d1}			= '';
		$sulfaf->{_dir}			= '';
		$sulfaf->{_dx}			= '';
		$sulfaf->{_f1}			= '';
		$sulfaf->{_f2}			= '';
		$sulfaf->{_ffdi}			= '';
		$sulfaf->{_ffdim}			= '';
		$sulfaf->{_ffdr}			= '';
		$sulfaf->{_ffdrm}			= '';
		$sulfaf->{_first}			= '';
		$sulfaf->{_fr}			= '';
		$sulfaf->{_i}			= '';
		$sulfaf->{_if1}			= '';
		$sulfaf->{_if2}			= '';
		$sulfaf->{_ifr}			= '';
		$sulfaf->{_ime}			= '';
		$sulfaf->{_ims}			= '';
		$sulfaf->{_itr}			= '';
		$sulfaf->{_itrm}			= '';
		$sulfaf->{_iw}			= '';
		$sulfaf->{_key}			= '';
		$sulfaf->{_maxmix}			= '';
		$sulfaf->{_mix}			= '';
		$sulfaf->{_nf}			= '';
		$sulfaf->{_nfft}			= '';
		$sulfaf->{_ng}			= '';
		$sulfaf->{_nmix}			= '';
		$sulfaf->{_nt}			= '';
		$sulfaf->{_ntr}			= '';
		$sulfaf->{_r}			= '';
		$sulfaf->{_rec_o}			= '';
		$sulfaf->{_rt}			= '';
		$sulfaf->{_snfft}			= '';
		$sulfaf->{_tmpr}			= '';
		$sulfaf->{_tri}			= '';
		$sulfaf->{_vel}			= '';
		$sulfaf->{_verbose}			= '';
		$sulfaf->{_wh}			= '';
		$sulfaf->{_Step}			= '';
		$sulfaf->{_note}			= '';
 }



=head2 sub adb 


=cut

 sub adb {

	my ( $self,$adb )		= @_;
	if ( $adb ne $empty_string ) {

		$sulfaf->{_adb}		= $adb;
		$sulfaf->{_note}		= $sulfaf->{_note}.' adb='.$sulfaf->{_adb};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' adb='.$sulfaf->{_adb};

	} else { 
		print("sulfaf, adb, missing adb,\n");
	 }
 }


=head2 sub ct 


=cut

 sub ct {

	my ( $self,$ct )		= @_;
	if ( $ct ne $empty_string ) {

		$sulfaf->{_ct}		= $ct;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ct='.$sulfaf->{_ct};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ct='.$sulfaf->{_ct};

	} else { 
		print("sulfaf, ct, missing ct,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$sulfaf->{_d1}		= $d1;
		$sulfaf->{_note}		= $sulfaf->{_note}.' d1='.$sulfaf->{_d1};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' d1='.$sulfaf->{_d1};

	} else { 
		print("sulfaf, d1, missing d1,\n");
	 }
 }


=head2 sub dir 


=cut

 sub dir {

	my ( $self,$dir )		= @_;
	if ( $dir ne $empty_string ) {

		$sulfaf->{_dir}		= $dir;
		$sulfaf->{_note}		= $sulfaf->{_note}.' dir='.$sulfaf->{_dir};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' dir='.$sulfaf->{_dir};

	} else { 
		print("sulfaf, dir, missing dir,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sulfaf->{_dx}		= $dx;
		$sulfaf->{_note}		= $sulfaf->{_note}.' dx='.$sulfaf->{_dx};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' dx='.$sulfaf->{_dx};

	} else { 
		print("sulfaf, dx, missing dx,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$sulfaf->{_f1}		= $f1;
		$sulfaf->{_note}		= $sulfaf->{_note}.' f1='.$sulfaf->{_f1};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' f1='.$sulfaf->{_f1};

	} else { 
		print("sulfaf, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$sulfaf->{_f2}		= $f2;
		$sulfaf->{_note}		= $sulfaf->{_note}.' f2='.$sulfaf->{_f2};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' f2='.$sulfaf->{_f2};

	} else { 
		print("sulfaf, f2, missing f2,\n");
	 }
 }


=head2 sub ffdi 


=cut

 sub ffdi {

	my ( $self,$ffdi )		= @_;
	if ( $ffdi ne $empty_string ) {

		$sulfaf->{_ffdi}		= $ffdi;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ffdi='.$sulfaf->{_ffdi};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ffdi='.$sulfaf->{_ffdi};

	} else { 
		print("sulfaf, ffdi, missing ffdi,\n");
	 }
 }


=head2 sub ffdim 


=cut

 sub ffdim {

	my ( $self,$ffdim )		= @_;
	if ( $ffdim ne $empty_string ) {

		$sulfaf->{_ffdim}		= $ffdim;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ffdim='.$sulfaf->{_ffdim};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ffdim='.$sulfaf->{_ffdim};

	} else { 
		print("sulfaf, ffdim, missing ffdim,\n");
	 }
 }


=head2 sub ffdr 


=cut

 sub ffdr {

	my ( $self,$ffdr )		= @_;
	if ( $ffdr ne $empty_string ) {

		$sulfaf->{_ffdr}		= $ffdr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ffdr='.$sulfaf->{_ffdr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ffdr='.$sulfaf->{_ffdr};

	} else { 
		print("sulfaf, ffdr, missing ffdr,\n");
	 }
 }


=head2 sub ffdrm 


=cut

 sub ffdrm {

	my ( $self,$ffdrm )		= @_;
	if ( $ffdrm ne $empty_string ) {

		$sulfaf->{_ffdrm}		= $ffdrm;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ffdrm='.$sulfaf->{_ffdrm};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ffdrm='.$sulfaf->{_ffdrm};

	} else { 
		print("sulfaf, ffdrm, missing ffdrm,\n");
	 }
 }


=head2 sub first 


=cut

 sub first {

	my ( $self,$first )		= @_;
	if ( $first ne $empty_string ) {

		$sulfaf->{_first}		= $first;
		$sulfaf->{_note}		= $sulfaf->{_note}.' first='.$sulfaf->{_first};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' first='.$sulfaf->{_first};

	} else { 
		print("sulfaf, first, missing first,\n");
	 }
 }


=head2 sub fr 


=cut

 sub fr {

	my ( $self,$fr )		= @_;
	if ( $fr ne $empty_string ) {

		$sulfaf->{_fr}		= $fr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' fr='.$sulfaf->{_fr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' fr='.$sulfaf->{_fr};

	} else { 
		print("sulfaf, fr, missing fr,\n");
	 }
 }


=head2 sub i 


=cut

 sub i {

	my ( $self,$i )		= @_;
	if ( $i ne $empty_string ) {

		$sulfaf->{_i}		= $i;
		$sulfaf->{_note}		= $sulfaf->{_note}.' i='.$sulfaf->{_i};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' i='.$sulfaf->{_i};

	} else { 
		print("sulfaf, i, missing i,\n");
	 }
 }


=head2 sub if1 


=cut

 sub if1 {

	my ( $self,$if1 )		= @_;
	if ( $if1 ne $empty_string ) {

		$sulfaf->{_if1}		= $if1;
		$sulfaf->{_note}		= $sulfaf->{_note}.' if1='.$sulfaf->{_if1};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' if1='.$sulfaf->{_if1};

	} else { 
		print("sulfaf, if1, missing if1,\n");
	 }
 }


=head2 sub if2 


=cut

 sub if2 {

	my ( $self,$if2 )		= @_;
	if ( $if2 ne $empty_string ) {

		$sulfaf->{_if2}		= $if2;
		$sulfaf->{_note}		= $sulfaf->{_note}.' if2='.$sulfaf->{_if2};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' if2='.$sulfaf->{_if2};

	} else { 
		print("sulfaf, if2, missing if2,\n");
	 }
 }


=head2 sub ifr 


=cut

 sub ifr {

	my ( $self,$ifr )		= @_;
	if ( $ifr ne $empty_string ) {

		$sulfaf->{_ifr}		= $ifr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ifr='.$sulfaf->{_ifr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ifr='.$sulfaf->{_ifr};

	} else { 
		print("sulfaf, ifr, missing ifr,\n");
	 }
 }


=head2 sub ime 


=cut

 sub ime {

	my ( $self,$ime )		= @_;
	if ( $ime ne $empty_string ) {

		$sulfaf->{_ime}		= $ime;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ime='.$sulfaf->{_ime};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ime='.$sulfaf->{_ime};

	} else { 
		print("sulfaf, ime, missing ime,\n");
	 }
 }


=head2 sub ims 


=cut

 sub ims {

	my ( $self,$ims )		= @_;
	if ( $ims ne $empty_string ) {

		$sulfaf->{_ims}		= $ims;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ims='.$sulfaf->{_ims};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ims='.$sulfaf->{_ims};

	} else { 
		print("sulfaf, ims, missing ims,\n");
	 }
 }


=head2 sub itr 


=cut

 sub itr {

	my ( $self,$itr )		= @_;
	if ( $itr ne $empty_string ) {

		$sulfaf->{_itr}		= $itr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' itr='.$sulfaf->{_itr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' itr='.$sulfaf->{_itr};

	} else { 
		print("sulfaf, itr, missing itr,\n");
	 }
 }


=head2 sub itrm 


=cut

 sub itrm {

	my ( $self,$itrm )		= @_;
	if ( $itrm ne $empty_string ) {

		$sulfaf->{_itrm}		= $itrm;
		$sulfaf->{_note}		= $sulfaf->{_note}.' itrm='.$sulfaf->{_itrm};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' itrm='.$sulfaf->{_itrm};

	} else { 
		print("sulfaf, itrm, missing itrm,\n");
	 }
 }


=head2 sub iw 


=cut

 sub iw {

	my ( $self,$iw )		= @_;
	if ( $iw ne $empty_string ) {

		$sulfaf->{_iw}		= $iw;
		$sulfaf->{_note}		= $sulfaf->{_note}.' iw='.$sulfaf->{_iw};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' iw='.$sulfaf->{_iw};

	} else { 
		print("sulfaf, iw, missing iw,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sulfaf->{_key}		= $key;
		$sulfaf->{_note}		= $sulfaf->{_note}.' key='.$sulfaf->{_key};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' key='.$sulfaf->{_key};

	} else { 
		print("sulfaf, key, missing key,\n");
	 }
 }


=head2 sub maxmix 


=cut

 sub maxmix {

	my ( $self,$maxmix )		= @_;
	if ( $maxmix ne $empty_string ) {

		$sulfaf->{_maxmix}		= $maxmix;
		$sulfaf->{_note}		= $sulfaf->{_note}.' maxmix='.$sulfaf->{_maxmix};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' maxmix='.$sulfaf->{_maxmix};

	} else { 
		print("sulfaf, maxmix, missing maxmix,\n");
	 }
 }


=head2 sub mix 


=cut

 sub mix {

	my ( $self,$mix )		= @_;
	if ( $mix ne $empty_string ) {

		$sulfaf->{_mix}		= $mix;
		$sulfaf->{_note}		= $sulfaf->{_note}.' mix='.$sulfaf->{_mix};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' mix='.$sulfaf->{_mix};

	} else { 
		print("sulfaf, mix, missing mix,\n");
	 }
 }


=head2 sub nf 


=cut

 sub nf {

	my ( $self,$nf )		= @_;
	if ( $nf ne $empty_string ) {

		$sulfaf->{_nf}		= $nf;
		$sulfaf->{_note}		= $sulfaf->{_note}.' nf='.$sulfaf->{_nf};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' nf='.$sulfaf->{_nf};

	} else { 
		print("sulfaf, nf, missing nf,\n");
	 }
 }


=head2 sub nfft 


=cut

 sub nfft {

	my ( $self,$nfft )		= @_;
	if ( $nfft ne $empty_string ) {

		$sulfaf->{_nfft}		= $nfft;
		$sulfaf->{_note}		= $sulfaf->{_note}.' nfft='.$sulfaf->{_nfft};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' nfft='.$sulfaf->{_nfft};

	} else { 
		print("sulfaf, nfft, missing nfft,\n");
	 }
 }


=head2 sub ng 


=cut

 sub ng {

	my ( $self,$ng )		= @_;
	if ( $ng ne $empty_string ) {

		$sulfaf->{_ng}		= $ng;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ng='.$sulfaf->{_ng};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ng='.$sulfaf->{_ng};

	} else { 
		print("sulfaf, ng, missing ng,\n");
	 }
 }


=head2 sub nmix 


=cut

 sub nmix {

	my ( $self,$nmix )		= @_;
	if ( $nmix ne $empty_string ) {

		$sulfaf->{_nmix}		= $nmix;
		$sulfaf->{_note}		= $sulfaf->{_note}.' nmix='.$sulfaf->{_nmix};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' nmix='.$sulfaf->{_nmix};

	} else { 
		print("sulfaf, nmix, missing nmix,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sulfaf->{_nt}		= $nt;
		$sulfaf->{_note}		= $sulfaf->{_note}.' nt='.$sulfaf->{_nt};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' nt='.$sulfaf->{_nt};

	} else { 
		print("sulfaf, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$sulfaf->{_ntr}		= $ntr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' ntr='.$sulfaf->{_ntr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' ntr='.$sulfaf->{_ntr};

	} else { 
		print("sulfaf, ntr, missing ntr,\n");
	 }
 }


=head2 sub r 


=cut

 sub r {

	my ( $self,$r )		= @_;
	if ( $r ne $empty_string ) {

		$sulfaf->{_r}		= $r;
		$sulfaf->{_note}		= $sulfaf->{_note}.' r='.$sulfaf->{_r};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' r='.$sulfaf->{_r};

	} else { 
		print("sulfaf, r, missing r,\n");
	 }
 }


=head2 sub rec_o 


=cut

 sub rec_o {

	my ( $self,$rec_o )		= @_;
	if ( $rec_o ne $empty_string ) {

		$sulfaf->{_rec_o}		= $rec_o;
		$sulfaf->{_note}		= $sulfaf->{_note}.' rec_o='.$sulfaf->{_rec_o};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' rec_o='.$sulfaf->{_rec_o};

	} else { 
		print("sulfaf, rec_o, missing rec_o,\n");
	 }
 }


=head2 sub rt 


=cut

 sub rt {

	my ( $self,$rt )		= @_;
	if ( $rt ne $empty_string ) {

		$sulfaf->{_rt}		= $rt;
		$sulfaf->{_note}		= $sulfaf->{_note}.' rt='.$sulfaf->{_rt};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' rt='.$sulfaf->{_rt};

	} else { 
		print("sulfaf, rt, missing rt,\n");
	 }
 }


=head2 sub snfft 


=cut

 sub snfft {

	my ( $self,$snfft )		= @_;
	if ( $snfft ne $empty_string ) {

		$sulfaf->{_snfft}		= $snfft;
		$sulfaf->{_note}		= $sulfaf->{_note}.' snfft='.$sulfaf->{_snfft};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' snfft='.$sulfaf->{_snfft};

	} else { 
		print("sulfaf, snfft, missing snfft,\n");
	 }
 }


=head2 sub tmpr 


=cut

 sub tmpr {

	my ( $self,$tmpr )		= @_;
	if ( $tmpr ne $empty_string ) {

		$sulfaf->{_tmpr}		= $tmpr;
		$sulfaf->{_note}		= $sulfaf->{_note}.' tmpr='.$sulfaf->{_tmpr};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' tmpr='.$sulfaf->{_tmpr};

	} else { 
		print("sulfaf, tmpr, missing tmpr,\n");
	 }
 }


=head2 sub tri 


=cut

 sub tri {

	my ( $self,$tri )		= @_;
	if ( $tri ne $empty_string ) {

		$sulfaf->{_tri}		= $tri;
		$sulfaf->{_note}		= $sulfaf->{_note}.' tri='.$sulfaf->{_tri};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' tri='.$sulfaf->{_tri};

	} else { 
		print("sulfaf, tri, missing tri,\n");
	 }
 }


=head2 sub vel 


=cut

 sub vel {

	my ( $self,$vel )		= @_;
	if ( $vel ne $empty_string ) {

		$sulfaf->{_vel}		= $vel;
		$sulfaf->{_note}		= $sulfaf->{_note}.' vel='.$sulfaf->{_vel};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' vel='.$sulfaf->{_vel};

	} else { 
		print("sulfaf, vel, missing vel,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sulfaf->{_verbose}		= $verbose;
		$sulfaf->{_note}		= $sulfaf->{_note}.' verbose='.$sulfaf->{_verbose};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' verbose='.$sulfaf->{_verbose};

	} else { 
		print("sulfaf, verbose, missing verbose,\n");
	 }
 }


=head2 sub wh 


=cut

 sub wh {

	my ( $self,$wh )		= @_;
	if ( $wh ne $empty_string ) {

		$sulfaf->{_wh}		= $wh;
		$sulfaf->{_note}		= $sulfaf->{_note}.' wh='.$sulfaf->{_wh};
		$sulfaf->{_Step}		= $sulfaf->{_Step}.' wh='.$sulfaf->{_wh};

	} else { 
		print("sulfaf, wh, missing wh,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 39;

    return($max_index);
}
 
 
1;
