/*
 *
 * Example 2x3x2 structure
 * =======================
 *
 * Rect---+---Map---+---Array---+---Vector---+---NV
 *                  |           |             \--NV
 *                  |           +---Vector---+---NV
 *                  |           |             \--NV
 *                  |            \--Vector---+---NV
 *                  |                         \--NV
 *                   \--Array---+---Vector---+---NV
 *                              |             \--NV
 *                              +---Vector---+---NV
 *                              |             \--NV
 *                               \--Vector---+---NV
 *                                            \--NV
 * 
 * References
 * ==========
 * 
 * Each of Rect, Map, Array, and Vector contains a member 'ref' which is
 * an SV* pointing to an RV. The RV can be returned directly to perl-land
 * after being blessed into its respective class.
 * 
 * The RV references an SV containing an IV. The IV is set to the base
 * address of its component structure. This is so the class code can know
 * which instance of the class is being referred to on callback.
 * 
 * The reference count of the SV has its initial reference count set to one,
 * representing its parents ownership. If a parent dies or a perl-land
 * reference is taken of any componenet, its reference count should
 * be adjusted accordingly.
 * 
 * When the count reaches zero perl will call the classes DESTROY method,
 * at which point we can decrease the reference count on each child and
 * free the component structure.
 * 
 * The intent of all this reference count tom-foolery is to keep the
 * component structures from disappearing from underneath perl-land
 * references to them. As a bonus, we get a neat destruction mechanism
 * without having to reimplement OOP in C.
 */

/*
 * SOM_Vector : holds Z NVs
 *
 * should be allocated:
 *	sizeof(SOM_Vector) + sizeof(NV)*(Z-1)
 *
 * this is enough space to use the 'element' member as the base of an array
 * of Z NVs.
 *
 * the 'ref' element is a pointer to a perl RV referencing a tied array.
 * a copy of 'ref' will be returned to the perl side on request, and the
 * tied array interface can be use to access the members of this struct.
 *
 * 'Z' is of course the number of NVs in the 'element' array.
 */
typedef struct {
	SV *ref;
	IV Z;
	NV element;
} SOM_Vector;

/*
 * SOM_Array : holds Y ptrs to SOM_Vector thingys
 *
 * should be allocated:
 *	sizeof(SOM_Array) + sizeof(SOM_Vector*)*(Y-1)
 *
 * 'ref' and 'vector' elements similar in functionality to the 'ref' and
 * 'element' members, respectively, of the SOM_Vector struct.
 *
 * 'Y' is the number of SOM_Vector pointers in the 'vector' array.
 *
 * 'Z' is provided here only for propogation down the line in creating
 * the SOM_Vectors.
 */
typedef struct {
	SV *ref;
	IV Y;
	IV Z;
	SOM_Vector *vector;
} SOM_Array;

/*
 * SOM_Map : holds X ptrs to SOM_Array thingys
 *
 * should be allocated:
 *	sizeof(SOM_Map) + sizeof(SOM_Array*)*(X-1)
 *
 * 'ref' and 'array' are similar in functionality to the 'ref' and 'element'
 * members, respectively, of the SOM_Vector struct.
 *
 * 'X' is the number of SOM_Array pointers in the 'array' array.
 *
 * 'Y' and 'Z' are provided here only for propagation down the line in
 * creation of SOM_Array and SOM_Vector structs.
 */
typedef struct {
	SV *ref;
	IV X;
	IV Y;
	IV Z;
	SOM_Array *array;
} SOM_Map;

/*
 * SOM_Rect : holds a ptr to a single SOM_Map thingy
 *
 * should be allocated:
 *	sizeof(SOM_Rect)
 *
 * this struct is the main object.
 *
 * 'X', 'Y', and 'Z' are held here for progagation down to the structs
 * that make up our grid map.
 *
 * '_R'      = initial SOM radius
 * '_Sigma0' = ???
 * '_L0'     = initial SOM learning rate
 *
 * 'output_dim' is kept from instantiation simply because the perl interface
 * already provides access to it.
 */
typedef struct {
	SV *ref;
	IV X;
	IV Y;
	IV Z;
	NV R;
	NV Sigma0;
	NV L0;
	NV LAMBDA;
	NV T;
	int type;
	SV *output_dim;
	AV *labels;
	SOM_Map *map;
} SOM_GENERIC;

typedef SOM_GENERIC SOM_Rect;
typedef SOM_GENERIC SOM_Torus;
typedef SOM_GENERIC SOM_Hexa;

enum SOMType {
	SOMType_Hexa,
	SOMType_Rect,
	SOMType_Torus
};

typedef AV AV_SPECIAL;

#ifndef PERL_MAGIC_tied
#define PERL_MAGIC_tied 'P'
#endif

#ifndef Newx
#define Newx(ptr,nitems,type) New(0,ptr,nitems,type)
#endif

#ifndef Newxc
#define Newxc(ptr,nitems,type,cast) Newc(0,ptr,nitems,type,cast)
#endif

#ifndef Newxz
#define Newxz(ptr,nitems,type) Newz(0,ptr,nitems,type)
#endif

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(x) ((void)x)
#endif

#define selfmg2iv(self,mg) SvIV(SvRV(SvTIED_obj((SV*)SvIV(SvRV(self)),mg)))
#define self2iv(self) SvIV(SvRV(self))

#define selfmagic(self) SvTIED_mg((SV*)SvRV(self), PERL_MAGIC_tied)

#define self2somptr(self,mg) INT2PTR(SOM_GENERIC*,selfmg2iv(self,mg))

#define tied2ptr(self) (INT2PTR(SOM_GENERIC*,SvIV(SvRV(self))))

