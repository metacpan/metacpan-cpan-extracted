package App::SeismicUnixGui::sunix::model::raydata;

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
 RAYDATA - simple program to display ray data from elaray		



raydata <rayends   [optional parameters]				



Optional Parameters: 							

kend=      Index of interest						

t=0    =1 output of x_t requested 					

px=0   =1 output of x_px requested 					

pz=0   =1 output of x_pz requested 					

vgx=0  =1 output of x_vgx requested 					

vgz=0  =1 output of x_vgz requested 					

pxvx=0 =1 output of px_vgx requested 					

pol=0  =1 output of x_polangle requested 				

ascci=0    binary output						

	=1  ascci output						



Simple program to display some of the computed raydata.                

Output is written into files <*.data>                                  









Author:  Andreas Rueger, Colorado School of Mines, 02/15/94







 the main program

int main (int argc, char **argv)

{

	int ir,nre,nrealloc,nri,iri,tout,ascci;

	int pxout,pzout,vgxout,vgzout,pxvxout;

	int polout;

	float *tdata=NULL,*xdata=NULL,*pxdata=NULL,*pzdata=NULL;

	float *vgxdata=NULL,*vgzdata=NULL,*pxvxdata=NULL;

	float *poldata=NULL,*g11data=NULL,*g33data=NULL,*g13data=NULL;

	/* float g11,g33,g13;*/

        int kend;

	RayEnd *re;	

        FILE *txfp=NULL,*pxfp=NULL,*pzfp=NULL,*vgxfp=NULL,*vgzfp=NULL; 

        FILE *outparfp=NULL,*polfp=NULL,*pxvxfp=NULL;



	/* hook up getpar to handle the parameters

	initargs(argc,argv);

	requestdoc(0);

	

	/* get parameters

	if (!getparint("kend",&kend)) kend = INT_MAX;

	if (!getparint("t",&tout))  tout  = 0; 

	if (!getparint("px",&pxout))  pxout  = 0; 

	if (!getparint("pz",&pzout))  pzout  = 0; 

	if (!getparint("vgx",&vgxout))  vgxout  = 0; 

	if (!getparint("vgz",&vgzout))  vgzout  = 0; 

	if (!getparint("pxvx",&pxvxout))  pxvxout  = 0; 

	if (!getparint("pol",&polout))  polout  = 0; 



	if (!getparint("ascci",&ascci)) ascci = 0;



        checkpars();



        /* output file control

        if(tout>0) txfp= fopen("x_t.data","w");

        if(pxout) pxfp= fopen("x_px.data","w");

        if(pzout) pzfp= fopen("x_pz.data","w");

        if(vgxout) vgxfp= fopen("x_vgx.data","w");

        if(vgzout) vgzfp= fopen("x_vgz.data","w");

        if(pxvxout) pxvxfp= fopen("px_vgx.data","w");

        if(polout) polfp= fopen("x_pol.data","w");

        if(!ascci) outparfp = efopen("outpar","w");



	/* read rayends

	nre = nri = 0;

	nrealloc = 301;

	re = ealloc1(nrealloc,sizeof(RayEnd));





	while (fread(&re[nre],sizeof(RayEnd),1,stdin)==1) {

		nre++;



		if (nre==nrealloc) {

			nrealloc += 100;

			re = erealloc1(re,nrealloc,sizeof(RayEnd));

		}

	}

	if(kend == INT_MAX){

            nri=nre;

        } else {    

            /* how many rayends are of interest

            for(ir = 0; ir < nre;ir +=1 )

		        if(re[ir].kend == kend) nri++;

        }



	/* allocate space for data files

        if(tout>0) tdata = ealloc1(nri,sizeof(float));

        if(pxout|| pxvxout) pxdata = ealloc1(nri,sizeof(float));

        if(pzout) pzdata = ealloc1(nri,sizeof(float));

        if(vgxout|| pxvxout) vgxdata = ealloc1(nri,sizeof(float));

        if(vgzout) vgzdata = ealloc1(nri,sizeof(float));

        if(pxvxout) pxvxdata = ealloc1(nri,sizeof(float));

        if(polout){

	  poldata = ealloc1(nri,sizeof(float));

	  g11data = ealloc1(nri,sizeof(float));

	  g13data = ealloc1(nri,sizeof(float));

	  g33data = ealloc1(nri,sizeof(float));

	}



        xdata = ealloc1(nri,sizeof(float));



        iri = 0;



        /* read in data into files

        for(ir = 0; ir < nre;ir +=1 ){

	  /*fprintf(stderr,"ir=0 \t kend=0\n",ir,re[ir].kend);*/

		if(re[ir].kend == kend || kend == INT_MAX) {

                   if(tout>0) tdata[iri]  = re[ir].t;

		   if(pxout|| pxvxout) pxdata[iri]  = re[ir].px;

                   if(pzout) pzdata[iri]  = re[ir].pz;

                   if(vgxout|| pxvxout) vgxdata[iri]  = re[ir].vgx;

                   if(vgzout) vgzdata[iri]  = re[ir].vgz;

		   if(polout){

			      g11data[iri] = re[ir].g11;

			      g33data[iri] = re[ir].g33;

			      g13data[iri] = re[ir].g13;

		   }

                   xdata[iri] = re[ir].x;

                   iri++;



                }

         }



     /* compute polarization

     if(polout){

	for(ir = 0; ir < nre;ir +=1 ){



		if(g13data[ir] > 0){

			poldata[ir]=atan(sqrt(g11data[ir]/g33data[ir]));

		} else if(g13data[ir] < 0){

			poldata[ir]=PI/2+atan(sqrt(g33data[ir]/g11data[ir]));

		} else if(g13data[ir] == 0 && g33data[ir]>0){

			poldata[ir]=0.0;

		} else if(g13data[ir] == 0 && g33data[ir]<0){

			poldata[ir]=PI/2;

		}

		/*fprintf(stderr,"pol=0\n",poldata[ir]);*/

	}

      }



     /* ASCII output for x_t

     if(ascci ==1 && tout ==1){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(txfp,"0.000000	0.000000\n",xdata[ir],tdata[ir]);

     /* Binary output for x_t

     } else if(ascci ==0 && tout ==1){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&tdata[ir],sizeof(float),1,txfp);

	    fwrite(&xdata[ir],sizeof(float),1,txfp);

        }

     }





     /* ASCII output for x_px

     if(ascci ==1 && pxout ==1){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(pxfp,"0.000000	0.000000\n",xdata[ir],pxdata[ir]);

     /* Binary output for x_px

     } else if(ascci ==0 && pxout ==1){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&pxdata[ir],sizeof(float),1,pxfp);

	    fwrite(&xdata[ir],sizeof(float),1,pxfp);

        }

     }





     /* ASCII output for x_pz

     if(ascci ==1 && pzout ==1){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(pzfp,"0.000000	0.000000\n",xdata[ir],pzdata[ir]);

     /* Binary output for x_pz

     } else if(ascci ==0 && pzout ==1){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&pzdata[ir],sizeof(float),1,pzfp);

	    fwrite(&xdata[ir],sizeof(float),1,pzfp);

        }

     }





     /* ASCII output for x_vgx

     if(ascci ==1 && vgxout ==1){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(vgxfp,"0.000000	0.000000\n",xdata[ir],vgxdata[ir]);

     /* Binary output for x_vgx

     } else if(ascci ==0 && vgxout ==1){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&vgxdata[ir],sizeof(float),1,vgxfp);

	    fwrite(&xdata[ir],sizeof(float),1,vgxfp);

        }

     }





     /* ASCII output for x_vgz

     if(ascci ==1 && vgzout ==1){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(vgzfp,"0.000000	0.000000\n",xdata[ir],vgzdata[ir]);

     /* Binary output for x_vgz

     } else if(ascci ==0 && vgzout ==1){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&vgzdata[ir],sizeof(float),1,vgzfp);

	    fwrite(&xdata[ir],sizeof(float),1,vgzfp);

        }

     }

     /* ASCII output for px_vgx

     if(ascci == 1 && pxvxout != 0){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(pxvxfp,"0.000000	0.000000\n",pxdata[ir],vgxdata[ir]);

     /* Binary output for px_vgx

     } else if(ascci ==0 && pxvxout != 0){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&pxdata[ir],sizeof(float),1,pxvxfp);

	    fwrite(&vgxdata[ir],sizeof(float),1,pxvxfp);

        }

     }



     /* ASCII output for px_vgx

     if(ascci == 1 && polout != 0){

        for(ir=0;ir<nri;ir+=1)

	    fprintf(polfp,"0.000000	0.000000\n",xdata[ir],poldata[ir]);

     /* Binary output for px_vgx

     } else if(ascci ==0 && polout != 0){

        for(ir=0;ir<nri;ir+=1){

	    fwrite(&xdata[ir],sizeof(float),1,polfp);

	    fwrite(&poldata[ir],sizeof(float),1,polfp);

        }

     }





     if(!ascci) fprintf(outparfp,"0\n",nri);

	return EXIT_FAILURE;

	

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

my $raydata			= {
	_ascci					=> '',
	_g11data					=> '',
	_g13data					=> '',
	_g33data					=> '',
	_ir					=> '',
	_iri					=> '',
	_kend					=> '',
	_nre					=> '',
	_nrealloc					=> '',
	_nri					=> '',
	_outparfp					=> '',
	_pol					=> '',
	_poldata					=> '',
	_polfp					=> '',
	_polout					=> '',
	_px					=> '',
	_pxdata					=> '',
	_pxfp					=> '',
	_pxout					=> '',
	_pxvx					=> '',
	_pxvxdata					=> '',
	_pxvxfp					=> '',
	_pxvxout					=> '',
	_pz					=> '',
	_pzdata					=> '',
	_pzfp					=> '',
	_pzout					=> '',
	_re					=> '',
	_t					=> '',
	_tdata					=> '',
	_tout					=> '',
	_txfp					=> '',
	_vgx					=> '',
	_vgxdata					=> '',
	_vgxfp					=> '',
	_vgxout					=> '',
	_vgz					=> '',
	_vgzdata					=> '',
	_vgzfp					=> '',
	_vgzout					=> '',
	_xdata					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$raydata->{_Step}     = 'raydata'.$raydata->{_Step};
	return ( $raydata->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$raydata->{_note}     = 'raydata'.$raydata->{_note};
	return ( $raydata->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$raydata->{_ascci}			= '';
		$raydata->{_g11data}			= '';
		$raydata->{_g13data}			= '';
		$raydata->{_g33data}			= '';
		$raydata->{_ir}			= '';
		$raydata->{_iri}			= '';
		$raydata->{_kend}			= '';
		$raydata->{_nre}			= '';
		$raydata->{_nrealloc}			= '';
		$raydata->{_nri}			= '';
		$raydata->{_outparfp}			= '';
		$raydata->{_pol}			= '';
		$raydata->{_poldata}			= '';
		$raydata->{_polfp}			= '';
		$raydata->{_polout}			= '';
		$raydata->{_px}			= '';
		$raydata->{_pxdata}			= '';
		$raydata->{_pxfp}			= '';
		$raydata->{_pxout}			= '';
		$raydata->{_pxvx}			= '';
		$raydata->{_pxvxdata}			= '';
		$raydata->{_pxvxfp}			= '';
		$raydata->{_pxvxout}			= '';
		$raydata->{_pz}			= '';
		$raydata->{_pzdata}			= '';
		$raydata->{_pzfp}			= '';
		$raydata->{_pzout}			= '';
		$raydata->{_re}			= '';
		$raydata->{_t}			= '';
		$raydata->{_tdata}			= '';
		$raydata->{_tout}			= '';
		$raydata->{_txfp}			= '';
		$raydata->{_vgx}			= '';
		$raydata->{_vgxdata}			= '';
		$raydata->{_vgxfp}			= '';
		$raydata->{_vgxout}			= '';
		$raydata->{_vgz}			= '';
		$raydata->{_vgzdata}			= '';
		$raydata->{_vgzfp}			= '';
		$raydata->{_vgzout}			= '';
		$raydata->{_xdata}			= '';
		$raydata->{_Step}			= '';
		$raydata->{_note}			= '';
 }


=head2 sub ascci 


=cut

 sub ascci {

	my ( $self,$ascci )		= @_;
	if ( $ascci ne $empty_string ) {

		$raydata->{_ascci}		= $ascci;
		$raydata->{_note}		= $raydata->{_note}.' ascci='.$raydata->{_ascci};
		$raydata->{_Step}		= $raydata->{_Step}.' ascci='.$raydata->{_ascci};

	} else { 
		print("raydata, ascci, missing ascci,\n");
	 }
 }


=head2 sub g11data 


=cut

 sub g11data {

	my ( $self,$g11data )		= @_;
	if ( $g11data ne $empty_string ) {

		$raydata->{_g11data}		= $g11data;
		$raydata->{_note}		= $raydata->{_note}.' g11data='.$raydata->{_g11data};
		$raydata->{_Step}		= $raydata->{_Step}.' g11data='.$raydata->{_g11data};

	} else { 
		print("raydata, g11data, missing g11data,\n");
	 }
 }


=head2 sub g13data 


=cut

 sub g13data {

	my ( $self,$g13data )		= @_;
	if ( $g13data ne $empty_string ) {

		$raydata->{_g13data}		= $g13data;
		$raydata->{_note}		= $raydata->{_note}.' g13data='.$raydata->{_g13data};
		$raydata->{_Step}		= $raydata->{_Step}.' g13data='.$raydata->{_g13data};

	} else { 
		print("raydata, g13data, missing g13data,\n");
	 }
 }


=head2 sub g33data 


=cut

 sub g33data {

	my ( $self,$g33data )		= @_;
	if ( $g33data ne $empty_string ) {

		$raydata->{_g33data}		= $g33data;
		$raydata->{_note}		= $raydata->{_note}.' g33data='.$raydata->{_g33data};
		$raydata->{_Step}		= $raydata->{_Step}.' g33data='.$raydata->{_g33data};

	} else { 
		print("raydata, g33data, missing g33data,\n");
	 }
 }


=head2 sub ir 


=cut

 sub ir {

	my ( $self,$ir )		= @_;
	if ( $ir ne $empty_string ) {

		$raydata->{_ir}		= $ir;
		$raydata->{_note}		= $raydata->{_note}.' ir='.$raydata->{_ir};
		$raydata->{_Step}		= $raydata->{_Step}.' ir='.$raydata->{_ir};

	} else { 
		print("raydata, ir, missing ir,\n");
	 }
 }


=head2 sub iri 


=cut

 sub iri {

	my ( $self,$iri )		= @_;
	if ( $iri ne $empty_string ) {

		$raydata->{_iri}		= $iri;
		$raydata->{_note}		= $raydata->{_note}.' iri='.$raydata->{_iri};
		$raydata->{_Step}		= $raydata->{_Step}.' iri='.$raydata->{_iri};

	} else { 
		print("raydata, iri, missing iri,\n");
	 }
 }


=head2 sub kend 


=cut

 sub kend {

	my ( $self,$kend )		= @_;
	if ( $kend ne $empty_string ) {

		$raydata->{_kend}		= $kend;
		$raydata->{_note}		= $raydata->{_note}.' kend='.$raydata->{_kend};
		$raydata->{_Step}		= $raydata->{_Step}.' kend='.$raydata->{_kend};

	} else { 
		print("raydata, kend, missing kend,\n");
	 }
 }


=head2 sub nre 


=cut

 sub nre {

	my ( $self,$nre )		= @_;
	if ( $nre ne $empty_string ) {

		$raydata->{_nre}		= $nre;
		$raydata->{_note}		= $raydata->{_note}.' nre='.$raydata->{_nre};
		$raydata->{_Step}		= $raydata->{_Step}.' nre='.$raydata->{_nre};

	} else { 
		print("raydata, nre, missing nre,\n");
	 }
 }


=head2 sub nrealloc 


=cut

 sub nrealloc {

	my ( $self,$nrealloc )		= @_;
	if ( $nrealloc ne $empty_string ) {

		$raydata->{_nrealloc}		= $nrealloc;
		$raydata->{_note}		= $raydata->{_note}.' nrealloc='.$raydata->{_nrealloc};
		$raydata->{_Step}		= $raydata->{_Step}.' nrealloc='.$raydata->{_nrealloc};

	} else { 
		print("raydata, nrealloc, missing nrealloc,\n");
	 }
 }


=head2 sub nri 


=cut

 sub nri {

	my ( $self,$nri )		= @_;
	if ( $nri ne $empty_string ) {

		$raydata->{_nri}		= $nri;
		$raydata->{_note}		= $raydata->{_note}.' nri='.$raydata->{_nri};
		$raydata->{_Step}		= $raydata->{_Step}.' nri='.$raydata->{_nri};

	} else { 
		print("raydata, nri, missing nri,\n");
	 }
 }


=head2 sub outparfp 


=cut

 sub outparfp {

	my ( $self,$outparfp )		= @_;
	if ( $outparfp ne $empty_string ) {

		$raydata->{_outparfp}		= $outparfp;
		$raydata->{_note}		= $raydata->{_note}.' outparfp='.$raydata->{_outparfp};
		$raydata->{_Step}		= $raydata->{_Step}.' outparfp='.$raydata->{_outparfp};

	} else { 
		print("raydata, outparfp, missing outparfp,\n");
	 }
 }


=head2 sub pol 


=cut

 sub pol {

	my ( $self,$pol )		= @_;
	if ( $pol ne $empty_string ) {

		$raydata->{_pol}		= $pol;
		$raydata->{_note}		= $raydata->{_note}.' pol='.$raydata->{_pol};
		$raydata->{_Step}		= $raydata->{_Step}.' pol='.$raydata->{_pol};

	} else { 
		print("raydata, pol, missing pol,\n");
	 }
 }


=head2 sub poldata 


=cut

 sub poldata {

	my ( $self,$poldata )		= @_;
	if ( $poldata ne $empty_string ) {

		$raydata->{_poldata}		= $poldata;
		$raydata->{_note}		= $raydata->{_note}.' poldata='.$raydata->{_poldata};
		$raydata->{_Step}		= $raydata->{_Step}.' poldata='.$raydata->{_poldata};

	} else { 
		print("raydata, poldata, missing poldata,\n");
	 }
 }


=head2 sub polfp 


=cut

 sub polfp {

	my ( $self,$polfp )		= @_;
	if ( $polfp ne $empty_string ) {

		$raydata->{_polfp}		= $polfp;
		$raydata->{_note}		= $raydata->{_note}.' polfp='.$raydata->{_polfp};
		$raydata->{_Step}		= $raydata->{_Step}.' polfp='.$raydata->{_polfp};

	} else { 
		print("raydata, polfp, missing polfp,\n");
	 }
 }


=head2 sub polout 


=cut

 sub polout {

	my ( $self,$polout )		= @_;
	if ( $polout ne $empty_string ) {

		$raydata->{_polout}		= $polout;
		$raydata->{_note}		= $raydata->{_note}.' polout='.$raydata->{_polout};
		$raydata->{_Step}		= $raydata->{_Step}.' polout='.$raydata->{_polout};

	} else { 
		print("raydata, polout, missing polout,\n");
	 }
 }


=head2 sub px 


=cut

 sub px {

	my ( $self,$px )		= @_;
	if ( $px ne $empty_string ) {

		$raydata->{_px}		= $px;
		$raydata->{_note}		= $raydata->{_note}.' px='.$raydata->{_px};
		$raydata->{_Step}		= $raydata->{_Step}.' px='.$raydata->{_px};

	} else { 
		print("raydata, px, missing px,\n");
	 }
 }


=head2 sub pxdata 


=cut

 sub pxdata {

	my ( $self,$pxdata )		= @_;
	if ( $pxdata ne $empty_string ) {

		$raydata->{_pxdata}		= $pxdata;
		$raydata->{_note}		= $raydata->{_note}.' pxdata='.$raydata->{_pxdata};
		$raydata->{_Step}		= $raydata->{_Step}.' pxdata='.$raydata->{_pxdata};

	} else { 
		print("raydata, pxdata, missing pxdata,\n");
	 }
 }


=head2 sub pxfp 


=cut

 sub pxfp {

	my ( $self,$pxfp )		= @_;
	if ( $pxfp ne $empty_string ) {

		$raydata->{_pxfp}		= $pxfp;
		$raydata->{_note}		= $raydata->{_note}.' pxfp='.$raydata->{_pxfp};
		$raydata->{_Step}		= $raydata->{_Step}.' pxfp='.$raydata->{_pxfp};

	} else { 
		print("raydata, pxfp, missing pxfp,\n");
	 }
 }


=head2 sub pxout 


=cut

 sub pxout {

	my ( $self,$pxout )		= @_;
	if ( $pxout ne $empty_string ) {

		$raydata->{_pxout}		= $pxout;
		$raydata->{_note}		= $raydata->{_note}.' pxout='.$raydata->{_pxout};
		$raydata->{_Step}		= $raydata->{_Step}.' pxout='.$raydata->{_pxout};

	} else { 
		print("raydata, pxout, missing pxout,\n");
	 }
 }


=head2 sub pxvx 


=cut

 sub pxvx {

	my ( $self,$pxvx )		= @_;
	if ( $pxvx ne $empty_string ) {

		$raydata->{_pxvx}		= $pxvx;
		$raydata->{_note}		= $raydata->{_note}.' pxvx='.$raydata->{_pxvx};
		$raydata->{_Step}		= $raydata->{_Step}.' pxvx='.$raydata->{_pxvx};

	} else { 
		print("raydata, pxvx, missing pxvx,\n");
	 }
 }


=head2 sub pxvxdata 


=cut

 sub pxvxdata {

	my ( $self,$pxvxdata )		= @_;
	if ( $pxvxdata ne $empty_string ) {

		$raydata->{_pxvxdata}		= $pxvxdata;
		$raydata->{_note}		= $raydata->{_note}.' pxvxdata='.$raydata->{_pxvxdata};
		$raydata->{_Step}		= $raydata->{_Step}.' pxvxdata='.$raydata->{_pxvxdata};

	} else { 
		print("raydata, pxvxdata, missing pxvxdata,\n");
	 }
 }


=head2 sub pxvxfp 


=cut

 sub pxvxfp {

	my ( $self,$pxvxfp )		= @_;
	if ( $pxvxfp ne $empty_string ) {

		$raydata->{_pxvxfp}		= $pxvxfp;
		$raydata->{_note}		= $raydata->{_note}.' pxvxfp='.$raydata->{_pxvxfp};
		$raydata->{_Step}		= $raydata->{_Step}.' pxvxfp='.$raydata->{_pxvxfp};

	} else { 
		print("raydata, pxvxfp, missing pxvxfp,\n");
	 }
 }


=head2 sub pxvxout 


=cut

 sub pxvxout {

	my ( $self,$pxvxout )		= @_;
	if ( $pxvxout ne $empty_string ) {

		$raydata->{_pxvxout}		= $pxvxout;
		$raydata->{_note}		= $raydata->{_note}.' pxvxout='.$raydata->{_pxvxout};
		$raydata->{_Step}		= $raydata->{_Step}.' pxvxout='.$raydata->{_pxvxout};

	} else { 
		print("raydata, pxvxout, missing pxvxout,\n");
	 }
 }


=head2 sub pz 


=cut

 sub pz {

	my ( $self,$pz )		= @_;
	if ( $pz ne $empty_string ) {

		$raydata->{_pz}		= $pz;
		$raydata->{_note}		= $raydata->{_note}.' pz='.$raydata->{_pz};
		$raydata->{_Step}		= $raydata->{_Step}.' pz='.$raydata->{_pz};

	} else { 
		print("raydata, pz, missing pz,\n");
	 }
 }


=head2 sub pzdata 


=cut

 sub pzdata {

	my ( $self,$pzdata )		= @_;
	if ( $pzdata ne $empty_string ) {

		$raydata->{_pzdata}		= $pzdata;
		$raydata->{_note}		= $raydata->{_note}.' pzdata='.$raydata->{_pzdata};
		$raydata->{_Step}		= $raydata->{_Step}.' pzdata='.$raydata->{_pzdata};

	} else { 
		print("raydata, pzdata, missing pzdata,\n");
	 }
 }


=head2 sub pzfp 


=cut

 sub pzfp {

	my ( $self,$pzfp )		= @_;
	if ( $pzfp ne $empty_string ) {

		$raydata->{_pzfp}		= $pzfp;
		$raydata->{_note}		= $raydata->{_note}.' pzfp='.$raydata->{_pzfp};
		$raydata->{_Step}		= $raydata->{_Step}.' pzfp='.$raydata->{_pzfp};

	} else { 
		print("raydata, pzfp, missing pzfp,\n");
	 }
 }


=head2 sub pzout 


=cut

 sub pzout {

	my ( $self,$pzout )		= @_;
	if ( $pzout ne $empty_string ) {

		$raydata->{_pzout}		= $pzout;
		$raydata->{_note}		= $raydata->{_note}.' pzout='.$raydata->{_pzout};
		$raydata->{_Step}		= $raydata->{_Step}.' pzout='.$raydata->{_pzout};

	} else { 
		print("raydata, pzout, missing pzout,\n");
	 }
 }


=head2 sub re 


=cut

 sub re {

	my ( $self,$re )		= @_;
	if ( $re ne $empty_string ) {

		$raydata->{_re}		= $re;
		$raydata->{_note}		= $raydata->{_note}.' re='.$raydata->{_re};
		$raydata->{_Step}		= $raydata->{_Step}.' re='.$raydata->{_re};

	} else { 
		print("raydata, re, missing re,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$raydata->{_t}		= $t;
		$raydata->{_note}		= $raydata->{_note}.' t='.$raydata->{_t};
		$raydata->{_Step}		= $raydata->{_Step}.' t='.$raydata->{_t};

	} else { 
		print("raydata, t, missing t,\n");
	 }
 }


=head2 sub tdata 


=cut

 sub tdata {

	my ( $self,$tdata )		= @_;
	if ( $tdata ne $empty_string ) {

		$raydata->{_tdata}		= $tdata;
		$raydata->{_note}		= $raydata->{_note}.' tdata='.$raydata->{_tdata};
		$raydata->{_Step}		= $raydata->{_Step}.' tdata='.$raydata->{_tdata};

	} else { 
		print("raydata, tdata, missing tdata,\n");
	 }
 }


=head2 sub tout 


=cut

 sub tout {

	my ( $self,$tout )		= @_;
	if ( $tout ne $empty_string ) {

		$raydata->{_tout}		= $tout;
		$raydata->{_note}		= $raydata->{_note}.' tout='.$raydata->{_tout};
		$raydata->{_Step}		= $raydata->{_Step}.' tout='.$raydata->{_tout};

	} else { 
		print("raydata, tout, missing tout,\n");
	 }
 }


=head2 sub txfp 


=cut

 sub txfp {

	my ( $self,$txfp )		= @_;
	if ( $txfp ne $empty_string ) {

		$raydata->{_txfp}		= $txfp;
		$raydata->{_note}		= $raydata->{_note}.' txfp='.$raydata->{_txfp};
		$raydata->{_Step}		= $raydata->{_Step}.' txfp='.$raydata->{_txfp};

	} else { 
		print("raydata, txfp, missing txfp,\n");
	 }
 }


=head2 sub vgx 


=cut

 sub vgx {

	my ( $self,$vgx )		= @_;
	if ( $vgx ne $empty_string ) {

		$raydata->{_vgx}		= $vgx;
		$raydata->{_note}		= $raydata->{_note}.' vgx='.$raydata->{_vgx};
		$raydata->{_Step}		= $raydata->{_Step}.' vgx='.$raydata->{_vgx};

	} else { 
		print("raydata, vgx, missing vgx,\n");
	 }
 }


=head2 sub vgxdata 


=cut

 sub vgxdata {

	my ( $self,$vgxdata )		= @_;
	if ( $vgxdata ne $empty_string ) {

		$raydata->{_vgxdata}		= $vgxdata;
		$raydata->{_note}		= $raydata->{_note}.' vgxdata='.$raydata->{_vgxdata};
		$raydata->{_Step}		= $raydata->{_Step}.' vgxdata='.$raydata->{_vgxdata};

	} else { 
		print("raydata, vgxdata, missing vgxdata,\n");
	 }
 }


=head2 sub vgxfp 


=cut

 sub vgxfp {

	my ( $self,$vgxfp )		= @_;
	if ( $vgxfp ne $empty_string ) {

		$raydata->{_vgxfp}		= $vgxfp;
		$raydata->{_note}		= $raydata->{_note}.' vgxfp='.$raydata->{_vgxfp};
		$raydata->{_Step}		= $raydata->{_Step}.' vgxfp='.$raydata->{_vgxfp};

	} else { 
		print("raydata, vgxfp, missing vgxfp,\n");
	 }
 }


=head2 sub vgxout 


=cut

 sub vgxout {

	my ( $self,$vgxout )		= @_;
	if ( $vgxout ne $empty_string ) {

		$raydata->{_vgxout}		= $vgxout;
		$raydata->{_note}		= $raydata->{_note}.' vgxout='.$raydata->{_vgxout};
		$raydata->{_Step}		= $raydata->{_Step}.' vgxout='.$raydata->{_vgxout};

	} else { 
		print("raydata, vgxout, missing vgxout,\n");
	 }
 }


=head2 sub vgz 


=cut

 sub vgz {

	my ( $self,$vgz )		= @_;
	if ( $vgz ne $empty_string ) {

		$raydata->{_vgz}		= $vgz;
		$raydata->{_note}		= $raydata->{_note}.' vgz='.$raydata->{_vgz};
		$raydata->{_Step}		= $raydata->{_Step}.' vgz='.$raydata->{_vgz};

	} else { 
		print("raydata, vgz, missing vgz,\n");
	 }
 }


=head2 sub vgzdata 


=cut

 sub vgzdata {

	my ( $self,$vgzdata )		= @_;
	if ( $vgzdata ne $empty_string ) {

		$raydata->{_vgzdata}		= $vgzdata;
		$raydata->{_note}		= $raydata->{_note}.' vgzdata='.$raydata->{_vgzdata};
		$raydata->{_Step}		= $raydata->{_Step}.' vgzdata='.$raydata->{_vgzdata};

	} else { 
		print("raydata, vgzdata, missing vgzdata,\n");
	 }
 }


=head2 sub vgzfp 


=cut

 sub vgzfp {

	my ( $self,$vgzfp )		= @_;
	if ( $vgzfp ne $empty_string ) {

		$raydata->{_vgzfp}		= $vgzfp;
		$raydata->{_note}		= $raydata->{_note}.' vgzfp='.$raydata->{_vgzfp};
		$raydata->{_Step}		= $raydata->{_Step}.' vgzfp='.$raydata->{_vgzfp};

	} else { 
		print("raydata, vgzfp, missing vgzfp,\n");
	 }
 }


=head2 sub vgzout 


=cut

 sub vgzout {

	my ( $self,$vgzout )		= @_;
	if ( $vgzout ne $empty_string ) {

		$raydata->{_vgzout}		= $vgzout;
		$raydata->{_note}		= $raydata->{_note}.' vgzout='.$raydata->{_vgzout};
		$raydata->{_Step}		= $raydata->{_Step}.' vgzout='.$raydata->{_vgzout};

	} else { 
		print("raydata, vgzout, missing vgzout,\n");
	 }
 }


=head2 sub xdata 


=cut

 sub xdata {

	my ( $self,$xdata )		= @_;
	if ( $xdata ne $empty_string ) {

		$raydata->{_xdata}		= $xdata;
		$raydata->{_note}		= $raydata->{_note}.' xdata='.$raydata->{_xdata};
		$raydata->{_Step}		= $raydata->{_Step}.' xdata='.$raydata->{_xdata};

	} else { 
		print("raydata, xdata, missing xdata,\n");
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
