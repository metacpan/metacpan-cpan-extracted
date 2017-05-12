/*
 * $Header$
 *
 * this is based off of code that i based off of other modules i've found in the
 * distant past. if you are the original author and you recognize this code let
 * me know and you'll be credited
 *
 * Copyright (C) 2003 by Ross McFarland
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 * 
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
	
#include <nnwork.h>
#include <neuron.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'A':
	if (strEQ(name + 0, "ALL")) {	/*  removed */
#ifdef ALL
	    return ALL;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 0, "HIDDEN")) {	/*  removed */
#ifdef HIDDEN
	    return HIDDEN;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 0, "INPUT")) {	/*  removed */
#ifdef INPUT
	    return INPUT;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 0, "OUTPUT")) {	/*  removed */
#ifdef OUTPUT
	    return OUTPUT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

/* function that takes an array reference and convert it into an equivelent
 * float array. dlen is the number of elements that we want to make sure are in
 * the array */
static float *
svpvav_to_float_array (SV * svpvav, int dlen)
{
	float *  array;
	AV    *  avp;
	SV    ** svpp;
	int      i;

	/* make sure that svpvav is array reference */
	if( !SvROK(svpvav) || (SvTYPE(SvRV(svpvav)) != SVt_PVAV) )
		Perl_croak(aTHX_ "parameter should be a valid array reference");

	/* get the array pointers out of its sv reference */
	avp = (AV*)SvRV(svpvav);

	/* make sure that it has the desired number of elements */
	if( av_len(avp)+1 != dlen )
		Perl_croak(aTHX_ "size of array and desired length do not match");
	
	/* alloc the memory for ains and aouts */
	array = (float*)malloc( dlen * sizeof(float) );
	if( array == NULL )
		Perl_croak(aTHX_ "unable to allocate memory for storing array");

	/* copy avins to ains */
	for( i = 0; i < dlen; i++ )
	{
		/* don't need ins anymore use as a tmp */
		svpp = av_fetch(avp, i, 0);
		if( !svpp || !*svpp || !SvOK(*svpp) )
		{
			if( array ) free(array);
			Perl_croak(aTHX_ "bad array value encountered at index %d", i);
		}
		array[i] = (float)SvNV(*svpp);
	}

	return array;
}

MODULE = AI::LibNeural		PACKAGE = AI::LibNeural		

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

nnwork *
nnwork::new (...)
    PREINIT:
	char * filename;
	int    inputs;
	int    hiddens;
	int    outputs;
    CODE:
    	CLASS = (char*)SvPV_nolen(ST(0));

	if( items == 1 )
	{
		/* blank */
		RETVAL = new nnwork();
	}
	else if( items == 2 )
	{
		/* given a file to load */
		char*	filename = (char*)SvPV_nolen(ST(1));
		RETVAL = new nnwork(filename);
	}
	else if( items == 4 )
	{
		/* given node counts */
		int	inputs = (int)SvIV(ST(1));
		int	hiddens = (int)SvIV(ST(2));
		int	outputs = (int)SvIV(ST(3));
		RETVAL = new nnwork(inputs, hiddens, outputs);
	}
	else
		Perl_croak(aTHX_ "Usage: Neural::new([ins, hids, outs])");
    OUTPUT:
	RETVAL    

int
nnwork::get_layersize (which)
	int which

void
nnwork::train (ins, outs, minerr, trainrate)
	SV    * ins
	SV    * outs
	float	minerr
	float	trainrate
    PREINIT:
	int     i;
	int     nin;
	int     nout;
	float * ains;
	float * aouts;
    CODE:
	nin = THIS->get_layersize(INPUT);
	nout = THIS->get_layersize(OUTPUT);

	ains = svpvav_to_float_array(ins, nin);
	aouts = svpvav_to_float_array(outs, nout);

	THIS->train(ains, aouts, minerr, trainrate);

	if( ains ) free(ains);
	if( aouts ) free(aouts);

void
nnwork::run (ins)
	SV * ins
    PREINIT:
	int     i;
	int     nin;
	int     nout;
	float * ains;
	float * aouts;
    PPCODE:
	nin = THIS->get_layersize(INPUT);
	nout = THIS->get_layersize(OUTPUT);

	ains = svpvav_to_float_array(ins, nin);

	aouts = (float*)malloc(nout * sizeof(float));
	if( aouts == NULL )
		XSRETURN_UNDEF;

	THIS->run(ains, aouts);

	EXTEND(SP, nout);
	for( i = 0; i < nout; i++ )
	{
		PUSHs(sv_2mortal(newSVnv(aouts[i])));
	}

	if( ains ) free(ains);
	if( aouts ) free(aouts);

int
nnwork::load (filename)
	char * filename

int
nnwork::save (filename)
	char * filename

