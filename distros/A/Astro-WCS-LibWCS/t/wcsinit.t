# needs work
print "1..1\nok\n";
my $hdr = "NAXIS   =                    2                                                  NAXIS1  =                32768                                                  NAXIS2  =                32768                                                  CTYPE1  = 'RA---TAN'                                                            CTYPE2  = 'DEC--TAN'                                                            CRPIX1  =  1.6384500000000E+04                                                  CRPIX2  =  1.6384500000000E+04                                                  CRVAL1  =  3.3220101343219E+02                                                  CRVAL2  =  4.5762217326820E+01                                                  CDELT1  = -3.6597222222222E-05                                                  CDELT2  =  3.6597222222222E-05                                                  EQUINOX =  2.0000000000000E+03                                                  RADECSYS= 'ICRS    '                                                            TELESCOP= 'CHANDRA '                                                            INSTRUME= 'HRC     '                                                            DATE-OBS= '1999-08-31T20:45:28'                                                 DATE    = '1999-09-12T14:41:31'                                                 END                                                                             ";

my (
    $cra,$cdec,$secpix,$xrpix,
    $yrpix,$nxpix,$nypix,$rotate,$equinox,$epoch,$proj
    ) = (
	 3.3220101343219E+02,
	 4.5762217326820E+01,
	 -3.6597222222222E-05,
	 16384.5,
	 16384.5,
	 32768,
	 32768,
	 0,
	 2000,
	 );


	 


