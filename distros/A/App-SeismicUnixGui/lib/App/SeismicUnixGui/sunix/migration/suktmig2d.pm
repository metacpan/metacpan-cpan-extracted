package App::SeismicUnixGui::sunix::migration::suktmig2d;

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
 SUKTMIG2D - prestack time migration of a common-offset	

	section with the double-square root (DSR) operator	





   suktmig2d < infile vfile= [parameters]  > outfile		



 Required Parameters:						

 vfile=	rms velocity file (units/s) v(t,x) as a function

		of time						

 dx=		distance (units) between consecutive traces	



 Optional parameters:						

 fcdpdata=tr.cdp	first cdp in data			

 firstcdp=fcdpdata	first cdp number in velocity file	

 lastcdp=from header	last cdp number in velocity file	

 dcdp=from header	number of cdps between consecutive traces

 angmax=40	maximum aperture angle for migration (degrees)	

 hoffset=.5*tr.offset		half offset (m)			

 nfc=16	number of Fourier-coefficients to approximate	

		low-pass					

		filters. The larger nfc the narrower the filter	

 fwidth=5 	high-end frequency increment for the low-pass	

 		filters						

 		in Hz. The lower this number the more the number

		of lowpass filters to be calculated for each 	

		input trace.					



 Caveat: this code may need some work				

 Notes:							

 Data must be preprocessed with sufrac to correct for the	

 wave-shaping factor using phasefac=.25 for 2D migration.	



 Input traces must be sorted into offset and cdp number.	

 The velocity file consists of rms velocities for all CMPs as a

 function of vertical time and horizontal position v(t,x)	

 in C-style binary floating point numbers.  It's easiest to 	

 supply v(t,x) that has the same dimensions as the input data to

 be migrated. Note that time t is the fast dimension in these  

 the input velocity file.					



 The units may be feet or meters, as long as these are		

 consistent.							

 Antialias filter is performed using (Gray,1992, Geoph. Prosp), 

 using nc low- pass filtered copies of the data. The cutoff	

 frequencies are calculated  as fractions of the Nyquist	

 frequency.							



 The maximum allowed angle is 80 degrees(a 10 degree taper is 

 applied to the end of the aperture)				



define LOOKFAC 2       /* Look ahead factor for npfaro  

define PFA_MAX 720720  /* Largest allowed nfft	  





 Prototype of functions used internally

void lpfilt(int nfc, int nfft, float dt, float fhi, float *filter);



segy intrace; 	/* input traces

segy outtrace;	/* migrated output traces



int

main(int argc, char **argv)

{

	int i,k,imp,iip,it,ix,ifc;	/* counters

	int ntr,nt;			/* x,t



	int verbose;	/* is verbose?				*/

	int nc;		/* number of low-pass filtered versions	*/

			/*  of the data for antialiasing	*/

	int nfft,nf;	/* number of frequencies		*/

	int nfc;	/* number of Fourier coefficients for low-pass filter

	int fwidth;	/* high-end frequency increment for the low-pass

			/* filters 				*/

	int firstcdp=0;	/* first cdp in velocity file		*/

	int lastcdp=0;	/* last cdp in velocity file		*/

	int oldcdp=0;	/* temporary storage			*/

	int fcdpdata=0;	/* first cdp in the data		*/

	int olddeltacdp=0;

	int deltacdp;

	int ncdp=0;	/* number of cdps in the velocity file	*/

	int dcdp=0;	/* number of cdps between consecutive traces



	float dx=0.0;	/* cdp sample interval

	float hoffset=0.0;  /* half receiver-source

	float p=0.0;	/* horizontal slowness of the migration operator

	float pmin=0.0;	/* maximum horizontal slowness for which there's

			/* no aliasing of the operator

	float dt;	/* t sample interval

	float h;	/* offset

	float x;	/* aperture distance

	float xmax=0.0;	/* maximum aperture distance



	float obliq;	/* obliquity factor

	float geoms;	/* geometrical spreading factor

	float angmax;   /* maximum aperture angle



	float mp,ip;	/* mid-point and image-point coordinates

	float t;	/* time

	float t0;	/* vertical traveltime

	float tmax;	/* maximum time



	float fnyq;	/* Nyquist frequency

	float ang;	/* aperture angle

	float angtaper=0.0;	/* aperture-angle taper

	float v;		/* velocity

  

	float *fc=NULL;		/* cut-frequencies for low-pass filters

	float *filter=NULL;	/* array of low-pass filter values



	float **vel=NULL;	/* array of velocity values from vfile

	float **data=NULL;	/* input data array*/

	float **lowpass=NULL;   /* low-pass filtered version of the trace

	float **mig=NULL;	/* output migrated data array



	register float *rtin=NULL,*rtout=NULL;/* real traces

	register complex *ct=NULL;   /* complex trace



	/* file names

	char *vfile="";		/* name of velocity file

	FILE *vfp=NULL;

	FILE *tracefp=NULL;	/* temp file to hold traces*/

	FILE *hfp=NULL;		/* temp file to hold trace headers



	float datalo[8], datahi[8];

	int itb, ite;

	float firstt, amplo, amphi;



	cwp_Bool check_cdp=cwp_false;	/* check cdp in velocity file	*/



	/* Hook up getpar to handle the parameters

	initargs(argc,argv);

	requestdoc(0);

	

	/* Get info from first trace

	if (!gettr(&intrace))  err("can't get first trace");

	nt=intrace.ns;

	dt=(float)intrace.dt/1000000;

	tmax=(nt-1)*dt;



	MUSTGETPARFLOAT("dx",&dx);

	MUSTGETPARSTRING("vfile",&vfile);

	if (!getparfloat("angmax",&angmax)) angmax=40;

	if (!getparint("firstcdp",&firstcdp)) firstcdp=intrace.cdp;

	if (!getparint("fcdpdata",&fcdpdata)) fcdpdata=intrace.cdp;

	if (!getparfloat("hoffset",&hoffset)) hoffset=.5*intrace.offset;

	if (!getparint("nfc",&nfc)) nfc=16;

	if (!getparint("fwidth",&fwidth)) fwidth=5;

	if (!getparint("verbose",&verbose)) verbose=0;



	h=hoffset;



	/* Store traces in tmpfile while getting a count of number of traces

	tracefp = etmpfile();

	hfp = etmpfile();

	ntr = 0;

	do {

		++ntr;



		/* get new deltacdp value

		deltacdp=intrace.cdp-oldcdp;



		/* read headers and data

		efwrite(&intrace,HDRBYTES, 1, hfp);

		efwrite(intrace.data, FSIZE, nt, tracefp);



		/* error trappings.

		/* ...did cdp value interval change?

		if ((ntr>3) && (olddeltacdp!=deltacdp)) {



			if (verbose) {

			warn("cdp interval changed in data");	

			warn("ntr=0 olddeltacdp=0 deltacdp=0"

				,ntr,olddeltacdp,deltacdp);

		 	check_cdp=cwp_true;

			}

		}

		

		/* save cdp and deltacdp values

		oldcdp=intrace.cdp;

		olddeltacdp=deltacdp;



	} while (gettr(&intrace));



	/* get last cdp  and dcdp

	if (!getparint("lastcdp",&lastcdp)) lastcdp=intrace.cdp; 

	if (!getparint("dcdp",&dcdp))	dcdp=deltacdp - 1;





	checkpars();



	/* error trappings

	if ( (firstcdp==lastcdp) 

		|| (dcdp==0) 

		|| (check_cdp==cwp_true) ) warn("Check cdp values in data!");



	/* rewind trace file pointer and header file pointer

	erewind(tracefp);

	erewind(hfp);



	/* total number of cdp's in data

	ncdp=lastcdp-firstcdp+1;



	/* Set up FFT parameters

	nfft = npfaro(nt, LOOKFAC*nt);

	if(nfft>= SU_NFLTS || nfft >= PFA_MAX)

	  err("Padded nt=0 -- too big",nfft);

	nf = nfft/2 + 1;



	/* Determine number of filters for antialiasing

	fnyq= 1.0/(2*dt);

	nc=ceil(fnyq/fwidth);

	if (verbose)

		warn(" The number of filters for antialiasing is nc= 0",nc);



	/* Allocate space

	data = alloc2float(nt,ntr);

	lowpass=alloc2float(nt,nc+1);

	mig=   alloc2float(nt,ntr);

	vel=   alloc2float(nt,ncdp);

	fc = alloc1float(nc+1);

	rtin= ealloc1float(nfft);

	rtout= ealloc1float(nfft);

	ct= ealloc1complex(nf);

	filter= alloc1float(nf);



	/* Read data from temporal array

	for (ix=0; ix<ntr; ++ix){

		efread(data[ix],FSIZE,nt,tracefp);

	}



	/* read velocities

	vfp=efopen(vfile,"r");

	efread(vel[0],FSIZE,nt*ncdp,vfp);

	efclose(vfp);



	/* Zero all arrays

	memset((void *) mig[0], 0,nt*ntr*FSIZE);

	memset((void *) rtin, 0, nfft*FSIZE);

	memset((void *) filter, 0, nf*FSIZE);

	memset((void *) lowpass[0], 0,nt*(nc+1)*FSIZE);



	/* Calculate cut frequencies for low-pass filters

	for(i=1; i<nc+1; ++i){

		fc[i]= fnyq*i/nc;

	}



	/* Start the migration process

	/* Loop over input mid-points first

	if (verbose) warn("Starting migration process...\n");

	for(imp=0; imp<ntr; ++imp){

		float perc;



		mp=imp*dx; 

		perc=imp*100.0/(ntr-1);

		if(fmod(imp*100,ntr-1)==0 && verbose)

			warn("migrated 0\n ",perc);



		/* Calculate low-pass filtered versions 

		/* of the data to be used for antialiasing

		for(it=0; it<nt; ++it){

			rtin[it]=data[imp][it];

		}

		for(ifc=1; ifc<nc+1; ++ifc){

			memset((void *) rtout, 0, nfft*FSIZE);

			memset((void *) ct, 0, nf*FSIZE);

			lpfilt(nfc,nfft,dt,fc[ifc],filter);

			pfarc(1,nfft,rtin,ct);



			for(it=0; it<nf; ++it){

				ct[it] = crmul(ct[it],filter[it]);

			}

			pfacr(-1,nfft,ct,rtout);

			for(it=0; it<nt; ++it){ 

				lowpass[ifc][it]= rtout[it]; 

			}

		}



		/* Loop over vertical traveltimes

		for(it=0; it<nt; ++it){

			int lx,ux;



			t0=it*dt;

			v=vel[imp*dcdp+fcdpdata-1][it];

			xmax=tan((angmax+10.0)*PI/180.0)*v*t0;

			lx=MAX(0,imp - ceil(xmax/dx)); 

			ux=MIN(ntr,imp + ceil(xmax/dx));

	

		/* loop over output image-points to the left of the midpoint

		for(iip=imp; iip>lx; --iip){

			float ts,tr;

			int fplo=0, fphi=0;

			float ref,wlo,whi;



			ip=iip*dx; 

			x=ip-mp; 

			ts=sqrt( pow(t0/2,2) + pow((x+h)/v,2) );

			tr=sqrt( pow(t0/2,2) + pow((h-x)/v,2) );

			t= ts + tr;

			if(t>=tmax) break;

			geoms=sqrt(1/(t*v));

	  		obliq=sqrt(.5*(1 + (t0*t0/(4*ts*tr)) 

					- (1/(ts*tr))*sqrt(ts*ts - t0*t0/4)*sqrt(tr*tr - t0*t0/4)));

	  		ang=180.0*fabs(acos(t0/t))/PI;  

	  		if(ang<=angmax) angtaper=1.0;

	  		if(ang>angmax) angtaper=cos((ang-angmax)*PI/20);

	  		/* Evaluate migration operator slowness p to determine

			/* the low-pass filtered trace for antialiasing

			pmin=1/(2*dx*fnyq);

			p=fabs((x+h)/(pow(v,2)*ts) + (x-h)/(pow(v,2)*tr));

				if(p>0){fplo=floor(nc*pmin/p);}

				if(p==0){fplo=nc;}

				ref=fmod(nc*pmin,p);

				wlo=1-ref;

				fphi=++fplo;

				whi=ref;

				itb=MAX(ceil(t/dt)-3,0);

				ite=MIN(itb+8,nt);

				firstt=(itb-1)*dt;

				/* Move energy from CMP to CIP

				if(fplo>=nc){

					for(k=itb; k<ite; ++k){

						datalo[k-itb]=lowpass[nc][k];

					}

					ints8r(8,dt,firstt,datalo,0.0,0.0,1,&t,&amplo);

					mig[iip][it] +=geoms*obliq*angtaper*amplo;

				} else if(fplo<nc){

					for(k=itb; k<ite; ++k){

						datalo[k-itb]=lowpass[fplo][k];

						datahi[k-itb]=lowpass[fphi][k];

					}

					ints8r(8,dt,firstt,datalo,0.0,0.0,1,&t,&amplo);

					ints8r(8,dt,firstt,datahi,0.0,0.0,1,&t,&amphi);

					mig[iip][it] += geoms*obliq*angtaper*(wlo*amplo + whi*amphi);

				}

			}



			/* loop over output image-points to the right of the midpoint

			for(iip=imp+1; iip<ux; ++iip){

				float ts,tr;

				int fplo=0, fphi;

				float ref,wlo,whi;



				ip=iip*dx; 

				x=ip-mp; 

				t0=it*dt;	  

				ts=sqrt( pow(t0/2,2) + pow((x+h)/v,2) );

				tr=sqrt( pow(t0/2,2) + pow((h-x)/v,2) );

				t= ts + tr;

				if(t>=tmax) break;

				geoms=sqrt(1/(t*v));

				obliq=sqrt(.5*(1 + (t0*t0/(4*ts*tr)) 

					- (1/(ts*tr))*sqrt(ts*ts 

						- t0*t0/4)*sqrt(tr*tr 

								- t0*t0/4)));

				ang=180.0*fabs(acos(t0/t))/PI;   

				if(ang<=angmax) angtaper=1.0;

				if(ang>angmax) angtaper=cos((ang-angmax)*PI/20.0);



				/* Evaluate migration operator slowness p to determine the 

				/* low-pass filtered trace for antialiasing

				pmin=1/(2*dx*fnyq);

				p=fabs((x+h)/(pow(v,2)*ts) + (x-h)/(pow(v,2)*tr));

				if(p>0){

					fplo=floor(nc*pmin/p);

				}

				if(p==0){

					fplo=nc;

				}



				ref=fmod(nc*pmin,p);

				wlo=1-ref;

				fphi=fplo+1;

				whi=ref;

				itb=MAX(ceil(t/dt)-3,0);

				ite=MIN(itb+8,nt);

				firstt=(itb-1)*dt;



				/* Move energy from CMP to CIP

				if(fplo>=nc){

					for(k=itb; k<ite; ++k){

						datalo[k-itb]=lowpass[nc][k];

					}

					ints8r(8,dt,firstt,datalo,0.0,0.0,1,&t,&amplo);

					mig[iip][it] +=geoms*obliq*angtaper*amplo;

				} else if(fplo<nc){

					for(k=itb; k<ite; ++k){

						datalo[k-itb]=lowpass[fplo][k];

						datahi[k-itb]=lowpass[fphi][k];

					}

					ints8r(8,dt,firstt,datalo,0.0,0.0,1,&t,&amplo);

					ints8r(8,dt,firstt,datahi,0.0,0.0,1,&t,&amphi);

					mig[iip][it] += geoms*obliq*angtaper*(wlo*amplo + whi*amphi);

				}

			}



		}

	} 



	/* Output migrated data

	erewind(hfp);

	for (ix=0; ix<ntr; ++ix) {

		efread(&outtrace, HDRBYTES, 1, hfp);

		for (it=0; it<nt; ++it) {

			outtrace.data[it] = mig[ix][it];

		}

		puttr(&outtrace);

	}



	efclose(hfp);



	return(CWP_Exit());

}



void

lpfilt(int nfc, int nfft, float dt, float fhi, float *filter)

lpfilt -- low-pass filter using Lanczos Smoothing 

	(R.W. Hamming:"Digital Filtering",1977)

Input: 

nfc	number of Fourier coefficients to approximate ideal filter

nfft	number of points in the fft

dt	time sampling interval

fhi	cut-frequency



Output:

filter  array[nf] of filter values

Notes: Filter is to be applied in the frequency domain   

Author: CWP: Carlos Pacheco   2006   

{

	int i,j;  /* counters

	int nf;   /* Number of frequencies (including Nyquist)

	float onfft;  /* reciprocal of nfft

	float fn; /* Nyquist frequency

	float df; /* frequency interval

	float dw; /* frequency interval in radians

	float whi;/* cut-frequency in radians

	float w;  /* radian frequency



	nf= nfft/2 + 1;

	onfft=1.0/nfft;

	fn=1.0/(2*dt);

	df=onfft/dt;

	whi=fhi*PI/fn;

	dw=df*PI/fn;



	for(i=0; i<nf; ++i){

		filter[i]= whi/PI;

		w=i*dw;



		for(j=1; j<nfc; ++j){

			float c= sin(whi*j)*sin(PI*j/nfc)*2*nfc/(PI*PI*j*j);

			filter[i] +=c*cos(j*w);

		}

	}

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

my $suktmig2d			= {
	_ang					=> '',
	_angmax					=> '',
	_angtaper					=> '',
	_c					=> '',
	_check_cdp					=> '',
	_ct					=> '',
	_data					=> '',
	_dcdp					=> '',
	_deltacdp					=> '',
	_df					=> '',
	_dt					=> '',
	_dw					=> '',
	_dx					=> '',
	_fc					=> '',
	_fcdpdata					=> '',
	_filter					=> '',
	_firstcdp					=> '',
	_firstt					=> '',
	_fn					=> '',
	_fnyq					=> '',
	_fphi					=> '',
	_fplo					=> '',
	_fwidth					=> '',
	_geoms					=> '',
	_h					=> '',
	_hfp					=> '',
	_hoffset					=> '',
	_i					=> '',
	_ifc					=> '',
	_iip					=> '',
	_imp					=> '',
	_ip					=> '',
	_it					=> '',
	_itb					=> '',
	_ite					=> '',
	_ix					=> '',
	_j					=> '',
	_k					=> '',
	_lastcdp					=> '',
	_lowpass					=> '',
	_lx					=> '',
	_mig					=> '',
	_mp					=> '',
	_nc					=> '',
	_ncdp					=> '',
	_nf					=> '',
	_nfc					=> '',
	_nfft					=> '',
	_nt					=> '',
	_ntr					=> '',
	_obliq					=> '',
	_oldcdp					=> '',
	_olddeltacdp					=> '',
	_onfft					=> '',
	_p					=> '',
	_perc					=> '',
	_phasefac					=> '',
	_pmin					=> '',
	_ref					=> '',
	_rtin					=> '',
	_rtout					=> '',
	_t					=> '',
	_t0					=> '',
	_tmax					=> '',
	_tr					=> '',
	_tracefp					=> '',
	_ts					=> '',
	_ux					=> '',
	_v					=> '',
	_vel					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_vfp					=> '',
	_w					=> '',
	_whi					=> '',
	_wlo					=> '',
	_x					=> '',
	_xmax					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suktmig2d->{_Step}     = 'suktmig2d'.$suktmig2d->{_Step};
	return ( $suktmig2d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suktmig2d->{_note}     = 'suktmig2d'.$suktmig2d->{_note};
	return ( $suktmig2d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suktmig2d->{_ang}			= '';
		$suktmig2d->{_angmax}			= '';
		$suktmig2d->{_angtaper}			= '';
		$suktmig2d->{_c}			= '';
		$suktmig2d->{_check_cdp}			= '';
		$suktmig2d->{_ct}			= '';
		$suktmig2d->{_data}			= '';
		$suktmig2d->{_dcdp}			= '';
		$suktmig2d->{_deltacdp}			= '';
		$suktmig2d->{_df}			= '';
		$suktmig2d->{_dt}			= '';
		$suktmig2d->{_dw}			= '';
		$suktmig2d->{_dx}			= '';
		$suktmig2d->{_fc}			= '';
		$suktmig2d->{_fcdpdata}			= '';
		$suktmig2d->{_filter}			= '';
		$suktmig2d->{_firstcdp}			= '';
		$suktmig2d->{_firstt}			= '';
		$suktmig2d->{_fn}			= '';
		$suktmig2d->{_fnyq}			= '';
		$suktmig2d->{_fphi}			= '';
		$suktmig2d->{_fplo}			= '';
		$suktmig2d->{_fwidth}			= '';
		$suktmig2d->{_geoms}			= '';
		$suktmig2d->{_h}			= '';
		$suktmig2d->{_hfp}			= '';
		$suktmig2d->{_hoffset}			= '';
		$suktmig2d->{_i}			= '';
		$suktmig2d->{_ifc}			= '';
		$suktmig2d->{_iip}			= '';
		$suktmig2d->{_imp}			= '';
		$suktmig2d->{_ip}			= '';
		$suktmig2d->{_it}			= '';
		$suktmig2d->{_itb}			= '';
		$suktmig2d->{_ite}			= '';
		$suktmig2d->{_ix}			= '';
		$suktmig2d->{_j}			= '';
		$suktmig2d->{_k}			= '';
		$suktmig2d->{_lastcdp}			= '';
		$suktmig2d->{_lowpass}			= '';
		$suktmig2d->{_lx}			= '';
		$suktmig2d->{_mig}			= '';
		$suktmig2d->{_mp}			= '';
		$suktmig2d->{_nc}			= '';
		$suktmig2d->{_ncdp}			= '';
		$suktmig2d->{_nf}			= '';
		$suktmig2d->{_nfc}			= '';
		$suktmig2d->{_nfft}			= '';
		$suktmig2d->{_nt}			= '';
		$suktmig2d->{_ntr}			= '';
		$suktmig2d->{_obliq}			= '';
		$suktmig2d->{_oldcdp}			= '';
		$suktmig2d->{_olddeltacdp}			= '';
		$suktmig2d->{_onfft}			= '';
		$suktmig2d->{_p}			= '';
		$suktmig2d->{_perc}			= '';
		$suktmig2d->{_phasefac}			= '';
		$suktmig2d->{_pmin}			= '';
		$suktmig2d->{_ref}			= '';
		$suktmig2d->{_rtin}			= '';
		$suktmig2d->{_rtout}			= '';
		$suktmig2d->{_t}			= '';
		$suktmig2d->{_t0}			= '';
		$suktmig2d->{_tmax}			= '';
		$suktmig2d->{_tr}			= '';
		$suktmig2d->{_tracefp}			= '';
		$suktmig2d->{_ts}			= '';
		$suktmig2d->{_ux}			= '';
		$suktmig2d->{_v}			= '';
		$suktmig2d->{_vel}			= '';
		$suktmig2d->{_verbose}			= '';
		$suktmig2d->{_vfile}			= '';
		$suktmig2d->{_vfp}			= '';
		$suktmig2d->{_w}			= '';
		$suktmig2d->{_whi}			= '';
		$suktmig2d->{_wlo}			= '';
		$suktmig2d->{_x}			= '';
		$suktmig2d->{_xmax}			= '';
		$suktmig2d->{_Step}			= '';
		$suktmig2d->{_note}			= '';
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$suktmig2d->{_ang}		= $ang;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ang='.$suktmig2d->{_ang};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ang='.$suktmig2d->{_ang};

	} else { 
		print("suktmig2d, ang, missing ang,\n");
	 }
 }


=head2 sub angmax 


=cut

 sub angmax {

	my ( $self,$angmax )		= @_;
	if ( $angmax ne $empty_string ) {

		$suktmig2d->{_angmax}		= $angmax;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' angmax='.$suktmig2d->{_angmax};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' angmax='.$suktmig2d->{_angmax};

	} else { 
		print("suktmig2d, angmax, missing angmax,\n");
	 }
 }


=head2 sub angtaper 


=cut

 sub angtaper {

	my ( $self,$angtaper )		= @_;
	if ( $angtaper ne $empty_string ) {

		$suktmig2d->{_angtaper}		= $angtaper;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' angtaper='.$suktmig2d->{_angtaper};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' angtaper='.$suktmig2d->{_angtaper};

	} else { 
		print("suktmig2d, angtaper, missing angtaper,\n");
	 }
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$suktmig2d->{_c}		= $c;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' c='.$suktmig2d->{_c};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' c='.$suktmig2d->{_c};

	} else { 
		print("suktmig2d, c, missing c,\n");
	 }
 }


=head2 sub check_cdp 


=cut

 sub check_cdp {

	my ( $self,$check_cdp )		= @_;
	if ( $check_cdp ne $empty_string ) {

		$suktmig2d->{_check_cdp}		= $check_cdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' check_cdp='.$suktmig2d->{_check_cdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' check_cdp='.$suktmig2d->{_check_cdp};

	} else { 
		print("suktmig2d, check_cdp, missing check_cdp,\n");
	 }
 }


=head2 sub ct 


=cut

 sub ct {

	my ( $self,$ct )		= @_;
	if ( $ct ne $empty_string ) {

		$suktmig2d->{_ct}		= $ct;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ct='.$suktmig2d->{_ct};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ct='.$suktmig2d->{_ct};

	} else { 
		print("suktmig2d, ct, missing ct,\n");
	 }
 }


=head2 sub data 


=cut

 sub data {

	my ( $self,$data )		= @_;
	if ( $data ne $empty_string ) {

		$suktmig2d->{_data}		= $data;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' data='.$suktmig2d->{_data};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' data='.$suktmig2d->{_data};

	} else { 
		print("suktmig2d, data, missing data,\n");
	 }
 }


=head2 sub dcdp 


=cut

 sub dcdp {

	my ( $self,$dcdp )		= @_;
	if ( $dcdp ne $empty_string ) {

		$suktmig2d->{_dcdp}		= $dcdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' dcdp='.$suktmig2d->{_dcdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' dcdp='.$suktmig2d->{_dcdp};

	} else { 
		print("suktmig2d, dcdp, missing dcdp,\n");
	 }
 }


=head2 sub deltacdp 


=cut

 sub deltacdp {

	my ( $self,$deltacdp )		= @_;
	if ( $deltacdp ne $empty_string ) {

		$suktmig2d->{_deltacdp}		= $deltacdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' deltacdp='.$suktmig2d->{_deltacdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' deltacdp='.$suktmig2d->{_deltacdp};

	} else { 
		print("suktmig2d, deltacdp, missing deltacdp,\n");
	 }
 }


=head2 sub df 


=cut

 sub df {

	my ( $self,$df )		= @_;
	if ( $df ne $empty_string ) {

		$suktmig2d->{_df}		= $df;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' df='.$suktmig2d->{_df};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' df='.$suktmig2d->{_df};

	} else { 
		print("suktmig2d, df, missing df,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suktmig2d->{_dt}		= $dt;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' dt='.$suktmig2d->{_dt};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' dt='.$suktmig2d->{_dt};

	} else { 
		print("suktmig2d, dt, missing dt,\n");
	 }
 }


=head2 sub dw 


=cut

 sub dw {

	my ( $self,$dw )		= @_;
	if ( $dw ne $empty_string ) {

		$suktmig2d->{_dw}		= $dw;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' dw='.$suktmig2d->{_dw};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' dw='.$suktmig2d->{_dw};

	} else { 
		print("suktmig2d, dw, missing dw,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suktmig2d->{_dx}		= $dx;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' dx='.$suktmig2d->{_dx};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' dx='.$suktmig2d->{_dx};

	} else { 
		print("suktmig2d, dx, missing dx,\n");
	 }
 }


=head2 sub fc 


=cut

 sub fc {

	my ( $self,$fc )		= @_;
	if ( $fc ne $empty_string ) {

		$suktmig2d->{_fc}		= $fc;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fc='.$suktmig2d->{_fc};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fc='.$suktmig2d->{_fc};

	} else { 
		print("suktmig2d, fc, missing fc,\n");
	 }
 }


=head2 sub fcdpdata 


=cut

 sub fcdpdata {

	my ( $self,$fcdpdata )		= @_;
	if ( $fcdpdata ne $empty_string ) {

		$suktmig2d->{_fcdpdata}		= $fcdpdata;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fcdpdata='.$suktmig2d->{_fcdpdata};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fcdpdata='.$suktmig2d->{_fcdpdata};

	} else { 
		print("suktmig2d, fcdpdata, missing fcdpdata,\n");
	 }
 }


=head2 sub filter 


=cut

 sub filter {

	my ( $self,$filter )		= @_;
	if ( $filter ne $empty_string ) {

		$suktmig2d->{_filter}		= $filter;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' filter='.$suktmig2d->{_filter};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' filter='.$suktmig2d->{_filter};

	} else { 
		print("suktmig2d, filter, missing filter,\n");
	 }
 }


=head2 sub firstcdp 


=cut

 sub firstcdp {

	my ( $self,$firstcdp )		= @_;
	if ( $firstcdp ne $empty_string ) {

		$suktmig2d->{_firstcdp}		= $firstcdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' firstcdp='.$suktmig2d->{_firstcdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' firstcdp='.$suktmig2d->{_firstcdp};

	} else { 
		print("suktmig2d, firstcdp, missing firstcdp,\n");
	 }
 }


=head2 sub firstt 


=cut

 sub firstt {

	my ( $self,$firstt )		= @_;
	if ( $firstt ne $empty_string ) {

		$suktmig2d->{_firstt}		= $firstt;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' firstt='.$suktmig2d->{_firstt};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' firstt='.$suktmig2d->{_firstt};

	} else { 
		print("suktmig2d, firstt, missing firstt,\n");
	 }
 }


=head2 sub fn 


=cut

 sub fn {

	my ( $self,$fn )		= @_;
	if ( $fn ne $empty_string ) {

		$suktmig2d->{_fn}		= $fn;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fn='.$suktmig2d->{_fn};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fn='.$suktmig2d->{_fn};

	} else { 
		print("suktmig2d, fn, missing fn,\n");
	 }
 }


=head2 sub fnyq 


=cut

 sub fnyq {

	my ( $self,$fnyq )		= @_;
	if ( $fnyq ne $empty_string ) {

		$suktmig2d->{_fnyq}		= $fnyq;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fnyq='.$suktmig2d->{_fnyq};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fnyq='.$suktmig2d->{_fnyq};

	} else { 
		print("suktmig2d, fnyq, missing fnyq,\n");
	 }
 }


=head2 sub fphi 


=cut

 sub fphi {

	my ( $self,$fphi )		= @_;
	if ( $fphi ne $empty_string ) {

		$suktmig2d->{_fphi}		= $fphi;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fphi='.$suktmig2d->{_fphi};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fphi='.$suktmig2d->{_fphi};

	} else { 
		print("suktmig2d, fphi, missing fphi,\n");
	 }
 }


=head2 sub fplo 


=cut

 sub fplo {

	my ( $self,$fplo )		= @_;
	if ( $fplo ne $empty_string ) {

		$suktmig2d->{_fplo}		= $fplo;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fplo='.$suktmig2d->{_fplo};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fplo='.$suktmig2d->{_fplo};

	} else { 
		print("suktmig2d, fplo, missing fplo,\n");
	 }
 }


=head2 sub fwidth 


=cut

 sub fwidth {

	my ( $self,$fwidth )		= @_;
	if ( $fwidth ne $empty_string ) {

		$suktmig2d->{_fwidth}		= $fwidth;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' fwidth='.$suktmig2d->{_fwidth};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' fwidth='.$suktmig2d->{_fwidth};

	} else { 
		print("suktmig2d, fwidth, missing fwidth,\n");
	 }
 }


=head2 sub geoms 


=cut

 sub geoms {

	my ( $self,$geoms )		= @_;
	if ( $geoms ne $empty_string ) {

		$suktmig2d->{_geoms}		= $geoms;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' geoms='.$suktmig2d->{_geoms};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' geoms='.$suktmig2d->{_geoms};

	} else { 
		print("suktmig2d, geoms, missing geoms,\n");
	 }
 }


=head2 sub h 


=cut

 sub h {

	my ( $self,$h )		= @_;
	if ( $h ne $empty_string ) {

		$suktmig2d->{_h}		= $h;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' h='.$suktmig2d->{_h};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' h='.$suktmig2d->{_h};

	} else { 
		print("suktmig2d, h, missing h,\n");
	 }
 }


=head2 sub hfp 


=cut

 sub hfp {

	my ( $self,$hfp )		= @_;
	if ( $hfp ne $empty_string ) {

		$suktmig2d->{_hfp}		= $hfp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' hfp='.$suktmig2d->{_hfp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' hfp='.$suktmig2d->{_hfp};

	} else { 
		print("suktmig2d, hfp, missing hfp,\n");
	 }
 }


=head2 sub hoffset 


=cut

 sub hoffset {

	my ( $self,$hoffset )		= @_;
	if ( $hoffset ne $empty_string ) {

		$suktmig2d->{_hoffset}		= $hoffset;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' hoffset='.$suktmig2d->{_hoffset};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' hoffset='.$suktmig2d->{_hoffset};

	} else { 
		print("suktmig2d, hoffset, missing hoffset,\n");
	 }
 }


=head2 sub i 


=cut

 sub i {

	my ( $self,$i )		= @_;
	if ( $i ne $empty_string ) {

		$suktmig2d->{_i}		= $i;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' i='.$suktmig2d->{_i};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' i='.$suktmig2d->{_i};

	} else { 
		print("suktmig2d, i, missing i,\n");
	 }
 }


=head2 sub ifc 


=cut

 sub ifc {

	my ( $self,$ifc )		= @_;
	if ( $ifc ne $empty_string ) {

		$suktmig2d->{_ifc}		= $ifc;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ifc='.$suktmig2d->{_ifc};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ifc='.$suktmig2d->{_ifc};

	} else { 
		print("suktmig2d, ifc, missing ifc,\n");
	 }
 }


=head2 sub iip 


=cut

 sub iip {

	my ( $self,$iip )		= @_;
	if ( $iip ne $empty_string ) {

		$suktmig2d->{_iip}		= $iip;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' iip='.$suktmig2d->{_iip};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' iip='.$suktmig2d->{_iip};

	} else { 
		print("suktmig2d, iip, missing iip,\n");
	 }
 }


=head2 sub imp 


=cut

 sub imp {

	my ( $self,$imp )		= @_;
	if ( $imp ne $empty_string ) {

		$suktmig2d->{_imp}		= $imp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' imp='.$suktmig2d->{_imp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' imp='.$suktmig2d->{_imp};

	} else { 
		print("suktmig2d, imp, missing imp,\n");
	 }
 }


=head2 sub ip 


=cut

 sub ip {

	my ( $self,$ip )		= @_;
	if ( $ip ne $empty_string ) {

		$suktmig2d->{_ip}		= $ip;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ip='.$suktmig2d->{_ip};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ip='.$suktmig2d->{_ip};

	} else { 
		print("suktmig2d, ip, missing ip,\n");
	 }
 }


=head2 sub it 


=cut

 sub it {

	my ( $self,$it )		= @_;
	if ( $it ne $empty_string ) {

		$suktmig2d->{_it}		= $it;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' it='.$suktmig2d->{_it};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' it='.$suktmig2d->{_it};

	} else { 
		print("suktmig2d, it, missing it,\n");
	 }
 }


=head2 sub itb 


=cut

 sub itb {

	my ( $self,$itb )		= @_;
	if ( $itb ne $empty_string ) {

		$suktmig2d->{_itb}		= $itb;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' itb='.$suktmig2d->{_itb};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' itb='.$suktmig2d->{_itb};

	} else { 
		print("suktmig2d, itb, missing itb,\n");
	 }
 }


=head2 sub ite 


=cut

 sub ite {

	my ( $self,$ite )		= @_;
	if ( $ite ne $empty_string ) {

		$suktmig2d->{_ite}		= $ite;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ite='.$suktmig2d->{_ite};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ite='.$suktmig2d->{_ite};

	} else { 
		print("suktmig2d, ite, missing ite,\n");
	 }
 }


=head2 sub ix 


=cut

 sub ix {

	my ( $self,$ix )		= @_;
	if ( $ix ne $empty_string ) {

		$suktmig2d->{_ix}		= $ix;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ix='.$suktmig2d->{_ix};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ix='.$suktmig2d->{_ix};

	} else { 
		print("suktmig2d, ix, missing ix,\n");
	 }
 }


=head2 sub j 


=cut

 sub j {

	my ( $self,$j )		= @_;
	if ( $j ne $empty_string ) {

		$suktmig2d->{_j}		= $j;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' j='.$suktmig2d->{_j};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' j='.$suktmig2d->{_j};

	} else { 
		print("suktmig2d, j, missing j,\n");
	 }
 }


=head2 sub k 


=cut

 sub k {

	my ( $self,$k )		= @_;
	if ( $k ne $empty_string ) {

		$suktmig2d->{_k}		= $k;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' k='.$suktmig2d->{_k};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' k='.$suktmig2d->{_k};

	} else { 
		print("suktmig2d, k, missing k,\n");
	 }
 }


=head2 sub lastcdp 


=cut

 sub lastcdp {

	my ( $self,$lastcdp )		= @_;
	if ( $lastcdp ne $empty_string ) {

		$suktmig2d->{_lastcdp}		= $lastcdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' lastcdp='.$suktmig2d->{_lastcdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' lastcdp='.$suktmig2d->{_lastcdp};

	} else { 
		print("suktmig2d, lastcdp, missing lastcdp,\n");
	 }
 }


=head2 sub lowpass 


=cut

 sub lowpass {

	my ( $self,$lowpass )		= @_;
	if ( $lowpass ne $empty_string ) {

		$suktmig2d->{_lowpass}		= $lowpass;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' lowpass='.$suktmig2d->{_lowpass};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' lowpass='.$suktmig2d->{_lowpass};

	} else { 
		print("suktmig2d, lowpass, missing lowpass,\n");
	 }
 }


=head2 sub lx 


=cut

 sub lx {

	my ( $self,$lx )		= @_;
	if ( $lx ne $empty_string ) {

		$suktmig2d->{_lx}		= $lx;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' lx='.$suktmig2d->{_lx};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' lx='.$suktmig2d->{_lx};

	} else { 
		print("suktmig2d, lx, missing lx,\n");
	 }
 }


=head2 sub mig 


=cut

 sub mig {

	my ( $self,$mig )		= @_;
	if ( $mig ne $empty_string ) {

		$suktmig2d->{_mig}		= $mig;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' mig='.$suktmig2d->{_mig};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' mig='.$suktmig2d->{_mig};

	} else { 
		print("suktmig2d, mig, missing mig,\n");
	 }
 }


=head2 sub mp 


=cut

 sub mp {

	my ( $self,$mp )		= @_;
	if ( $mp ne $empty_string ) {

		$suktmig2d->{_mp}		= $mp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' mp='.$suktmig2d->{_mp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' mp='.$suktmig2d->{_mp};

	} else { 
		print("suktmig2d, mp, missing mp,\n");
	 }
 }


=head2 sub nc 


=cut

 sub nc {

	my ( $self,$nc )		= @_;
	if ( $nc ne $empty_string ) {

		$suktmig2d->{_nc}		= $nc;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' nc='.$suktmig2d->{_nc};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' nc='.$suktmig2d->{_nc};

	} else { 
		print("suktmig2d, nc, missing nc,\n");
	 }
 }


=head2 sub ncdp 


=cut

 sub ncdp {

	my ( $self,$ncdp )		= @_;
	if ( $ncdp ne $empty_string ) {

		$suktmig2d->{_ncdp}		= $ncdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ncdp='.$suktmig2d->{_ncdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ncdp='.$suktmig2d->{_ncdp};

	} else { 
		print("suktmig2d, ncdp, missing ncdp,\n");
	 }
 }


=head2 sub nf 


=cut

 sub nf {

	my ( $self,$nf )		= @_;
	if ( $nf ne $empty_string ) {

		$suktmig2d->{_nf}		= $nf;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' nf='.$suktmig2d->{_nf};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' nf='.$suktmig2d->{_nf};

	} else { 
		print("suktmig2d, nf, missing nf,\n");
	 }
 }


=head2 sub nfc 


=cut

 sub nfc {

	my ( $self,$nfc )		= @_;
	if ( $nfc ne $empty_string ) {

		$suktmig2d->{_nfc}		= $nfc;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' nfc='.$suktmig2d->{_nfc};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' nfc='.$suktmig2d->{_nfc};

	} else { 
		print("suktmig2d, nfc, missing nfc,\n");
	 }
 }


=head2 sub nfft 


=cut

 sub nfft {

	my ( $self,$nfft )		= @_;
	if ( $nfft ne $empty_string ) {

		$suktmig2d->{_nfft}		= $nfft;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' nfft='.$suktmig2d->{_nfft};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' nfft='.$suktmig2d->{_nfft};

	} else { 
		print("suktmig2d, nfft, missing nfft,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suktmig2d->{_nt}		= $nt;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' nt='.$suktmig2d->{_nt};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' nt='.$suktmig2d->{_nt};

	} else { 
		print("suktmig2d, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$suktmig2d->{_ntr}		= $ntr;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ntr='.$suktmig2d->{_ntr};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ntr='.$suktmig2d->{_ntr};

	} else { 
		print("suktmig2d, ntr, missing ntr,\n");
	 }
 }


=head2 sub obliq 


=cut

 sub obliq {

	my ( $self,$obliq )		= @_;
	if ( $obliq ne $empty_string ) {

		$suktmig2d->{_obliq}		= $obliq;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' obliq='.$suktmig2d->{_obliq};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' obliq='.$suktmig2d->{_obliq};

	} else { 
		print("suktmig2d, obliq, missing obliq,\n");
	 }
 }


=head2 sub oldcdp 


=cut

 sub oldcdp {

	my ( $self,$oldcdp )		= @_;
	if ( $oldcdp ne $empty_string ) {

		$suktmig2d->{_oldcdp}		= $oldcdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' oldcdp='.$suktmig2d->{_oldcdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' oldcdp='.$suktmig2d->{_oldcdp};

	} else { 
		print("suktmig2d, oldcdp, missing oldcdp,\n");
	 }
 }


=head2 sub olddeltacdp 


=cut

 sub olddeltacdp {

	my ( $self,$olddeltacdp )		= @_;
	if ( $olddeltacdp ne $empty_string ) {

		$suktmig2d->{_olddeltacdp}		= $olddeltacdp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' olddeltacdp='.$suktmig2d->{_olddeltacdp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' olddeltacdp='.$suktmig2d->{_olddeltacdp};

	} else { 
		print("suktmig2d, olddeltacdp, missing olddeltacdp,\n");
	 }
 }


=head2 sub onfft 


=cut

 sub onfft {

	my ( $self,$onfft )		= @_;
	if ( $onfft ne $empty_string ) {

		$suktmig2d->{_onfft}		= $onfft;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' onfft='.$suktmig2d->{_onfft};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' onfft='.$suktmig2d->{_onfft};

	} else { 
		print("suktmig2d, onfft, missing onfft,\n");
	 }
 }


=head2 sub p 


=cut

 sub p {

	my ( $self,$p )		= @_;
	if ( $p ne $empty_string ) {

		$suktmig2d->{_p}		= $p;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' p='.$suktmig2d->{_p};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' p='.$suktmig2d->{_p};

	} else { 
		print("suktmig2d, p, missing p,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$suktmig2d->{_perc}		= $perc;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' perc='.$suktmig2d->{_perc};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' perc='.$suktmig2d->{_perc};

	} else { 
		print("suktmig2d, perc, missing perc,\n");
	 }
 }


=head2 sub phasefac 


=cut

 sub phasefac {

	my ( $self,$phasefac )		= @_;
	if ( $phasefac ne $empty_string ) {

		$suktmig2d->{_phasefac}		= $phasefac;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' phasefac='.$suktmig2d->{_phasefac};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' phasefac='.$suktmig2d->{_phasefac};

	} else { 
		print("suktmig2d, phasefac, missing phasefac,\n");
	 }
 }


=head2 sub pmin 


=cut

 sub pmin {

	my ( $self,$pmin )		= @_;
	if ( $pmin ne $empty_string ) {

		$suktmig2d->{_pmin}		= $pmin;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' pmin='.$suktmig2d->{_pmin};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' pmin='.$suktmig2d->{_pmin};

	} else { 
		print("suktmig2d, pmin, missing pmin,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$suktmig2d->{_ref}		= $ref;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ref='.$suktmig2d->{_ref};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ref='.$suktmig2d->{_ref};

	} else { 
		print("suktmig2d, ref, missing ref,\n");
	 }
 }


=head2 sub rtin 


=cut

 sub rtin {

	my ( $self,$rtin )		= @_;
	if ( $rtin ne $empty_string ) {

		$suktmig2d->{_rtin}		= $rtin;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' rtin='.$suktmig2d->{_rtin};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' rtin='.$suktmig2d->{_rtin};

	} else { 
		print("suktmig2d, rtin, missing rtin,\n");
	 }
 }


=head2 sub rtout 


=cut

 sub rtout {

	my ( $self,$rtout )		= @_;
	if ( $rtout ne $empty_string ) {

		$suktmig2d->{_rtout}		= $rtout;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' rtout='.$suktmig2d->{_rtout};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' rtout='.$suktmig2d->{_rtout};

	} else { 
		print("suktmig2d, rtout, missing rtout,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$suktmig2d->{_t}		= $t;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' t='.$suktmig2d->{_t};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' t='.$suktmig2d->{_t};

	} else { 
		print("suktmig2d, t, missing t,\n");
	 }
 }


=head2 sub t0 


=cut

 sub t0 {

	my ( $self,$t0 )		= @_;
	if ( $t0 ne $empty_string ) {

		$suktmig2d->{_t0}		= $t0;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' t0='.$suktmig2d->{_t0};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' t0='.$suktmig2d->{_t0};

	} else { 
		print("suktmig2d, t0, missing t0,\n");
	 }
 }


=head2 sub tmax 


=cut

 sub tmax {

	my ( $self,$tmax )		= @_;
	if ( $tmax ne $empty_string ) {

		$suktmig2d->{_tmax}		= $tmax;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' tmax='.$suktmig2d->{_tmax};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' tmax='.$suktmig2d->{_tmax};

	} else { 
		print("suktmig2d, tmax, missing tmax,\n");
	 }
 }


=head2 sub tr 


=cut

 sub tr {

	my ( $self,$tr )		= @_;
	if ( $tr ne $empty_string ) {

		$suktmig2d->{_tr}		= $tr;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' tr='.$suktmig2d->{_tr};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' tr='.$suktmig2d->{_tr};

	} else { 
		print("suktmig2d, tr, missing tr,\n");
	 }
 }


=head2 sub tracefp 


=cut

 sub tracefp {

	my ( $self,$tracefp )		= @_;
	if ( $tracefp ne $empty_string ) {

		$suktmig2d->{_tracefp}		= $tracefp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' tracefp='.$suktmig2d->{_tracefp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' tracefp='.$suktmig2d->{_tracefp};

	} else { 
		print("suktmig2d, tracefp, missing tracefp,\n");
	 }
 }


=head2 sub ts 


=cut

 sub ts {

	my ( $self,$ts )		= @_;
	if ( $ts ne $empty_string ) {

		$suktmig2d->{_ts}		= $ts;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ts='.$suktmig2d->{_ts};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ts='.$suktmig2d->{_ts};

	} else { 
		print("suktmig2d, ts, missing ts,\n");
	 }
 }


=head2 sub ux 


=cut

 sub ux {

	my ( $self,$ux )		= @_;
	if ( $ux ne $empty_string ) {

		$suktmig2d->{_ux}		= $ux;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' ux='.$suktmig2d->{_ux};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' ux='.$suktmig2d->{_ux};

	} else { 
		print("suktmig2d, ux, missing ux,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$suktmig2d->{_v}		= $v;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' v='.$suktmig2d->{_v};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' v='.$suktmig2d->{_v};

	} else { 
		print("suktmig2d, v, missing v,\n");
	 }
 }


=head2 sub vel 


=cut

 sub vel {

	my ( $self,$vel )		= @_;
	if ( $vel ne $empty_string ) {

		$suktmig2d->{_vel}		= $vel;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' vel='.$suktmig2d->{_vel};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' vel='.$suktmig2d->{_vel};

	} else { 
		print("suktmig2d, vel, missing vel,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suktmig2d->{_verbose}		= $verbose;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' verbose='.$suktmig2d->{_verbose};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' verbose='.$suktmig2d->{_verbose};

	} else { 
		print("suktmig2d, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suktmig2d->{_vfile}		= $vfile;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' vfile='.$suktmig2d->{_vfile};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' vfile='.$suktmig2d->{_vfile};

	} else { 
		print("suktmig2d, vfile, missing vfile,\n");
	 }
 }


=head2 sub vfp 


=cut

 sub vfp {

	my ( $self,$vfp )		= @_;
	if ( $vfp ne $empty_string ) {

		$suktmig2d->{_vfp}		= $vfp;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' vfp='.$suktmig2d->{_vfp};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' vfp='.$suktmig2d->{_vfp};

	} else { 
		print("suktmig2d, vfp, missing vfp,\n");
	 }
 }


=head2 sub w 


=cut

 sub w {

	my ( $self,$w )		= @_;
	if ( $w ne $empty_string ) {

		$suktmig2d->{_w}		= $w;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' w='.$suktmig2d->{_w};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' w='.$suktmig2d->{_w};

	} else { 
		print("suktmig2d, w, missing w,\n");
	 }
 }


=head2 sub whi 


=cut

 sub whi {

	my ( $self,$whi )		= @_;
	if ( $whi ne $empty_string ) {

		$suktmig2d->{_whi}		= $whi;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' whi='.$suktmig2d->{_whi};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' whi='.$suktmig2d->{_whi};

	} else { 
		print("suktmig2d, whi, missing whi,\n");
	 }
 }


=head2 sub wlo 


=cut

 sub wlo {

	my ( $self,$wlo )		= @_;
	if ( $wlo ne $empty_string ) {

		$suktmig2d->{_wlo}		= $wlo;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' wlo='.$suktmig2d->{_wlo};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' wlo='.$suktmig2d->{_wlo};

	} else { 
		print("suktmig2d, wlo, missing wlo,\n");
	 }
 }


=head2 sub x 


=cut

 sub x {

	my ( $self,$x )		= @_;
	if ( $x ne $empty_string ) {

		$suktmig2d->{_x}		= $x;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' x='.$suktmig2d->{_x};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' x='.$suktmig2d->{_x};

	} else { 
		print("suktmig2d, x, missing x,\n");
	 }
 }


=head2 sub xmax 


=cut

 sub xmax {

	my ( $self,$xmax )		= @_;
	if ( $xmax ne $empty_string ) {

		$suktmig2d->{_xmax}		= $xmax;
		$suktmig2d->{_note}		= $suktmig2d->{_note}.' xmax='.$suktmig2d->{_xmax};
		$suktmig2d->{_Step}		= $suktmig2d->{_Step}.' xmax='.$suktmig2d->{_xmax};

	} else { 
		print("suktmig2d, xmax, missing xmax,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 77;

    return($max_index);
}
 
 
1;
