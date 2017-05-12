#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include "FastSOM.h"
#include "proto.h"

/*
 * generic funtions
 *
 * NOT superclass functions, but usable by all
 */

NV _vector_distance(AV* V1, AV* V2) {
	NV	diff,sum;
	I32	w_ptr;

	sum = 0;
	for ( w_ptr=av_len(V2) ; w_ptr>=0 ; w_ptr-- ) {
		diff = SvNV(*av_fetch(V1, w_ptr, FALSE))
			- SvNV(*av_fetch(V2, w_ptr, FALSE));
		sum += diff * diff;
	}
	return sqrt(sum);
}

void _bmuguts(SOM_GENERIC *som,AV *sample,IV *bx,IV *by,NV *bd) {
	IV		x,y,z,X,Y,Z;
	NV		sum,diff,distance;
	SOM_Map		*map;
	SOM_Array	*array;
	SOM_Vector	*vector;

	map = som->map;
	X = som->X;
	Y = som->Y;
	Z = som->Z;

	*bx = -1;
	*by = 0;
	*bd = 0.0;

	for ( x=0 ; x<X ; x++ ) {
		array = (&map->array)[x];
		for ( y=0 ; y<Y ; y++ ) {
			vector = (&array->vector)[y];

			sum = 0;
			for ( z=0 ; z<Z ; z++ ) {
				diff = SvNV(*av_fetch(sample,z,0))
					- (&vector->element)[z];
				sum += diff * diff;
			}

			distance = sqrt(sum);

			if ( *bx < 0 )
				{ *bx = 0; *by = 0; *bd = distance; }
			if ( distance < *bd )
				{ *bx = x; *by = y; *bd = distance; }
		}
	}
}


/* http://www.ai-junkie.com/ann/som/som4.html */
void _adjust(SV* self,NV l,NV sigma,AV* unit,AV* v) {
	IV		x,y;
	I32		z,Z;
	NV		d,theta,vold,wold;
	MAGIC		*mg;
	SOM_Map		*map;
	SOM_Array	*array;
	SOM_Vector	*vector;
	SOM_GENERIC	*som;

	x = SvIV(*av_fetch(unit, 0, FALSE));
	y = SvIV(*av_fetch(unit, 1, FALSE));
	d = SvNV(*av_fetch(unit, 2, FALSE));
	theta = exp( -d*d/2/sigma/sigma );

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!\n");
	som = self2somptr(self,mg);

	map = som->map;
	array = (&map->array)[x];
	vector = (&array->vector)[y];

	/* hmm.. casting IV to I32.. is that sane? */
	Z = (I32)som->Z;

	for ( z=0 ; z<Z ; z++ ) {
		wold = (&vector->element)[z];
		vold = SvNV(*av_fetch(v,z,FALSE));
		(&vector->element)[z] = (vold - wold) * l * theta + wold;
	}
}

void _adjustn(SOM_GENERIC* som,NV l,NV sigma,NV* n,AV* v) {
	IV		x,y,X,Y;
	I32		z,Z;
	NV		d,theta,vold,wold;
	SOM_Map		*map;
	SOM_Array	*array;
	SOM_Vector	*vector;

	map = som->map;
	X = som->X;
	Y = som->Y;

	for ( x=0 ; x<X ; x++ ) {
		array = (&map->array)[x];
		for ( y=0 ; y<Y ; y++ ) {
			d = n[x*Y+y];
			if (d < 0) continue;
			theta = exp( -d*d/2/sigma/sigma );
			vector = (&array->vector)[y];

			/* hmm.. casting IV to I32.. is that sane? */
			Z = (I32)som->Z;

			for ( z=0 ; z<Z ; z++ ) {
				wold = (&vector->element)[z];
				vold = SvNV(*av_fetch(v,z,FALSE));
				(&vector->element)[z] =
					(vold - wold) * l * theta + wold;
			}
		}
	}
}

AV* _neighbors(SV* self,NV sigma,IV X0,IV Y0,...) {
	IV		i,x,y,X,Y;
	NV		distance,*n;
	AV		*tmp,*neighbors;
	MAGIC		*mg;
	SOM_GENERIC	*som;
	void		(*neiguts)(SOM_GENERIC* som,NV sigma,IV X0,IV Y0,NV *n);

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!\n");
	som = self2somptr(self,mg);

	X = som->X;
	Y = som->Y;

	i = X*Y;
	Newx(n,i,NV);
	for ( i-=1 ; i>=0 ; i-- )
		n[i] = -1;

	if ( som->type == SOMType_Torus )
		neiguts = _torus_neiguts;
	else if ( som->type == SOMType_Hexa )
		neiguts = _hexa_neiguts;
	else if ( som->type == SOMType_Rect )
		neiguts = _rect_neiguts;
	else
		croak("unknown type");

	neiguts(som,sigma,X0,Y0,n);

	neighbors = newAV();

	for ( x=0 ; x<X ; x++ ) {
		for ( y=0 ; y<Y ; y++ ) {
			distance = n[x*Y+y];
			if ( distance >= 0 ) {
				tmp = newAV();
				av_push(tmp,newSViv(x));
				av_push(tmp,newSViv(y));
				av_push(tmp,newSVnv(distance));
				av_push(neighbors,newRV_noinc((SV*)tmp));
			}
		}
	}
	Safefree(n);
	return neighbors;
}

SOM_Vector* _make_vector(SOM_Array* array) {
	IV		z,len;
	AV		*thingy;
	SV		*tie;
	HV		*stash;
	SOM_Vector	*vector;

        z = array->Z;

	len = sizeof(SOM_Vector)+z*sizeof(NV);
        Newxc(vector, len, char, SOM_Vector);
	Zero(vector, len, char);

        vector->Z = z;

        thingy = newAV();
        tie = newRV_noinc(newSViv(PTR2IV(vector)));
        stash = gv_stashpv("AI::NeuralNet::FastSOM::VECTOR", GV_ADD);
        sv_bless(tie, stash);
        hv_magic((HV*)thingy, (GV*)tie, 'P');
	vector->ref = newRV_noinc((SV*)thingy);

        (&vector->element)[z] = 0.0;
        for ( z-=1 ; z>=0 ; z-- ) {
                (&vector->element)[z] = 0.0;
        }

        return vector;
}

SOM_Array* _make_array(SOM_Map* map) {
	IV		y,len;
	AV		*thingy;
	SV		*tie;
	HV		*stash;
	SOM_Array	*array;

	y = map->Y;

	len = sizeof(SOM_Array)+y*sizeof(SOM_Vector*);
	Newxc(array, len, char, SOM_Array);
	Zero(array, len, char);

	array->Y = y;
	array->Z = map->Z;

	thingy = newAV();
	tie = newRV_noinc(newSViv(PTR2IV(array)));
	stash = gv_stashpv("AI::NeuralNet::FastSOM::ARRAY", GV_ADD);
	sv_bless(tie, stash);
	hv_magic((HV*)thingy, (GV*)tie, PERL_MAGIC_tied);
	array->ref = newRV_noinc((SV*)thingy);

	(&array->vector)[y] = NULL;
	for ( y-=1 ; y>=0 ; y-- )
		(&array->vector)[y] = _make_vector( array );

	return array;
}

SOM_Map* _make_map(SOM_GENERIC *som) {
	IV	x,len;
	AV	*thingy;
	SV	*tie;
	HV	*stash;
	SOM_Map	*map;

	x = som->X;

	len = sizeof(SOM_Map)+x*sizeof(SOM_Array*);
	Newxc(map, len, char, SOM_Map);
	Zero(map, len, char);

	map->X = x;
	map->Y = som->Y;
	map->Z = som->Z;

	thingy = newAV();
	tie = newRV_noinc(newSViv(PTR2IV(map)));
	stash = gv_stashpv("AI::NeuralNet::FastSOM::MAP", GV_ADD);
	sv_bless(tie, stash);
	hv_magic((HV*)thingy, (GV*)tie, PERL_MAGIC_tied);
	map->ref = newRV_noinc((SV*)thingy);

	(&map->array)[x] = NULL;
	for ( x-=1 ; x>=0 ; x-- )
		(&map->array)[x] = _make_array( map );

	return map;
}



/*
 * som functions
 */

void _som_bmu(SV* self, AV* sample) {
	IV		cx,cy;
	NV		cd;
	MAGIC		*mg;
	SOM_GENERIC	*som;
	dXSARGS;

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!\n");
	som = self2somptr(self,mg);

	_bmuguts(som,sample,&cx,&cy,&cd);

	PERL_UNUSED_VAR(items); /* -W */
	sp = mark;
	XPUSHs(sv_2mortal(newSViv(cx)));
	XPUSHs(sv_2mortal(newSViv(cy)));
	XPUSHs(sv_2mortal(newSVnv(cd)));
	PUTBACK;
}

SV* _som_map(SV* self) {
        MAGIC		*mg;
	SOM_GENERIC	*som;

	if ( !(mg = selfmagic(self)) )
                croak("self has no magic!\n");
	som = self2somptr(self,mg);

	SvREFCNT_inc(som->map->ref);
	return som->map->ref;
}

SV* _som_output_dim(SV* self) {
	MAGIC		*mg;
	SOM_GENERIC	*som;

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!\n");
	som = self2somptr(self,mg);

	SvREFCNT_inc(som->output_dim);
	return som->output_dim;
}

void _som_train(SV* self,IV epochs) {
	IV		i,X,Y,bx,by,epoch;
	NV		bd,l,sigma,*n;
	AV		**org,**veg,*sample;
	I32		p,pick,nitems,oitems,vitems;
	MAGIC		*mg;
	SOM_GENERIC	*som;
	bool		wantarray;
	void		(*neiguts)(SOM_GENERIC* som,NV sigma,IV X0,IV Y0,NV* n);
	dXSARGS;

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!");
	som = self2somptr(self,mg);

	if ( epochs < 1 )
		epochs = 1;

	if ( items < 3 )
		croak("no data to learn");

	oitems = items - 2;
	Newx(org,oitems,AV*);
	Newx(veg,oitems,AV*);

	for ( i=2 ; i<items ; i++ )
		if ( SvTYPE(SvRV(ST(i))) != SVt_PVAV )
			croak("training item %i is not an array ref", (int)i);
		else
			org[i-2] = (AV*)SvRV(ST(i));

	som->LAMBDA = epochs / log( som->Sigma0 );

	X = som->X;
	Y = som->Y;

	nitems = X*Y;
	Newx(n,nitems,NV);

	if ( som->type == SOMType_Torus )
		neiguts = _torus_neiguts;
	else if ( som->type == SOMType_Hexa )
		neiguts = _hexa_neiguts;
	else if ( som->type == SOMType_Rect )
		neiguts = _rect_neiguts;
	else
		croak("unknown type");

	wantarray = GIMME_V == G_ARRAY ? TRUE : FALSE;

	/* should this be moved somewhere more global? */
	if ( !PL_srand_called ) {
		seedDrand01((Rand_seed_t)(time(NULL)+PerlProc_getpid()));
		PL_srand_called = TRUE;
	}

	sp = mark;

	for ( epoch=1 ; epoch<=epochs ; epoch++ ) {
		som->T = epoch;
		sigma = som->Sigma0 * exp(-epoch / som->LAMBDA);
		l = som->L0 * exp(-epoch / epochs);

		Copy(org,veg,oitems,AV*);
		vitems = oitems;

		while ( vitems > 0 ) {

			pick = (I32)(Drand01() * vitems);

			sample = (AV*)veg[pick];

			/* optimize me! */
			for ( p=pick+1 ; p<vitems ; p++ ) veg[p-1] = veg[p];
			vitems--;

			_bmuguts(som,sample,&bx,&by,&bd);

			if ( wantarray ) XPUSHs(newSVnv(bd));

			for ( i=0 ; i<nitems ; i++ ) n[i] = -1;

			neiguts(som,sigma,bx,by,n);

			_adjustn(som,l,sigma,n,sample);

		}
	}

	Safefree(n);
	Safefree(org);
	Safefree(veg);

	PUTBACK;
}

void _som_FREEZE(SV* self,SV* cloning) {
	IV		x,y,z;
	MAGIC		*mg;
	SOM_Map		*m;
	SOM_Array	*a;
	SOM_Vector	*v;
	SOM_GENERIC	*som;
	dXSARGS;

	PERL_UNUSED_VAR(items); /* -W */
	sp = mark;

	if ( !SvTRUE(cloning) ) {

	if ( (mg = selfmagic(self)) != NULL) {

		/*
		 * we should get here on the first pass. this is where we
		 * serialize the hash seen from perl.
		 */

		XPUSHs(INT2PTR(SV*,newSVpvn("i wanna be a cowboy",19)));

	}
	else if ( SvTYPE(SvRV(self)) == SVt_PVMG ) {

		/*
		 * this should be the second pass. here we need to serialize
		 * the tied part not seen from the perl side.
		 */

		som = INT2PTR(SOM_GENERIC*,self2iv(self));

		XPUSHs( INT2PTR(SV*,newSVpvn(
				"beat me whip me make me code badly",34)) );
		XPUSHs( newRV_noinc(newSViv(som->type)) );
		XPUSHs( newRV_noinc(newSViv(som->X)) );
		XPUSHs( newRV_noinc(newSViv(som->Y)) );
		XPUSHs( newRV_noinc(newSViv(som->Z)) );
		XPUSHs( newRV_noinc(newSVnv(som->R)) );
		XPUSHs( newRV_noinc(newSVnv(som->Sigma0)) );
		XPUSHs( newRV_noinc(newSVnv(som->L0)) );
		XPUSHs( newRV_noinc(newSVnv(som->LAMBDA)) );
		XPUSHs( newRV_noinc(newSVnv(som->T)) );
		XPUSHs( newRV_noinc(som->output_dim) );
		XPUSHs( newRV_noinc((SV*)som->labels) );

		m = som->map;
		for ( x=som->X-1 ; x>=0 ; x-- ) {
			a = (&m->array)[x];
			for ( y=som->Y-1 ; y>=0 ; y-- ) {
				v = (&a->vector)[y];
				for ( z=som->Z-1 ; z>=0 ; z-- ) {
					XPUSHs(newRV_noinc(newSVnv(
					(&v->element)[z])));
				}
			}
		}
	}
	else {
		croak("i wanna run with scissors!");
	}
	} /* cloning */
	PUTBACK;
}

void _som_THAW(SV* self,SV* cloning,SV* serialized) {
	IV		x,y,z,i;
	SV		*rrr;
	HV		*stash;
	SOM_Map		*m;
	SOM_Array	*a;
	SOM_Vector	*v;
	SOM_GENERIC	*som;
	dXSARGS;

	PERL_UNUSED_VAR(serialized); /* -W */

	if (!SvTRUE(cloning)) {

	if ( SvTYPE(SvRV(self)) == SVt_PVMG ) {
		Newxz(som,1,SOM_GENERIC);

		som->type = SvIV(SvRV(ST(3)));
		som->X = SvIV(SvRV(ST(4)));
		som->Y = SvIV(SvRV(ST(5)));
		som->Z = SvIV(SvRV(ST(6)));
		som->R = SvNV(SvRV(ST(7)));
		som->Sigma0 = SvNV(SvRV(ST(8)));
		som->L0 = SvNV(SvRV(ST(9)));
		som->LAMBDA = SvNV(SvRV(ST(10)));
		som->T = SvNV(SvRV(ST(11)));
		som->output_dim = newSVsv(SvRV(ST(12)));
		som->labels = (AV*)SvRV(ST(13));

		som->map = _make_map( som );

		i = 14;
		m = som->map;
		for ( x=som->X-1 ; x>=0 ; x-- ) {
			a = (&m->array)[x];
			for ( y=som->Y-1 ; y>=0 ; y-- ) {
				v = (&a->vector)[y];
				for ( z=som->Z-1 ; z>=0 ; z-- ) {
					/*
					(&v->element)[z] =
						SvNV(SvRV(ST(i++)));
					*/
					rrr = SvRV(ST(i++));
					(&v->element)[z] = SvNV(rrr);
				}
			}
		}

		SvSetSV( SvRV(self), sv_2mortal(newSViv((IV)PTR2IV(som))) );

		stash = SvSTASH(SvRV(self));
		som->ref = sv_bless(newRV_inc((SV*)self),stash);

	}

	else if ( SvTYPE(SvRV(self)) != SVt_PVHV )
		croak("you'll put an eye out!");

	} /* cloning */

	PERL_UNUSED_VAR(items); /* -W */
	sp = mark;
	PUTBACK;
}

SV* _som_FETCH(SV* self,SV* key) {
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("map",3) ) ) ) {
		SOM_GENERIC *som = INT2PTR(SOM_Rect*,self2iv(self));
		SvREFCNT_inc(som->map->ref);
		return som->map->ref;
	}
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_X",2) ) ) )
		return newSViv(tied2ptr(self)->X);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Y",2) ) ) )
		return newSViv(tied2ptr(self)->Y);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Z",2) ) ) )
		return newSViv(tied2ptr(self)->Z);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_R",2) ) ) )
		return newSVnv(tied2ptr(self)->R);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_L0",3) ) ) )
		return newSVnv(tied2ptr(self)->L0);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Sigma0",7) ) ) )
		return newSVnv(tied2ptr(self)->Sigma0);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("output_dim",10) ) ) )
		return newSVsv(tied2ptr(self)->output_dim);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("LAMBDA",6) ) ) )
		return newSVnv(tied2ptr(self)->LAMBDA);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("T",1) ) ) )
		return newSVnv(tied2ptr(self)->T);
	if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("labels",6) ) ) )
		return newRV_inc((SV*)(tied2ptr(self)->labels));
	croak("%s not accessible for read", SvPV_nolen(key));
}

SV* _som_STORE(SV* self,SV* key,SV* val) {
        if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_X",2) ) ) )
		tied2ptr(self)->X = SvIV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Y",2) ) ) )
                tied2ptr(self)->Y = SvIV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Z",2) ) ) )
                tied2ptr(self)->Z = SvIV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_R",2) ) ) )
                tied2ptr(self)->R = SvNV(val);
	else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_L0",3) ) ) )
		tied2ptr(self)->L0 = SvNV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("_Sigma0",7) ) ) )
                tied2ptr(self)->Sigma0 = SvNV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("output_dim",10) ) ) )
                tied2ptr(self)->output_dim = newSVsv(val);
	else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("LAMBDA",6) ) ) )
		tied2ptr(self)->LAMBDA = SvNV(val);
	else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("T",1) ) ) )
		tied2ptr(self)->T = SvNV(val);
        else if ( !sv_cmp( key, INT2PTR(SV*,newSVpvn("map",3) ) ) )
		croak("cant assign to map");
	else
		croak("%s not accessible for write", SvPV_nolen(key));
	return val;
}

SV* _som_FIRSTKEY() {
	return INT2PTR(SV*,newSVpvn("_X",2));
}

SV* _som_NEXTKEY(SV* prev) {
        if ( strEQ( SvPVX(prev), "_X" ) )
                return INT2PTR(SV*,newSVpvn("_Y",2));
        else if ( strEQ( SvPVX(prev), "_Y" ) )
                return INT2PTR(SV*,newSVpvn("_Z",2));
        else if ( strEQ( SvPVX(prev), "_Z" ) )
                return INT2PTR(SV*,newSVpvn("_R",2));
        else if ( strEQ( SvPVX(prev), "_R" ) )
                return INT2PTR(SV*,newSVpvn("_Sigma0",7));
        else if ( strEQ( SvPVX(prev), "_Sigma0" ) )
                return INT2PTR(SV*,newSVpvn("_L0",3));
        else if ( strEQ( SvPVX(prev), "_L0" ) )
                return INT2PTR(SV*,newSVpvn("LAMBDA",6));
        else if ( strEQ( SvPVX(prev), "LAMBDA" ) )
                return INT2PTR(SV*,newSVpvn("T",1));
        else if ( strEQ( SvPVX(prev), "T" ) )
                return INT2PTR(SV*,newSVpvn("labels",6));
        else if ( strEQ( SvPVX(prev), "labels" ) )
                return INT2PTR(SV*,newSVpvn("map",3));
        return &PL_sv_undef;
}

void _som_DESTROY(SV* self) {
	IV              iv;
	SV              *ref;
	SOM_Map         *map;
	SOM_GENERIC     *som;

	if ( !SvROK(self) )
		return;
	ref = SvRV(self);
	if ( !SvIOK(ref) )
		return;
	iv = SvIV(ref);
	som = INT2PTR(SOM_GENERIC*,iv);
	if ( !som )
		return;
	map = som->map;
	/* more to do here ? */
}



/*
 * rect functions
 */

void _rect_neiguts(SOM_Rect* som,NV sigma,IV X0,IV Y0,NV* n) {
	IV	x,y,X,Y;
	NV	d2,s2;

	X = som->X;
	Y = som->Y;

	s2 = sigma * sigma;

	for ( x=0 ; x<X ; x++ ) {
		for ( y=0 ; y<Y ; y++ ) {
			d2 = (x-X0)*(x-X0)+(y-Y0)*(y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);
		}
	}
}

void _rect_new(const char* class,...) {
	IV		i;
	NV		sigma0,rate;
	SV		*tie,*rv,*key,*val,*od,*sclass;
	HV		*options,*hash,*stash;
	char		*begptr,*endptr,*xstart,*ystart,*yend;
	STRLEN		len;
	SOM_GENERIC	*som;
	dXSARGS;

	if ( (items & 1) ^ 1 )
		croak( "Weird number of arguments\n" );

	options = newHV();
	for ( i=1 ; i<items ; i+=2 ) {
		key = ST(i);
		val = ST(i+1);
		len = sv_len(key);
		hv_store( options, SvPV_nolen(key), len, val, 0 );
	}

	if ( !hv_exists( options, "input_dim", 9 ) )
		croak( "no input_dim argument" );
	if ( !hv_exists( options, "output_dim", 10 ) )
		croak( "no output_dim argument" );

	Newxz(som,1,SOM_GENERIC);

	od = newSVsv(*hv_fetch(options,"output_dim",10,FALSE));
	som->output_dim = od;

	begptr = SvPV_force(od,SvLEN(od));
	endptr = SvEND(od) - 1; /* allow for terminating character */
	if ( endptr < begptr )
		croak("brain damage!!!");

	xstart = begptr;
	if ( !isDIGIT((char)*xstart) )
		croak("no x-dimension found");
	som->X = Atol(xstart);

	ystart = yend = endptr;
	if ( !isDIGIT((char)*ystart) )
		croak("no y-dimension found");
	while (--ystart >= begptr)
		if ( !isDIGIT((char)*ystart) )
			break;
	som->Y = Atol(++ystart);

	som->Z = SvIV(*hv_fetch(options,"input_dim",9,FALSE));

	som->R = som->X > som->Y
		? som->Y / 2.0
		: som->X / 2.0;

	if ( hv_exists( options, "sigma0", 6 ) ) {
		sigma0 = SvNV(*hv_fetch(options,"sigma0",6,0));
		if ( sigma0 )
			som->Sigma0 = sigma0;
		else
			som->Sigma0 = som->R;
	}
	else
		som->Sigma0 = som->R;

	if ( hv_exists( options, "learning_rate", 13 ) ) {
		rate = SvNV(*hv_fetch(options,"learning_rate",13,0));
		if ( rate )
			som->L0 = rate;
		else
			som->L0 = 0.1;
	}
	else
		som->L0 = 0.1;

	som->map = _make_map(som);
	som->labels = newAV();

	sclass = sv_2mortal(newSVpvf("%s",class));
	if (!sv_cmp(sclass,INT2PTR(
			SV*,newSVpvn("AI::NeuralNet::FastSOM::Rect",28))))
		som->type = SOMType_Rect;
	/*
	else if (!sv_cmp(sclass,INT2PTR(
			SV*,newSVpvn("AI::NeuralNet::FastSOM::Hexa",28))))
		som->type = SOMType_Hexa;
	*/
	else if (!sv_cmp(sclass,INT2PTR(
			SV*,newSVpvn("AI::NeuralNet::FastSOM::Torus",29))))
		som->type = SOMType_Torus;
	else
		croak("unknown type");

	hash = (HV*)sv_2mortal((SV*)newHV());
	tie = newRV_noinc(newSViv(PTR2IV(som)));
	stash = gv_stashpv(class, GV_ADD);
	sv_bless(tie, stash);
	hv_magic(hash, (GV*)tie, PERL_MAGIC_tied);
	rv = sv_bless(newRV_noinc((SV*)hash),stash);

	som->ref = rv;

	/*
	 * here 'hash' is the object seen from the perl side.
	 * 'tie' is what we see from the c side when accessing the tied
	 * functionality.
	 */

	sp = mark;
	XPUSHs(rv);
	PUTBACK;
}

SV* _rect_radius(SV* self) {
	MAGIC		*mg;
	SOM_GENERIC	*som;

	if ( !(mg = selfmagic(self)) )
		croak("self has no magic!\n");
	som = self2somptr(self,mg);

	return newSVnv(som->R);
}



/*
 * torus functions
 */

void _torus_neiguts(SOM_Torus* som,NV sigma,IV X0,IV Y0,NV* n) {
	IV	x,y,X,Y;
	NV	d2,s2;

	X = som->X;
	Y = som->Y;

	s2 = sigma * sigma;

	for ( x=0 ; x<X ; x++ ) {
		for ( y=0 ; y<Y ; y++ ) {

			/*
			 * which one of these should "win"?
			 */

			d2 = (x-X0)*(x-X0) + (y-Y0)*(y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);

			d2 = (x-X-X0)*(x-X-X0) + (y-Y0)*(y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);

			d2 = (x+X-X0)*(x+X-X0) + (y-Y0)*(y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);

			d2 = (x-X0)*(x-X0) + (y-Y-Y0)*(y-Y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);

			d2 = (x-X0)*(x-X0) + (y+Y-Y0)*(y+Y-Y0);
			if (d2 <= s2) n[x*Y+y] = sqrt(d2);
		}
	}
}

/* http://www.ai-junkie.com/ann/som/som3.html */



/*
 * hexa functions
 */

void _hexa_new(const char* class) {
	IV		i;
	SV		*key,*val,*od,*tie,*rv;
	NV		sigma0,rate;
	HV		*options,*hash,*stash;
	STRLEN		len;
	SOM_Hexa	*hexa;
	dXSARGS;

	if ( (items & 1) ^ 1 )
		croak( "Weird number of arguments\n" );

	options = newHV();
	for ( i=1 ; i<items ; i+=2 ) {
		key = ST(i);
		val = ST(i+1);
		len = sv_len(key);
		hv_store( options, SvPV_nolen(key), len, val, 0 );
	}

	if ( !hv_exists( options, "input_dim", 9 ) )
		croak( "no input_dim argument" );
	if ( !hv_exists( options, "output_dim", 10 ) )
		croak( "no ouput_dim argument" );

	Newxz(hexa,1,SOM_Hexa);

	od = newSVsv(*hv_fetch(options,"output_dim",10,FALSE));
	hexa->output_dim = od;

	hexa->X=SvIV(*hv_fetch(options,"output_dim",10,FALSE));
	hexa->Z=SvIV(*hv_fetch(options,"input_dim",9,FALSE));

	hexa->Y = hexa->X;
	hexa->R = hexa->X / 2.0;

	if ( hv_exists( options, "sigma0", 6 ) ) {
		sigma0 = SvNV(*hv_fetch(options,"sigma0",6,0));
                if ( sigma0 )
                        hexa->Sigma0 = sigma0;
                else
                        hexa->Sigma0 = hexa->R;
        }
        else
                hexa->Sigma0 = hexa->R;

	if ( hv_exists( options, "learning_rate", 13 ) ) {
                rate = SvNV(*hv_fetch(options,"learning_rate",13,0));
                if ( rate )
                        hexa->L0 = rate;
                else
                        hexa->L0 = 0.1;
        }
        else
                hexa->L0 = 0.1;

	hexa->map = _make_map( hexa );
	hexa->labels = newAV();

	hexa->type = SOMType_Hexa;

	hash = (HV*)sv_2mortal((SV*)newHV());
	tie = newRV_noinc(newSViv(PTR2IV(hexa)));
	stash = gv_stashpv(class, GV_ADD);
	sv_bless(tie, stash);
	hv_magic(hash, (GV*)tie, PERL_MAGIC_tied);
	rv = sv_bless(newRV_noinc((SV*)hash),stash);

	hexa->ref = rv;

	sp = mark;
	XPUSHs(rv);
	PUTBACK;
}

NV _hexa_distance(NV x1,NV y1,NV x2,NV y2) {
	NV	tmp,dx,dy;

	if ( x1+y1 > x2+y2 ) {
		tmp=x1; x1=x2; x2=tmp;
		tmp=y1; y1=y2; y2=tmp;
	}

	dx = x2 - x1;
	dy = y2 - y1;

	if ( dx<0 || dy<0 )
		return abs(dx) + abs(dy);
	else
		return dx<dy ? dy : dx;
}

void _hexa_neiguts(SOM_Hexa* som,NV sigma,IV X0,IV Y0,NV* n) {
	IV	x,y,X,Y;
	NV	d;

	X = som->X;
	Y = som->Y;

	for ( x=0 ; x<X ; x++ ) {
		for ( y=0 ; y<Y ; y++ ) {
			d = _hexa_distance(X0,Y0,x,y);
			if (d <= sigma) n[x*Y+y] = d;
		}
	}
}



/*
 * map functions
 */

SV* _map_FETCH(SV* self,I32 x) {
	SOM_Map		*map;
	SOM_Array	*array;
	
	map = INT2PTR(SOM_Map*,self2iv(self));
	array = (&map->array)[x];
	SvREFCNT_inc(array->ref);
	return array->ref;
}

void _map_DESTROY(SV* self) {
	SOM_Map		*map;

	map = INT2PTR(SOM_Map*,self2iv(self));
	/* need more done here ? */
	Safefree( map );
}



/*
 * array functions
 */

void _array_STORE(SV* self,IV y,SV* aref) {
	I32		len;
	NV		tmp;
	AV		*src;
	SV		**ptr;
	SOM_Array	*array;
	SOM_Vector	*dst;

	if ( SvTYPE( SvRV(aref) ) != SVt_PVAV )
		croak("value to store is not a reference to an array\n");
	src = (AV*)SvRV( aref );

	array = INT2PTR(SOM_Array*,self2iv(self));
	dst = (&array->vector)[y];

	if ( y < 0 )
		croak("storing y-index < 0 not supported\n");
	if ( y >= array->Y )
		croak("storing y-index > y-dimension of SOM\n");

	len = av_len( src );
	if ( len < 0 )
		croak("cant store empty vector\n");
	if ( len+1 > array->Z )
		croak("vector too long\n");
	if ( len+1 < array->Z )
		croak("vector too short\n");

	for ( ; len >= 0 ; len-- ) {
		ptr = av_fetch( src, len, 0 );
		if ( ptr == NULL )
			croak("NULL ptr!\n");
		tmp = SvNV(*ptr);
		(&dst->element)[len] = tmp;
	}
}

SV* _array_FETCH(SV* self,I32 y) {
	SOM_Array	*array;
	SOM_Vector	*vector;

	array = INT2PTR(SOM_Array*,self2iv(self));
	vector = (&array->vector)[y];
	SvREFCNT_inc(vector->ref);
	return vector->ref;
}

void _array_DESTROY(SV* self) {
	SOM_Array	*array;

	array = INT2PTR(SOM_Array*,self2iv(self));
	/* need more done here ? */
	Safefree( array );
}



/*
 * vector functions
 */

void _vector_STORE(SV* self,I32 z,NV val) {
	SOM_Vector	*vector;

	vector = INT2PTR(SOM_Vector*,self2iv(self));
	if ( z < 0 )
		croak("negative z-index not supported\n");
	if ( z >= vector->Z )
		croak("z-index larger than vector dimension\n");
	(&vector->element)[z] = val;
}

SV* _vector_FETCH(SV* self,I32 z) {
	SOM_Vector	*vector;

	vector = INT2PTR(SOM_Vector*,self2iv(self));
	return newSVnv((&vector->element)[z]);
}

void _vector_DESTROY(SV* self) {
	SOM_Vector	*vector;

	vector = INT2PTR(SOM_Vector*,self2iv(self));
	/* need more done here ? */
	Safefree( vector );
}



/*
 *
 * End of C code. Begin XS.
 *
 */



MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM	

PROTOTYPES: DISABLE


void
train (self, epochs, ...)
	SV *	self
	IV	epochs
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_train(self,epochs);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
	}
	return;

void
bmu (self, sample)
	SV *	self
	AV *	sample
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_bmu(self,sample);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

SV *
map (self)
	SV *	self
	PREINIT:
	SV* rv;
	CODE:
	rv = _som_map(self);
	ST(0) = rv;
	sv_2mortal(ST(0));

SV *
output_dim (self)
	SV *	self
	PREINIT:
	SV* rv;
	CODE:
	rv = _som_output_dim(self);
	ST(0) = rv;
	sv_2mortal(ST(0));

void
_adjust (self, l, sigma, unit, v)
	SV *    self
	NV      l
	NV	sigma
	AV *    unit
	AV *    v
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_adjust(self, l, sigma, unit, v);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
	}
	return;

void
STORABLE_freeze (self, cloning)
	SV *	self
	SV *	cloning
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_FREEZE(self,cloning);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
	}
	return;

void
STORABLE_thaw (self, cloning, serialized, ...)
	SV *	self
	SV *	cloning
	SV *	serialized
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_THAW(self,cloning,serialized);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_UNDEF;
	}
	return;

SV *
FETCH (self, key)
	SV *    self
	SV *    key
	PREINIT:
	SV* rv;
	CODE:
	rv = _som_FETCH(self, key);
	ST(0) = rv;
	sv_2mortal(ST(0));

void
STORE (self, key, val)
	SV *    self
	SV *    key
	SV *    val
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_STORE(self, key, val);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
	}
	return;

SV *
FIRSTKEY (self)
        SV *    self
	PREINIT:
	SV* rv;
        CODE:
	if (!self) croak("avoiding -Wextra");
        rv = _som_FIRSTKEY();
        ST(0) = rv;
        sv_2mortal(ST(0));

SV *
NEXTKEY (self,prev)
        SV *    self
        SV *    prev
	PREINIT:
	SV* rv;
        CODE:
	if (!self) croak("avoiding -Wextra");
        rv = _som_NEXTKEY(prev);
        ST(0) = rv;
        sv_2mortal(ST(0));

void
DESTROY (obj)
	SV *    obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_som_DESTROY(obj);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
	}
	return;



MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM::Rect	

PROTOTYPES: DISABLE


void
new (class, ...)
	const char *	class
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_rect_new(class);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

AV *
neighbors (self, sigma, X, Y, ...)
        SV *    self
        NV      sigma
        IV      X
        IV      Y
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = _neighbors(self, sigma, X, Y);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
radius (self)
	SV *	self
	PREINIT:
	SV* rv;
	CODE:
	rv = _rect_radius(self);
	ST(0) = rv;
	sv_2mortal(ST(0));




MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM::Torus	

PROTOTYPES: DISABLE


AV *
neighbors (self, sigma, X, Y, ...)
        SV *    self
        NV      sigma
        IV      X
        IV      Y
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = _neighbors(self, sigma, X, Y);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL



MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM::Hexa	

PROTOTYPES: DISABLE


void
new (class, ...)
	const char *	class
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_hexa_new(class);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

AV *
neighbors (self, sigma, X, Y, ...)
        SV *    self
        NV      sigma
        IV      X
        IV      Y
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = _neighbors(self, sigma, X, Y);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL



MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM::Utils	

PROTOTYPES: DISABLE


NV
vector_distance (V1, V2)
	AV_SPECIAL*	V1;
	AV_SPECIAL*	V2;
	PREINIT:
	NV rv;
	CODE:
        rv = _vector_distance((AV*)V1, (AV*)V2);
        XSprePUSH; PUSHn((NV)rv);



MODULE = AI::NeuralNet::FastSOM 	PACKAGE = AI::NeuralNet::FastSOM::MAP	

PROTOTYPES: DISABLE


SV *
FETCH (self, x)
	SV *	self
	I32	x
	PREINIT:
	SV* rv;
	CODE:
	rv = _map_FETCH(self, x);
	ST(0) = rv;
	sv_2mortal(ST(0));

IV
FETCHSIZE (self)
	SV *	self
	PREINIT:
	IV rv;
	CODE:
	rv = (INT2PTR(SOM_Map*,self2iv(self)))->X;
	XSprePUSH; PUSHi((IV)rv);

void
DESTROY (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_map_DESTROY(obj);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;



MODULE = AI::NeuralNet::FastSOM		PACKAGE = AI::NeuralNet::FastSOM::ARRAY	

PROTOTYPES: DISABLE


void
STORE (self, y, aref)
	SV *	self
	IV	y
	SV *	aref
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_array_STORE(self, y, aref);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

SV *
FETCH (self, y)
	SV *	self
	I32	y
	PREINIT:
	SV* rv;
	CODE:
	rv = _array_FETCH(self, y);
	ST(0) = rv;
	sv_2mortal(ST(0));

IV
FETCHSIZE (self)
	SV *	self
	PREINIT:
	IV rv;
	CODE:
	rv = (INT2PTR(SOM_Array*,self2iv(self)))->Y;
	XSprePUSH; PUSHi((IV)rv);

void
DESTROY (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_array_DESTROY(obj);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;



MODULE = AI::NeuralNet::FastSOM	PACKAGE = AI::NeuralNet::FastSOM::VECTOR	

PROTOTYPES: DISABLE


void
STORE (self, z, val)
	SV *	self
	I32	z
	NV	val
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_vector_STORE(self, z, val);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

SV *
FETCH (self, z)
	SV *	self
	I32	z
	PREINIT:
	SV* rv;
	CODE:
	rv = _vector_FETCH(self, z);
	ST(0) = rv;
	sv_2mortal(ST(0));

IV
FETCHSIZE (self)
	SV *	self
	PREINIT:
	IV rv;
	CODE:
	rv = (INT2PTR(SOM_Vector*,self2iv(self)))->Z;
	XSprePUSH; PUSHi((IV)rv);

void
DESTROY (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_vector_DESTROY(obj);
	if (PL_markstack_ptr != temp) {
		PL_markstack_ptr = temp;
		XSRETURN_EMPTY;
        }
	return;

