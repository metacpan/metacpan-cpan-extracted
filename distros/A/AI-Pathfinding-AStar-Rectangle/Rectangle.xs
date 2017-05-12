#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#define cxinc() Perl_cxinc(aTHX)
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

#ifdef _MSC_VER
    #define inline 
#endif

inline bool is_hash(SV *x){
    return SvTYPE(x) == SVt_PVHV;
}

struct map_item{
    int g;
    int h;
    int k;
    char prev;
    char open;
    char closed;
    char reserved[1];
};
struct map_like{
    unsigned int width;
    unsigned int height;
    signed int start_x;
    signed int start_y;
    signed int current_x;
    signed int current_y;
    unsigned char map[];
};

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif


#ifndef croak_xs_usage
#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
M_croak_xs_usage(pTHX_ const CV *const cv, const char *const params);

STATIC void
M_croak_xs_usage(pTHX_ const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
            Perl_croak(aTHX_ "Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak(aTHX_ "Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak(aTHX_ "Usage: CODE(0x%"UVxf")(%s)", PTR2UV(cv), params);
    }
}
#endif
#ifdef PERL_IMPLICIT_CONTEXT
#define croak_xs_usage(a,b)     M_croak_xs_usage(aTHX_ a,b)
#else
#define croak_xs_usage          M_croak_xs_usage
#endif
#endif


#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
#endif /* !defined(newXS_flags) */

#ifdef XMULTICALL

void
foreach_xy(self, block)
SV * self;
SV * block;
PROTOTYPE: $&
CODE:
{
    dVAR; dMULTICALL;
    pmap newmap;
    int x,y;
    GV *agv,*bgv,*gv;
    HV *stash;
    I32 gimme = G_VOID;
    SV **args = &PL_stack_base[ax];
    SV *x1, *y1, *value;
    AV *argv;

    CV *cv;
    if (!sv_isobject(self))
        croak("Need object");
    newmap = (pmap) SvPV_nolen(SvRV(self));
    cv = sv_2cv(block, &stash, &gv, 0);
    agv = gv_fetchpv("a", TRUE, SVt_PV);
    bgv = gv_fetchpv("b", TRUE, SVt_PV);
    SAVESPTR(GvSV(agv));
    SAVESPTR(GvSV(bgv));
    SAVESPTR(GvSV(PL_defgv));
    x1 = sv_newmortal();
    y1 = sv_newmortal();

    SAVESPTR(GvAV(PL_defgv));
    if (0){
        argv = newAV();
        av_push(argv, newSViv(10));
        av_push(argv, newSViv(20));
        sv_2mortal((SV*) argv);
        GvAV(PL_defgv) = argv;
    }
    value = sv_newmortal();
    GvSV(agv) = x1;
    GvSV(bgv) = y1;
    GvSV(PL_defgv)  = value;
    PUSH_MULTICALL(cv);
    if (items>2){
        for(y =newmap->height-1 ; y>=0; --y){
            for (x = 0; x < newmap->width; ++x){
                sv_setiv(x1,x + newmap->start_x);
                sv_setiv(y1,y + newmap->start_y);
                sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
                MULTICALL;

            }
        }

    }
    else {
        for(y =0; y< newmap->height; ++y){
            for (x = 0; x < newmap->width; ++x){
                sv_setiv(x1,x + newmap->start_x);
                sv_setiv(y1,y + newmap->start_y);
                sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
                MULTICALL;

            }
        }
    }
    POP_MULTICALL;
    XSRETURN_EMPTY;
}

void
foreach_xy_set (self, block)
SV * self;
SV * block;
PROTOTYPE: $&
CODE:
{
    dVAR; dMULTICALL;
    pmap newmap;
    int x,y;
    GV *agv,*bgv,*gv;
    HV *stash;
    I32 gimme = G_VOID;
    SV **args = &PL_stack_base[ax];
    SV *x1, *y1, *value;

    CV *cv;
    if (!sv_isobject(self))
        croak("Need object");
    newmap = (pmap) SvPV_nolen(SvRV(self));
    cv = sv_2cv(block, &stash, &gv, 0);
    agv = gv_fetchpv("a", TRUE, SVt_PV);
    bgv = gv_fetchpv("b", TRUE, SVt_PV);
    SAVESPTR(GvSV(agv));
    SAVESPTR(GvSV(bgv));
    SAVESPTR(GvSV(PL_defgv));
    x1 = sv_newmortal();
    y1 = sv_newmortal();
    value = sv_newmortal();
    GvSV(agv) = x1;
    GvSV(bgv) = y1;
    GvSV(PL_defgv)  = value;
    PUSH_MULTICALL(cv);
    for(y =0; y< newmap->height; ++y){
        for (x = 0; x < newmap->width; ++x){
            sv_setiv(x1,x + newmap->start_x);
            sv_setiv(y1,y + newmap->start_y);
            sv_setiv(value, newmap->map[get_offset_abs(newmap, x,y)]);
            MULTICALL;
            
            newmap->map[get_offset_abs(newmap, x, y)] = SvIV(*PL_stack_sp);
        }
    }
    POP_MULTICALL;
    XSRETURN_EMPTY;
}

#endif

typedef struct map_like * pmap;
static  int path_weigths[10]={50,14,10,14,10,50,10,14,10,14};

bool check_options(pmap map, HV *opts){
    SV ** item;
    if (!hv_exists(opts, "width", 5))
        return 0;
    if (!hv_exists(opts, "height", 6))
        return 0;

    item = hv_fetch(opts, "width", 5, 0);
    map->width = SvIV(*item);
    item = hv_fetch(opts, "height", 6, 0);
    map->height = SvIV(*item);
    return 1;
}

void
inline init_move_offset(pmap map, int * const moves, int trim){
    const int dx = 1;
    const int dy = map->width + 2;
    moves[0] = 0;
    moves[5] = 0;
    moves[1] = -dx + dy;
    moves[2] =     + dy;
    moves[3] = +dx + dy;
    moves[4] = -dx     ;
    moves[6] = +dx     ;
    moves[7] = -dx - dy;
    moves[8] =     - dy;
    moves[9] = +dx - dy;
    if (trim){
        moves[0] = moves[8];
        moves[5] = moves[9];
    }
}

bool
inline on_the_map(pmap newmap, int x, int y){
    if (x< newmap->start_x  ||y< newmap->start_y ){
        return 0;
    }
    else if (x - newmap->start_x >= (int )newmap->width || y - newmap->start_y >= (int)newmap->height){
        return 0;
    }
    return 1;
}
int 
inline get_offset(pmap newmap, int x, int y){
    return ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
}

int 
inline get_offset_abs(pmap newmap, int x, int y){
    return ( (y + 1)*(newmap->width+2) + (x + 1));
}
void
inline get_xy(pmap newmap, int offset, int *x,int *y){
   *x = offset % ( newmap->width + 2) + newmap->start_x - 1;
   *y = offset / ( newmap->width + 2) + newmap->start_y - 1;
}

MODULE = AI::Pathfinding::AStar::Rectangle		PACKAGE = AI::Pathfinding::AStar::Rectangle		

void 
clone(pmap self)
PREINIT:
SV *string;
SV *clone;
    PPCODE:
        string = SvRV(ST(0));
	clone = sv_newmortal();
	sv_setsv( clone, string );
	clone = newRV_inc( clone );

	sv_bless( clone, SvSTASH( string ));
	XPUSHs( sv_2mortal(clone));
	

void 
clone_rect(pmap self, IV begin_x, IV begin_y, IV end_x, IV end_y)
PREINIT:
SV *clone;
struct map_like re_map;
pmap newmap;
size_t map_size;
    PPCODE:
	if (!on_the_map( self, begin_x, begin_y ))
	    croak_xs_usage( cv, "left corner of  rectangle is out of the map" );
	if (!on_the_map( self, end_x, end_y ))
	    croak_xs_usage( cv, "rigth corner of rectangle is out of the map" );
	if ( ! ( begin_x <= end_x ))
	    croak_xs_usage( cv, "attemp made to make zero width rectangle" );
	if ( ! ( begin_y <= end_y ))
	    croak_xs_usage( cv, "attemp made to make zero height rectangle" );
	
	
	clone = sv_newmortal();
	sv_setpvn( clone, "", 0 );

	re_map.width  = end_x - begin_x + 1;
	re_map.height  = end_y - begin_y + 1;
	map_size = sizeof(struct map_like)+(re_map.width + 2) * (re_map.height+2) *sizeof( char );
	SvGROW( clone, map_size ); 

	/* Initializing */
        newmap = (pmap) SvPV_nolen( clone );
        Zero(newmap, map_size, char);
        newmap->width = re_map.width;
        newmap->height = re_map.height;
	newmap->start_x = begin_x;
	newmap->start_y = begin_y;

        SvCUR_set(clone, map_size);
	/*Copy passability */
	if (1) {
	    int x, y;
	    for ( x = begin_x; x <= end_x ; ++x ){
		for ( y = begin_y; y <= end_y; ++y ){
		    newmap->map[ get_offset( newmap, x, y )]=
			self->map[ get_offset( self, x, y )];
		}
	    }

	};
	
	/*Prepare for return full object */
	clone = newRV_inc( clone );
	sv_bless( clone, SvSTASH( SvRV(ST(0) )));
	XPUSHs( sv_2mortal(clone));

void 
new(self, options)
SV * self;
SV * options;
    INIT:
    SV * object;
    struct map_like re_map;
    pmap newmap;
    size_t map_size;
    SV *RETVALUE;
    PPCODE:
        if (!(SvROK(options) && (is_hash(SvRV(options))))){
            croak("Not hashref: USAGE: new( {width=>10, height=>20})");            
        }
        if (!check_options(&re_map, (HV *) SvRV(options))){
            croak("Not enough params: USAGE: new( {width=>10, height=>20})");            
            croak("Fail found mandatory param");
        }
        object  = sv_2mortal(newSVpvn("",0));


        SvGROW(object, map_size = sizeof(struct map_like)+(re_map.width + 2) * (re_map.height+2));

        newmap = (pmap) SvPV_nolen(object);

        Zero(newmap, map_size, char);

        newmap->width = re_map.width;
        newmap->height = re_map.height;
        SvCUR_set(object, map_size);
        RETVALUE = sv_2mortal( newRV_inc(object ));
        sv_bless(RETVALUE, gv_stashpv( SvPV_nolen( self ), GV_ADD));
        XPUSHs(RETVALUE);

void 
start_x(pmap self, int newpos_x = 0 )
    PPCODE:
    if (items>1){
	    self->start_x = newpos_x;
	    XPUSHs(ST(0));
    }
    else {
	mXPUSHi(self->start_x);
    };
    


        

void 
start_y(pmap self, int newpos_y = 0 )
    PPCODE:
    if (items>1){
	self->start_y = newpos_y;
	XPUSHs(ST(0));
    }
    else {
	mXPUSHi(self->start_y);
    }

void 
width(pmap newmap)
    PPCODE:
    XPUSHs(sv_2mortal(newSViv(newmap->width)));

void 
height(pmap newmap)
    PPCODE:
    mXPUSHi(newmap->height);

void
begin_y( pmap self )
PPCODE:
    mXPUSHi(self->start_y);

void
end_y( pmap self )
PPCODE:
    mXPUSHi(self->start_y + (signed) self->height -1) ;

void
begin_x( pmap self )
PPCODE:
    mXPUSHi( self->start_x );

void
end_x( pmap self )
PPCODE:
    mXPUSHi( self->start_x + (signed) self->width -1 );

void 
last_x(pmap self)
    PPCODE:
    mXPUSHi(self->start_x + (signed)self->width -1);



void 
last_y(pmap newmap)
    PPCODE:
    mXPUSHi(newmap->start_y + (signed)newmap->height-1);

void 
set_start_xy(pmap self, x, y)
int x;
int y;
    PPCODE:
	//PerlIO_stdoutf("start(x,y) = (%d,%d)\n", x, y);
        self->start_x = x;
        self->start_y = y;
	//PerlIO_stdoutf("start(x,y) = (%d,%d)\n", self->width, self->height);
	XPUSHs( ST(0) );

void 
get_passability(self, x, y)
SV * self;
int x;
int y;
    INIT:
    pmap newmap;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if ( ! on_the_map( newmap, x, y )){
            XPUSHs(&PL_sv_no);
        }
        else {
            int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
            XPUSHs( sv_2mortal(newSViv( newmap->map[offset])));
        }


void
set_passability(self, x, y, value)
pmap self;
int x;
int y;
int value;
    PPCODE:
        if ( ! on_the_map( self, x, y )){
            warn("x=%d,y=%d outside map", x, y);
            XPUSHs(&PL_sv_no);
	}
        else {
            int offset = ( (y - self->start_y + 1)*(self->width+2) + (x-self->start_x+1));
            self->map[offset] = value;
        };


void
path_goto(self, x, y, path)
SV * self;
int x;
int y;
char *path;
    INIT:
    pmap newmap;
    char * position;
    int moves[10];
    int gimme;
    int offset;
    int weigth;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
        init_move_offset(newmap, moves, 0);
        position = path;

        weigth = 0;
        while(*position){
            if (*position < '0' || *position>'9'){
                goto last_op;
            };


            offset+= moves[ *position - '0'];
            weigth+= path_weigths[ *position - '0' ];
            ++position;
        };
        gimme = GIMME_V;
        if (gimme == G_ARRAY){
            int x,y;
            int norm;
            norm = offset ;

            x = norm % ( newmap->width + 2) + newmap->start_x - 1;
            y = norm / ( newmap->width + 2) + newmap->start_y - 1;
            mXPUSHi(x);
            mXPUSHi(y);
            mXPUSHi(weigth);
        };
        last_op:;


void 
draw_path_xy( pmap newmap, int x, int y, char *path, int value )
    PREINIT:
    char *position;
    int moves[10];
    PPCODE:
        if ( !on_the_map(newmap, x, y) ){
            croak("start is outside the map");
        }
        else {
            int offset = get_offset(newmap, x, y);
            const int max_offset   =  get_offset_abs( newmap, newmap->width, newmap->height);
            const int min_offset   =  get_offset_abs( newmap, 0, 0);
            init_move_offset(newmap, moves,0);
            newmap->map[offset] = value;
            position = path;
            while(*position){
                if (*position < '0' || *position>'9'){
                    croak("bad path: illegal symbols");
                };
                

                offset+= moves[ *position - '0'];
                if (offset > max_offset || offset < min_offset || 
                    offset % (int)(newmap->width + 2) == 0 ||
                    offset % (int)(newmap->width + 2) == (int) newmap->width + 1 ){
                    croak("path otside map");
                }
                newmap->map[offset] = value;
                ++position;
            }       
            get_xy(newmap, offset, &x, &y);
            mXPUSHi(x);
            mXPUSHi(y);
        }

void 
is_path_valid(self, x, y, path)
SV * self;
int x;
int y;
char *path;
    INIT:
    pmap newmap;
    char * position;
    int moves[10];
    int gimme;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if ( ! on_the_map( newmap, x, y )){
            XPUSHs(&PL_sv_no);
        }
        else {
            int offset = ( (y - newmap->start_y + 1)*(newmap->width+2) + (x-newmap->start_x+1));
            int weigth = 0;
            init_move_offset(newmap, moves,0);
            position = path;
            while(*position){
                if (*position < '0' || *position>'9'){
                    XPUSHs(&PL_sv_no);
                    goto last_op;
                };


                offset+= moves[ *position - '0'];
                if (! newmap->map[offset] ){
                    XPUSHs(&PL_sv_no);
                    goto last_op;
                }
                weigth+= path_weigths[ *position - '0' ];
                ++position;
            }
//          fprintf( stderr, "ok");
            gimme = GIMME_V;
            if (gimme == G_ARRAY){
                int x,y;
                int norm;
                norm = offset ;

                x = norm % ( newmap->width + 2) + newmap->start_x - 1;
                y = norm / ( newmap->width + 2) + newmap->start_y - 1;
                mXPUSHi(x);
                mXPUSHi(y);
                mXPUSHi(weigth);
            }            
            XPUSHs(&PL_sv_yes);
        }
        last_op:;

void 
dastar( self, from_x, from_y, to_x, to_y )
int from_x;
int from_y;
int to_x;
int to_y;
SV* self;
    INIT:
    pmap newmap;
    int moves[10];
    struct map_item *layout;
    int current, end_offset, start_offset;
    int *opens;
    int opens_start;
    int opens_end;
    static U8 path_char[8]={'8','1','2','3','4','9','6','7'};
    static int weigths[8]   ={10,14,10,14,10,14,10,14};
    int iter_num;
    int finish[5];
    int map_size;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (!on_the_map(newmap, from_x, from_y) || !on_the_map(newmap, to_x, to_y)){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }
        if (! newmap->map[get_offset(newmap, from_x, from_y)] 
            || ! newmap->map[get_offset(newmap, to_x, to_y)]){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }

        
        start_offset = get_offset(newmap, from_x, from_y);
        end_offset = get_offset(newmap, to_x, to_y);

        if (start_offset == end_offset){
            XPUSHs(&PL_sv_no);
            XPUSHs(&PL_sv_yes);
            goto last_op;
        }

	map_size= (2+newmap->width) * (2+newmap->height);
        Newxz(layout, map_size, struct map_item);
        Newx(opens, map_size, int);

        init_move_offset(newmap, moves, 1);

        opens_start = 0;
        opens_end   = 0;

        iter_num = 0;

        current = start_offset;
        layout[current].g      = 0;

        
	finish[0] = end_offset;
	finish[1] = end_offset+1;
	finish[2] = end_offset-1;
	finish[3] = end_offset+newmap->width+2;
	finish[4] = end_offset-newmap->width-2;
        

        while( current != end_offset){
            int i; 
	    int g;
            if  ( 0
                    || current == finish[1] 
                    || current == finish[2]
                    || current == finish[3]
                    || current == finish[4])
                break;
            layout[current].open   = 0;
            layout[current].closed = 1;
            for(i=1; i<8; i+=2){
                int  nextpoint = current + moves[i];
                if ( layout[nextpoint].closed || newmap->map[nextpoint] == 0 )
                    continue;
                g = weigths[i] + layout[current].g;
                if (layout[nextpoint].open ){
                    if (g < layout[nextpoint].g){
                        // int g0;
                        // g0 = layout[nextpoint].g;
                        layout[nextpoint].g = g;
                        layout[nextpoint].k = layout[nextpoint].h + g ;
                        layout[nextpoint].prev = i;
                    }
                }
                else {
                    int x, y;
                    int h;
                    int abs_dx;
                    int abs_dy;
                    get_xy(newmap, nextpoint, &x, &y);
                    

                    layout[nextpoint].open = 1;
                    abs_dx = abs( x-to_x );
                    abs_dy = abs( y-to_y );
                    // layout[nextpoint].h = h = ( abs_dx + abs_dy )*14;
                    h = ( abs_dx + abs_dy )*10; // Manheton
                    #h = 10 * ((abs_dx> abs_dy)?  abs_dx: abs_dy);
                    layout[nextpoint].h = h ; 

                    // layout[nextpoint].h = h = (abs( x - to_x ) + abs(y -to_y))*14;
                    layout[nextpoint].g = g;
                    layout[nextpoint].k = g + h;
                    layout[nextpoint].prev = i;

                    opens[opens_end++] = nextpoint;
                }
            }


            if (opens_start >= opens_end){
                XPUSHs(&PL_sv_no);
                goto free_allocated;
            }
	    else {
		int index;
		int min_k; 
		index = opens_start;
		min_k = layout[opens[opens_start]].k ; // + layout[opens[opens_start]].h; 

		for (i = opens_start+1; i<opens_end; ++i){
		    int k = layout[opens[i]].k ; // + layout[opens[i]].h;
		    if (min_k> k){
			min_k = k;
			index = i;
		    }
		}
		current = opens[index];
		opens[index] = opens[opens_start];
		++opens_start;
		iter_num++;
	    }
        }

	{ 
	    STRLEN i;
	    SV* path;
	    U8 *path_pv;
	    STRLEN path_len;

	    path = sv_2mortal(newSVpvn("",0));

	    //
	    // 1

	    while(current != start_offset){
		STRLEN i = layout[current].prev;
		sv_catpvn_nomg(path, (char *) &path_char[i], (STRLEN) 1);
		current -= moves[i];
	    };
	    // 2
	    // 3
	    //
	    path_pv = (U8*)SvPV( path, path_len);
	    for(i=0; i<path_len/2; ++i){
		U8 x;
		x = path_pv[path_len-i-1];
		path_pv[path_len - i - 1] = path_pv[i];
		path_pv[ i ] = x;
	    }
	    if (GIMME_V == G_ARRAY){
		XPUSHs(path);
		XPUSHs(&PL_sv_yes);
	    }
	    else {
		XPUSHs(path);
	    }
	}

        free_allocated:;
        (void) Safefree(opens);
        (void) Safefree(layout);
        
        last_op:; // last resort Can't use return

void 
astar( self, from_x, from_y, to_x, to_y )
int from_x;
int from_y;
int to_x;
int to_y;
SV* self;
    INIT:
    pmap newmap;
    int moves[10];
    struct map_item *layout;
    int current, end_offset, start_offset;
    int *opens;
    int opens_start;
    int opens_end;
    static U8 path_char[8]={'8','1','2','3','4','9','6','7'};
    static int weigths[8]   ={10,14,10,14,10,14,10,14};
    int iter_num;
    int index;
    int map_size;
    PPCODE:
        if (!sv_isobject(self))
            croak("Need object");
        newmap = (pmap) SvPV_nolen(SvRV(self));
        if (!on_the_map(newmap, from_x, from_y) || !on_the_map(newmap, to_x, to_y)){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }
        if (! newmap->map[get_offset(newmap, from_x, from_y)] 
            || ! newmap->map[get_offset(newmap, to_x, to_y)]){
            XPUSHs(&PL_sv_no);
            goto last_op;
        }

        
        start_offset = get_offset(newmap, from_x, from_y);
        end_offset = get_offset(newmap, to_x, to_y);

        if (start_offset == end_offset){
            XPUSHs(&PL_sv_no);
            XPUSHs(&PL_sv_yes);
            goto last_op;
        }

	map_size = (2+newmap->width) * (2+newmap->height);
        Newxz(layout, map_size, struct map_item);
        Newx(opens, map_size, int);

        init_move_offset(newmap, moves, 1);

        opens_start = 0;
        opens_end   = 0;

        iter_num = 0;
        current = start_offset;
        layout[current].g      = 0;

        while( current != end_offset){
            int i; 
            layout[current].open   = 0;
            layout[current].closed = 1;
            for(i=0; i<8; ++i){
                int  nextpoint = current + moves[i];
		        int g;
                if ( layout[nextpoint].closed || newmap->map[nextpoint] == 0 )
                    continue;
                g = weigths[i] + layout[current].g;
                if (layout[nextpoint].open ){
                    if (g < layout[nextpoint].g){
                        // int g0;
                        // g0 = layout[nextpoint].g;
                        layout[nextpoint].g = g;
                        layout[nextpoint].k = layout[nextpoint].h + g ;
                        layout[nextpoint].prev = i;
                    }
                }
                else {
                    int x, y;
                    int h;
                    int abs_dx;
                    int abs_dy;
                    get_xy(newmap, nextpoint, &x, &y);
                    

                    layout[nextpoint].open = 1;
                    abs_dx = abs( x-to_x );
                    abs_dy = abs( y-to_y );
                    // layout[nextpoint].h = h = ( abs_dx + abs_dy )*14;
                    h = ( abs_dx + abs_dy )*10; // Manheton
                    #h = 10 * ((abs_dx> abs_dy)?  abs_dx: abs_dy);
                    layout[nextpoint].h = h ; 

                    // layout[nextpoint].h = h = (abs( x - to_x ) + abs(y -to_y))*14;
                    layout[nextpoint].g = g;
                    layout[nextpoint].k = g + h;
                    layout[nextpoint].prev = i;

                    opens[opens_end++] = nextpoint;
                }
            }


            if (opens_start >= opens_end){
                XPUSHs(&PL_sv_no);
                goto free_allocated;
            };



            if (0) {
                int min_f; 
                index = opens_start;
                min_f = layout[opens[opens_start]].g  + layout[opens[opens_start]].h; 

                for (i = opens_start+1; i<opens_end; ++i){
                    int f = layout[opens[i]].g  + layout[opens[i]].h;
                    if (min_f> f){
                        min_f = f;
                        index = i;
                    }
                }

            }
            else {
                int min_k; 
                index = opens_start;
                min_k = layout[opens[opens_start]].k ; // + layout[opens[opens_start]].h; 

                for (i = opens_start+1; i<opens_end; ++i){
                    int k = layout[opens[i]].k ; // + layout[opens[i]].h;
                    if (min_k> k){
                        min_k = k;
                        index = i;
                    }
                }
            }
            current = opens[index];
            opens[index] = opens[opens_start];
            ++opens_start;
            iter_num++;
        }

	{ 
	    STRLEN i;
	    SV* path;
	    U8 *path_pv;
	    STRLEN path_len;

	    path = sv_2mortal(newSVpvn("",0));

	    while(current != start_offset){
		STRLEN i = layout[current].prev;
		sv_catpvn_nomg(path, (char *)&path_char[i], (STRLEN)1);
		current -= moves[i];
	    };
	    path_pv = (U8*)SvPV( path, path_len);
	    for(i=0; i<path_len/2; ++i){
		U8 x;
		x = path_pv[path_len-i-1];
		path_pv[path_len - i - 1] = path_pv[i];
		path_pv[ i ] = x;
	    }
	    if (GIMME_V == G_ARRAY){
		XPUSHs(path);
		XPUSHs(&PL_sv_yes);
	    }
	    else {
		XPUSHs(path);
	    }
	}

        free_allocated:;
        (void) Safefree(opens);
        (void) Safefree(layout);
        
        last_op:; // last resort Can't use return

