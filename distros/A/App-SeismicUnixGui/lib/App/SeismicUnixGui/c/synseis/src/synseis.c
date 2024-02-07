/* program to create simple synthetic seismogams in 1-D
   using the convolutional filter approach.  No attenuation,
   spherical divergence, or internal multiples are calculated  */
/*
  include files
  */
#include <stdio.h> /*standard i/o */
#include <math.h>
#include <stdlib.h>

/*default values*/
#define SIZE 5000/*array length*/
#define FALSE 0
#define FILE_SIZE 50 /*array length for file*/
#define T_INCREMENT 0.001/*default resampling increment in seconds*/
/*#define THRESHOLD 1000. threshold for RC going to 0*/
/* #define TINT 0.001 sampling interval in seconds*/
#define TRUE 1
#define XSTART 0.0 /* o/p for first x value in resampling */
#define TSTART 0.0/* o/p for first t value in resampling */
#define Z_INCREMENT 0.25 /* default resampling increment in m*/
#define ZSTART 0.0 /* o/p for first z value in resampling */
#define Vp_water_mps 1500. /* velocity of sound in salt water at 0 deg C */
#define rho_water_gcc 1.035  /* density of salt water at 0 deg C */

/* internal functions at the end of this source file */
double ricker();
void regular();
void convolve();

/* reads in switches */
int main (int argc, char **argv)
{
  /* Varibale pre-definitions*/
  float
    /*special counters*/
    A, subtract,/*t,individual t and Amplitude values*/
    wint [SIZE],  /* i/p wavelet in time*/
    winA [SIZE],  /*  i/p wavelet Amplitude*/
    winA_reg [SIZE], wint_reg, /* regularized i/p wavelet Amplitude*/
    Refl_coef_reg_depth[SIZE], /*regularized reflection coefficient series in depth*/
    Refl_coef_reg_time[SIZE], /* regularized reflection coefficients in time*/
    /* RC [SIZE], regularized reflection coefficient */
    depth[SIZE], depth_reg [SIZE], /* depth measurements*/
    rho [SIZE], rho_reg [SIZE], /*density in g/cc*/
    time[SIZE], time_reg,/* first step in converting depth to time*/
    tmin, /*min time value for stout synthetic seismogram*/
    Vp [SIZE],  Vp_reg [SIZE], /*velocity in m/s*/
    Convolve_Amplitude[SIZE], Convolve_time, /*convolved output trace*/
    top_imp, bottom_imp,water_imp, upper_half_space_imp, /*impedances*/
    min_time, max_time, expected_num_of_t_samples,time_non_reg[SIZE], 
    water_depth, /*water depth in meters*/
    t_increment, /*xincrement for regularization*/
    xstart, /* first x value at which to start regularizing*/
	tstart,/*first t value at which to start regularizing*/
    /*xint, regularized x value*/
    d,r,v,  /*depth, density and velocity values*/
    Ricker_time[SIZE],  /*time array for Ricker wavelet*/
    Ricker_Amplitude[SIZE], /*amplitude array for RIcker wavelet*/
    /*threshold,   threshold value below which RC are = 0 threshold is a proportion of the RC at sea floor)*/
    z_increment, /*zincrement for regularization in depth (m)*/
    zstart; /* first zvalue at which to start regularizing*/

  double
    freq, rick_long, td,l,/* dominant frequency (Hz) and length of  wavelet (s)*/
    SI; /*sampling interval in s*/

  char
    *source_filename,    /*input source file name */
    *Ricker_filnam, /*output  filename of Ricker wavelet source*/
    *reg_source_filnam,  /*regularized output filename of source wavelet */
    *zrhov_filename, /*input file with log data as depth (m),& velocity (m/s)*/
    *Refl_coef_reg_depth_filnam,
    *Refl_coef_reg_time_filnam,
    *Reg_rho_filnam,
    *Reg_Vp_filnam;

  int
    i,j,t,error = FALSE,
    /*num_pts, number of points in array*/
    num_pts_conv, /*number of points in convolved array=num_src+num_refl_coef*/
    num_pts_src, /* counters*/
    num_samples_Ricker, /*number of samples in source*/
    num_pts_log, /* number of points in log*/
    num_pts_reg,  /* number of points in regularized source*/
    num_pts_rho_reg,  /* number of points in regularized log*/
    num_pts_Vp_reg,  /* number of points in regularized log*/
    num_pts_log_reg,  /* number of points in regularized log*/
	num_pts_rc_reg_time,/* number of points in regularized rc time series */
	/*num_pts_rc_reg_depth number of points in regularized rc depth series*/
    read_source = FALSE,
    reg_rho_out = FALSE,
    reg_Vp_out = FALSE,
    resample_source = FALSE,
    reflec_coef_reg_depth_out  = FALSE,
    reflec_coef_reg_time_out = FALSE,
    source_file_out  = FALSE,
    verbose = FALSE,
    ricker_wavelet = FALSE,
    ricker_out = FALSE;

  FILE *fpin, *fpout;

  /* intitialize variables*/
  source_filename = 0;
  Reg_rho_filnam = 0;
  Reg_Vp_filnam = 0;
  reg_source_filnam = 0;
  zrhov_filename = 0;
  Ricker_filnam = 0;
  i = 0;
  /*num_pts = 0;*/
  num_pts_src = 0;
  num_samples_Ricker = 0;
  num_pts_reg = 0;
  num_pts_log = 0;
  num_pts_log_reg = 0;
  num_pts_rho_reg = 0;
  num_pts_rc_reg_time = 0;
  /*num_pts_rc_reg_depth = 0;*/
  num_pts_Vp_reg = 0;

  /*threshold = (float)THRESHOLD; default of 1000 */
  t_increment = (float)T_INCREMENT; /*default of 0.001 s*/
/*   printf ("tincrement= %f\n",t_increment);*/

  xstart = (float)XSTART; /*default of 0.0 */
  tstart  = (float)TSTART;/*default of 0.0 */
  z_increment = (float)Z_INCREMENT; /*default of 0.25 m */
  zstart = (float)ZSTART; /*default of 0.0 */

 /* getting values from command line input */
  for (i=1; !error && i < argc; i++) {
    if (argv[i][0] == '-') {
      switch (argv[i][1]) {

      case 'A': /*-A Ricker wavelet*/
    	  ricker_wavelet = TRUE;

			if (argv[i][2] == 'F' ) { /*-AF frequency of Ricker wavelet*/
	  			freq = atof(&argv[i][3]);
			}
			if (argv[i][2] == 'E') { /*-AE end time of ricker wavelet */
	  			rick_long  = atof(&argv[i][3]);
			}
			if (argv[i][2] == 'o') { /*-Ao ricker file out*/
			  ricker_out = TRUE;
			  Ricker_filnam = &argv[i][3];
			}
			/*	printf("%s ricker wavelet=",ricker_wavelet);*/
		break;

      	case 'C': /*-Creflection coefficients*/
			if (argv[i][2]== 'Z') { /*-CZ reflect. coef. in depth */
			  reflec_coef_reg_depth_out  = TRUE;
			  Refl_coef_reg_depth_filnam = &argv[i][3];
			}
			if (argv[i][2]== 'T') { /*-CT reflect. coef. in time */
			  reflec_coef_reg_time_out = TRUE;
			  Refl_coef_reg_time_filnam = &argv[i][3];
			}
		break;

		case 'I': /*sampling interval*/
			if (argv[i][2]== 'Z') {
				/* does not work under linux
			  z2_increment = (float)atof(&argv[i][3]); depth sampling interval*/
				sscanf (&argv[i][3],"%f",&z_increment);
			}
			else {
				/* doesn't work under linux
		 	 	 t_increment = (float)atof(&argv[i][2]); general sampling interval
				 */
			  sscanf (&argv[i][2],"%f",&t_increment);
			  SI = t_increment;     /*sampling interval(s) for Ricker wavelet*/
			}
		break;

		case 'L': /*L resampled log values out */
			if (argv[i][2]== 'D') {  /*-RD resampled density file name out*/
			  reg_rho_out = TRUE;
			  Reg_rho_filnam = &argv[i][3];
			}
			if (argv[i][2]== 'V') {  /*-RV resampled Vp file name out*/
			  reg_Vp_out = TRUE;
			  Reg_Vp_filnam = &argv[i][3];
			}
		break;

		case 'R': /*-R resampling source*/
			if (argv[i][2]== 'o') {
			  source_file_out = TRUE;/*-Ro source file name out not resampled
						  within program resample_source = FALSE*/
			  reg_source_filnam = &argv[i][3];
			}
			else {
			  resample_source = TRUE;
			  	/*	  t_increment = (float)atof(&argv[i][2]);*/
			}
		break;

		case 'S': /*-Ssource file name*/
			read_source = TRUE;
			source_filename = &argv[i][2];
			resample_source = FALSE;
			if( verbose == TRUE ) {
		          printf("%s\n",source_filename);
			}
		break;

		case 'V': /*-V verbose*/
			  verbose = TRUE;
			  if( verbose == TRUE ) {
		          printf("%s\n",zrhov_filename);
			  }
		break;

		case 'W': /*water depth*/
			sscanf (&argv[i][2],"%f",&water_depth);
			/* not like by linux
			  water_depth=(float)atof(&argv[i][2]);*/
		break;

		case 'X': /* -X0 t0 for resampling source */
			if (argv[i][2]== '0') {
				sscanf (&argv[i][3],"%f",&xstart); /*default=0.0*/
				/* doesn't work in linux*/
				/* 	xstart = (float)atof(&argv[i][3]);defaullt 0 */
			}
		break;

		case 'Z': /*-Zdepth-density-velocityfile name*/
					zrhov_filename = &argv[i][2];
		break;
	   }	/*switch*/
    } /* end '-' */
  } /* end for */

  if( verbose == TRUE ) printf("%s\n",zrhov_filename);
  if( verbose == TRUE ) printf("t_increment= %f\n",t_increment);
  if( verbose == TRUE ) printf("z_increment =%f\n",z_increment);
  if( verbose == TRUE ) printf("water_depth =%f\n",water_depth);
  if( verbose == TRUE ) printf("source_filname =%s\n",source_filename);

/*  if (argc == 1 || error ) { */
/*    fprintf (stderr, " -AFfrequency of Ricker wavelet(Hz)\n"); */
/*    fprintf (stderr, " -AElength of ricker wavelet in secs\n"); */
/*    fprintf (stderr, " -Aoname of output ricker wavelet file if wanted\n");*/
/*    fprintf (stderr, " -CZoutput file with depth, refle. coef. pairs*\n"); */
/*    fprintf (stderr, " -CToutput file with time, reflec. coef. pairs*\n");*/
/*    fprintf (stderr, " -Isampling interval (s)*\n");*/
/*    fprintf (stderr, " -IZsampling interval in depth (m)*\n");*/
/*    fprintf (stderr, " -LDresampled log density filename*\n");*/
/*    fprintf (stderr, " -LVresampled velocity filename*\n");*/
/*    fprintf (stderr, " -Roresampled output source filename*\n");*/
/*    fprintf (stderr, " -Rresample source=TRUE, otherwise don't resample\n");*/
/*    fprintf (stderr, " -Ssource_file_name (resampling=FALSE)\n");*/
/*    fprintf (stderr, " -Vspill all the details of the modelin\n");*/
/*    fprintf (stderr, " -Zname of file with depth(mbsf),density(g/cc),velocity(m/s)*\n");*/
/*    fprintf (stderr, "\n\n\n\n\n * ALWAYS USE\n");*/
/* */
/*  } */

  /*DATA INPUT */

  /*SOURCE IN A FILE */
  /* read source file*/
if(read_source == TRUE) {

	if(  (fpin = fopen(source_filename,"r") ) == NULL) {
		printf("Can't open file1 %s, try again\n", source_filename);
		exit(0);
	}

     /*RESAMPLE SOURCE*/
	if(resample_source == TRUE) {
		for(i=0, num_pts_src=0; (!feof(fpin));  i++, num_pts_src++) {
			fscanf (fpin, "%d %f", &t, &A);
			/*wint[i] = t;*/
			wint[i] = (float)t * t_increment; /*TINT;default 1 ms Sample Interval*/
			winA[i] = A;
		}
		fclose(fpin);
	}

    /* DO NOT RESAMPLE SOURCE */
    if(resample_source == FALSE) {
    	for(i=0, num_pts_src=0; (!feof(fpin));  i++, num_pts_src++) {
    		fscanf (fpin, "%f\n", &A); /* N.B. only amplitudes */
    		winA_reg[i] = A;
    		/*	printf(" amplitude from file= %f\n",winA_reg[i]); */
    	}
    	fclose(fpin);
    	num_pts_reg = num_pts_src;
    	xstart = (float)XSTART; /* XSTART default = 0.0 */
    	/*t_increment = (float)TINT; TINT=0.001 s */

    	if(verbose == TRUE) {
    		printf("For source resampled before i/p \n");
    		printf("t_increment= %f  xstart= %f counter= %f\n",t_increment, xstart,(float)1);

    		for(i=0; i< num_pts_reg; i++) {
    			wint_reg = xstart + (float)i* t_increment;
    			printf("t= %f  A= %f\n",wint_reg, winA_reg[i]);
    		}
    	}
    	/*      t_increment = wint[1] - wint[0]; only amplitudes here
	      if(verbose == TRUE) printf("t_increment=%f\n",t_increment);
	      if(T_INCREMENT != t_increment) printf("t_increment warning\n");*/
	} /* END of DO NOT RESAMPLE SOURCE */

/*resample source */
    if(resample_source == TRUE) {
    	/*regularize source here*/
    	if(verbose == TRUE) printf("    time,      Amplitude\n");
    	subtract = wint[0];
    	for(i=0; i< num_pts_src; i++) {
    		wint[i] = wint[i] - subtract; /* make xstart = 0*/
    		if(verbose == TRUE) printf("%f,      %f\n",wint[i],winA[i]);
    	}
    	regular(xstart, t_increment, num_pts_src,
	      &num_pts_reg, winA, wint, winA_reg); /*xstart from stdin*/

    	if(verbose == TRUE){
    		printf("  time,     Amplitude,num_pts_reg = %d\n", num_pts_reg);
    	}

    	for ( i=0;  i< num_pts_reg;  i++) {
    		wint_reg = xstart + i* t_increment;
    		if(verbose == TRUE) printf("%f,      %f\n",wint_reg, winA_reg[i]);
    	}
    }

    if(source_file_out == TRUE){
      fpout= fopen(reg_source_filnam,"w");
      /*	fprintf(fpout," time(s),      Amplitude\n");*/
      for (i=0;  i< num_pts_reg;  i++){
	wint_reg = xstart + (float)i* t_increment;
	fprintf(fpout,"%f\t%f\n",wint_reg, winA_reg[i]);
      }
      fclose(fpout);
    }
} /* END of SOURCE IN A FILE */

/*RICKER WAVELET -------------------START-----------------*/
if(ricker_wavelet == TRUE) {

    if( verbose == TRUE) printf("Calculating with a Ricker source\n");
    num_samples_Ricker = (int)(rick_long /SI)+ 1;

    if (verbose == TRUE) {
    	printf("  L346 Ricker wavelet\n time,      Amplitude\n");
    	printf("%lf %lf %lf %d\n", freq, SI, rick_long, num_samples_Ricker);
    }

    for (i=0, td=0.;  i< num_samples_Ricker;  i++, td=td+SI) {
		  l= ricker(td,freq, rick_long);
		  Ricker_Amplitude[i] = (float)l;
		  Ricker_time[i] = td;
    }

    if(verbose == TRUE) {
		  printf("    L363 Ricker\ntime,      Amplitude\n");
/*		  for (i=0;  i< num_samples_Ricker;  i++) {
				  printf("%f,      %f\n",Ricker_time[i], Ricker_Amplitude[i]);
		  } */
    }

    if(ricker_out == TRUE) {
    	fpout= fopen(Ricker_filnam,"w");
    	/*fprintf(fpout,"     time,    Amplitude\n");*/

		 for (i=0;  i< num_samples_Ricker;  i++){
			 fprintf(fpout,"%lf\t%lf\n",Ricker_time[i], Ricker_Amplitude[i]);
		 }

		 if(verbose == TRUE) {
		  	printf("num_samples_Ricker=%d\n",  num_samples_Ricker);
		 }
		 
		 fclose(fpout);
    }
    
  } /*END of RICKER WAVELET*/

/*START to READ LOG FILE*/

 if( (fpin = fopen(zrhov_filename,"r") ) == NULL) {
    printf("Can't open file2 %s, try again\n", zrhov_filename);
    exit(0);
 }
 
 for(i=0, num_pts_log=0; (!feof(fpin));  i++, num_pts_log++) {
 
    fscanf (fpin, "%f %f %f", &d, &r, &v);
    depth[i] 	= d;
    rho[i] 		= r;
    Vp[i] 		= v;

    if(verbose == TRUE) {
    	printf("depth=%f, rho=%f Vp=%f\n",depth[i], rho[i], Vp[i]);
    }
    
    if(verbose == TRUE) {
    	printf("L403 num_pts_log= %d \n\n",num_pts_log);
    }

 }
  fclose(fpin);
/* END of reading log file */

/* REGULARIZE LOG FILE */
  zstart = depth[0]; /* first depth for resampling */
  if(verbose == TRUE) printf("L396 Regularizing log file\n");
  if(verbose == TRUE) printf("zstart= %f z_increment= %f num_pts_log= %d \n\n",zstart, z_increment, num_pts_log);

  regular(zstart, z_increment, num_pts_log,
	  &num_pts_rho_reg, rho, depth, rho_reg);

  regular(zstart, z_increment, num_pts_log,
	  &num_pts_Vp_reg, Vp, depth, Vp_reg);

  for (i=0;  i< num_pts_Vp_reg;  i++) {
      depth_reg[i] =  zstart + z_increment * (float)i;
   }
/*  END of REGULARIZING LOG FILE */

  /* write out regularized densities */
if(reg_rho_out == TRUE) {

    if(verbose == TRUE) {
    	printf("Putting resampled densities into a file\n");
    	for (i=0;  i< num_pts_rho_reg;  i++) {
    		printf("depth_reg=%f\trho_reg=%f\n",depth_reg[i], rho_reg[i]);
    	}
	}

    fpout= fopen(Reg_rho_filnam,"w");

    for (i=0;  i< num_pts_rho_reg;  i++) {
    	fprintf(fpout,"%f\t%f\n",depth_reg[i], rho_reg[i]);
    }
    fclose(fpout);

    num_pts_log_reg = num_pts_rho_reg;
} /* end of writing regularized densities */

/* write out regularized velocity values to a file */
if(reg_Vp_out == TRUE) {
    if(verbose == TRUE) {
    	printf("Putting resampled velocities into a file\n");
/*    	for (i=0;  i< num_pts_Vp_reg;  i++) { */
/*    		printf("depth_reg=%f\tVp_reg=%f\n",depth_reg[i], Vp_reg[i]); */
/*    	}*/
    }
    fpout= fopen(Reg_Vp_filnam,"w");
    for (i=0;  i< num_pts_Vp_reg;  i++) {
    	fprintf(fpout,"%f\t%f\n",depth_reg[i], Vp_reg[i]);
    }
    fclose(fpout);
    num_pts_log_reg = num_pts_Vp_reg;
    
} /* end of writing out regularized velocity values to a file */
/*  overall end of REGULARIZING LOG FILE contents (density, velocities)*/


/* CALCULATE TWO-WAY TRAVELTIME TO THE TOP OF LAYER */
/* For use later when converting reflection coefficients that are regularized in depth 
 into their time equivalency
 Use velocity in the layer above the point to calculate increment 
 The output is then regularized at the sample increment in time -s */
 
if(verbose == TRUE) {
    printf("Calculating traveltime to the top of each assumed layer\n");
}

time[0] = 2. * water_depth / Vp_water_mps;/*in secs*/
tstart  = time[0];

if(verbose == TRUE) printf("\ndepth[0]=%f, time[0]=%f",depth[0],time[0]);

for(i=1; i< num_pts_Vp_reg; i++) {
	time[i] = time[i-1] + 2. * ( depth_reg[i] - depth_reg[i-1])/ Vp_reg[i-1];
/*	 if(verbose == TRUE) { */
/*		 printf("\n%d,depth[%d]=%f, time[%d]=%f",i,depth_reg[i],i,time[i]); */
/*	 } */
} /*End CALCULATION of TWO-WAY TRAVELTIME TO THE TOP OF each LAYER*/

/*min_time                  = time[0];
max_time                  = time[num_pts_Vp_reg-1];
expected_num_of_t_samples = (max_time - min_time) /t_increment;*/
/*printf("min_time=%f, max_time=%f, num-samples=%f\n",min_time,max_time, expected_num_of_t_samples);*/

/*  CALCULATE REFLECTION COEFFICIENTS IN DEPTH */
if(verbose == TRUE) printf("\n Calculating reflection coefficients in depth!\n");

bottom_imp        = Vp_reg[0] * rho_reg[0];
water_imp         = Vp_water_mps * rho_water_gcc;
upper_half_space_imp = water_imp;

if (water_depth == 0.0) upper_half_space_imp = 0;  /* case for air */

Refl_coef_reg_depth[0]   = (bottom_imp - upper_half_space_imp) / (bottom_imp + upper_half_space_imp);

for( i=1; i < num_pts_Vp_reg; i++){

	top_imp = Vp_reg[i-1] * rho_reg[i-1];
	bottom_imp = Vp_reg[i] * rho_reg[i];
	Refl_coef_reg_depth[i] = (bottom_imp - top_imp) / (bottom_imp + top_imp);
		  /* if( labs(Refl_coef_reg_depth[i]) < Refl_coef_reg_depth[0]/threshold) Refl_coef_reg_depth[i]=0.;*/

/*	 if( verbose == TRUE) { */
/*			printf("\n i = %d, reflection coefficient =%f\n", i, Refl_coef_reg_depth[i]); */
/*			printf("\n i = %d, bottom_imp = %f  top_imp= %f\n", i, bottom_imp,top_imp); */
/*	  } */
}

  if(verbose == TRUE) {
    printf("Putting raw reflection coefficients (versus depth) into a file\n");
  }

 if(reflec_coef_reg_depth_out  == TRUE) {
		fpout= fopen(Refl_coef_reg_depth_filnam,"w");

		for (i=0;  i< num_pts_Vp_reg;  i++){
			fprintf(fpout,"%f\t%f\n",depth_reg[i], Refl_coef_reg_depth[i]);
		}

		fclose(fpout);
 }

  /*REGULARIZE REFLECTION COEFFICIENTS in time*/
  
 if(verbose == TRUE) {
	 printf("Regularizing reflection coefficients in time\n");
	 printf("num_pts_log_reg = %d\n", num_pts_log_reg);
	 printf("num_pts_Vp_reg = %d\n", num_pts_Vp_reg);
	 printf("xstart= %f\n", xstart);
	 printf("t_increment, = %f\n", t_increment);

/*		for (i=0;  i< num_pts_log_reg;  i++){
			printf("%f\t%f\n",depth_reg[i], Refl_coef_reg_depth[i]);
		} */
 }
 

regular(tstart, t_increment, num_pts_log_reg,
		&num_pts_rc_reg_time, Refl_coef_reg_depth, time, Refl_coef_reg_time);

 if(verbose == TRUE) {
	printf("L530 time,      Amplitude\n");
	printf("num_pts_log_reg = %d\n", num_pts_log_reg);
	printf("num_pts_rc_reg_time = %d\n", num_pts_rc_reg_time);
 }
	
 if(reflec_coef_reg_time_out == TRUE) {
	if(verbose == TRUE) {
		printf("Putting resampled reflection coefficients into a file\n");
    }
    
    fpout= fopen(Refl_coef_reg_time_filnam,"w");

    for (i=0;  i< num_pts_rc_reg_time;  i++) {
    	time_reg =  tstart + t_increment * (float)i;
    	fprintf(fpout,"%f\t%f\n", time_reg, Refl_coef_reg_time[i]);
    }

    fclose(fpout);
  }
/* END of REGULARIZE REFLECTION COEFFICIENTS IN TIME */

/* CONVOLVE SOURCE AND DATA */
 if(verbose == TRUE) printf(" Convolving data \n");

/*  -----------------  My own source ---------------------------------- */
if(read_source == TRUE && resample_source == TRUE) {
	  for (i=num_pts_reg; i < num_pts_log_reg; i++){
		  winA_reg[i]=0.;
	  }
if(verbose == TRUE) {
	for(i=0; i < num_pts_log_reg; i++){
		wint_reg = xstart + t_increment * (float)i;
		printf("source just before convolution\n");
		printf("%f,%f\n",wint_reg,winA_reg[i]);
     }
  }

    convolve(Refl_coef_reg_time, num_pts_log_reg, num_pts_reg,
	       t_increment, winA_reg, Convolve_Amplitude);
    num_pts_conv = num_pts_log_reg+num_pts_reg;
    if(verbose == TRUE) {
      for (i=0;  i< num_pts_conv;  i++){
    	  Convolve_time = (t_increment * (float)i  ) + xstart;
    	  printf("%f\t%f\n", Convolve_time, Convolve_Amplitude[i]);
      }
    }
} /* end convolution */
  /*----------------------- my source already resampled ---------------*/

/*read my own source but didn't resample,as it had been already resampled*/
if (read_source == TRUE && resample_source == FALSE){
    /*N.B. num_pts_reg=num_pts_src*/
    xstart = XSTART; /*defaulted to 0.0*/
    /*t_increment = TINT;*/

    if(verbose == TRUE) {
    	printf("own source,didn't resample,already resampled\n");
    	printf("time and Amplitude\n");
    	for(i=0; i < num_pts_src; i++){
    		wint_reg = xstart + t_increment * (float)i;
    		printf("%f      %f\n",wint_reg,winA_reg[i]);
    	}
	 }

    convolve(Refl_coef_reg_time, num_pts_log_reg, num_pts_reg,
	     t_increment, winA_reg, Convolve_Amplitude);
    num_pts_conv = num_pts_log_reg + num_pts_reg;

    if(verbose == TRUE) {
    	printf("time and Amplitude for synthetic seismogram using above source\n");
    	for (i=0;  i< num_pts_conv;  i++){
    		Convolve_time = (t_increment * (float)i  ) + xstart;
    		printf("%f\t%f\n", Convolve_time, Convolve_Amplitude[i]);
      }
    }
  }
  /*---------------  Ricker Source ------------------------------------*/
if (ricker_wavelet == TRUE) { /*calculated ricker source*/
	 t_increment = (float)SI;
	 convolve(Refl_coef_reg_time, num_pts_log_reg, num_samples_Ricker,
	       t_increment, Ricker_Amplitude,Convolve_Amplitude);
      num_pts_conv = num_pts_log_reg + num_samples_Ricker;

/*	if(verbose == TRUE ) {
		printf(" convolving  Ricker Source with reflection coefficient\n");
		for (i=0; i< num_pts_conv;  i++){
			Convolve_time = (t_increment * (float)i  ) + xstart;
			printf("%f\t%f\n", Convolve_time, Convolve_Amplitude[i]);
		}
    } */

 }
  
  /*CONVOLVE SOURCE AND DATA -----------------END-----------------*/
  
  /*OUTPUT CONVOLVED SIGNAL TO STDOUT*/
for (i=0;  i< num_pts_conv;  i++){
	tmin = 2. * water_depth /Vp_water_mps; /*in secs*/
    Convolve_time = (t_increment * (float)i  ) + tmin;
    fprintf(stdout,"%lf\t%lf\n", Convolve_time, Convolve_Amplitude[i] );
 }
	fclose(stdout);

  
} /*end main*/

double ricker(td, freq, rick_long)
  /* subroutine to calculate a ricker wavelet amplitude at a given time value*/
  double 
    td, /*enter in seconds!!!*/
    freq,/* dominant frequency (Hz)*/
    rick_long;   /*length of ricker wavelet*/
  
  {
#define PI        3.1415926
#define PI2       9.8696044
    
    double 
      zero_cross, t2, /* half the signal length*/
      amplitude, /*output value*/
      dominant_freq2; /*dominant frequencey squared, Hz*/
    
    double arg1;
    
    zero_cross = rick_long/2.; /* in seconds*/
    dominant_freq2 = freq * freq; 
    t2 = ( td - zero_cross) *  ( td - zero_cross);
    arg1 = PI2 * dominant_freq2 * t2;
    amplitude = (1. - 2. * arg1) * exp(-arg1);
    return(amplitude);	
  }
  
  
  void regular(xstart,t_increment,num_pts_src,num_pts_reg,winA,wint,winA_reg)
  /*function to regularize data*/

     float xstart, t_increment, winA[], wint[], winA_reg[];
     int num_pts_src,*num_pts_reg;
{	
         /* xstart: x min for resampling
    	t_increment: resampling interval
    	num_pts_src: num_pts in input data set
    	num_pts_reg: output sampled data set
    	winA: input data amplitudes
    	wint: input data times
    	winA_reg: output sampled data amplitudes
    	xint: output interpolation times
    		  first xint has to be >= 0
    		  last xint has to less than the last x value of
    		  the series being resampled*/

  int i; /*local variable*/
  float xint;
  xint =xstart;
/*  printf("made it to subroutine\n"); */
  while(xint < wint[0])  xint = xint +  t_increment;
/*  printf("regular, xint=%f\n",xint); */
  for  (i=0; i < num_pts_src; i++) {
    while(wint[i+1] >= xint) {
    
    	winA_reg[*num_pts_reg] = (winA[i+1]  -  winA[i])/
    		  (wint[i+1] - wint[i]) * ( xint  -  wint[i]) +  winA[i];
 /*       	printf("regular, xint=%f A_reg=%f\n",xint, winA_reg[*num_pts_reg]); */
			*num_pts_reg=*num_pts_reg +1, xint=xint+t_increment;
		}
  }
}

  
void convolve(Refl_coef_reg_time, num_pts_log_reg, num_pts_src,
		  t_increment, source_amplitude,  amplitude_out)
    
     /* function to convolve two arrays in the time domain regardless
       of each arrays size. Beginning and end effects are included
       Ref: Claerbout,1992, Earth Sounding Analysis, p.5*/


     float Refl_coef_reg_time[],	/* reflection coefficient series in time*/
       t_increment,	/*:sample interval*/		 
       source_amplitude[],/*:source amplitude array*/
       amplitude_out[];	/*:convolved source and reflection coefficient series*/
  
     int num_pts_log_reg, /*:number of values in regularized input series*/
       num_pts_src;	/*:number of values in regularized source series*/
  
  {
    int  j, k;

    for (j=0; j<num_pts_log_reg; j++) {
      for (k = 0; k<num_pts_src; k++) { /*reflection coefficient*/
	amplitude_out[j+k] = amplitude_out[j+k] 
	  + source_amplitude[k] * Refl_coef_reg_time[j];
      }
    }
  }
  
