//-*- Mode: C++ -*-
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "thread.h"
}

#include <stdexcept>
#include <typeinfo>  //-- for typeid()

#include <ConcCommon.h>
#include <QueryCompiler.h>
#include <Query.h>

using namespace std;

/*======================================================================
 * refcount utilities
 */

inline UV ddcxs_obj_refcnt(ddcObject *obj)
{
  return PTR2UV(obj->m_User);
}

inline void ddcxs_obj_refcnt_inc(ddcObject *obj, UV n=1)
{
  obj->m_User = INT2PTR(void*, ddcxs_obj_refcnt(obj)+n);
}

inline void ddcxs_obj_refcnt_dec(ddcObject *obj, UV n=1)
{
  obj->m_User = INT2PTR(void*, ddcxs_obj_refcnt(obj)-n);
}

//#define REFDEBUG(code) code
#define REFDEBUG(code)

//--------------------------------------------------------------
struct ddcxsRefcntIncVisitor
{
  UV n_;
  ddcxsRefcntIncVisitor(UV n=1) : n_(n) {};

  inline bool operator()(ddcObject *obj) {
    if (obj) {
      ddcxs_obj_refcnt_inc(obj, n_);
      REFDEBUG(fprintf(stderr, "[debug] RefIncVisit[n=%u]:INC(obj=%s=%p) --> refcnt=%u\n", n_, obj->jsonClass().c_str(), obj, ddcxs_obj_refcnt(obj)));
    }
    return false;
  };
};

//--------------------------------------------------------------
void ddcxs_refcnt_inc(ddcObject *obj, UV n=1)
{
  if (obj != NULL) {
    ddcxsRefcntIncVisitor visitor(n);
    obj->Traverse(visitor);
  }
}

//--------------------------------------------------------------
struct ddcxsRefcntDecVisitor {
  UV n_;
  ddcxsRefcntDecVisitor(UV n=1) : n_(n) {};

  inline bool operator()(ddcObject *obj) {
    if (!obj) return false;
    if (ddcxs_obj_refcnt(obj) <= n_) {
      //-- last reference: safely delete the object
      REFDEBUG(fprintf(stderr, "[debug] RefDecVisit[n=%u]:DESTROY(obj=%s=%p) --> refcnt=%u\n", n_, obj->jsonClass().c_str(), obj, ddcxs_obj_refcnt(obj)));
      obj->DisownChildren();
      delete obj;
    } else {
      //-- other references exist; just decrement the local reference count
      ddcxs_obj_refcnt_dec(obj, n_);
      REFDEBUG(fprintf(stderr, "[debug] RefDecVisit[n=%u]:DEC(obj=%s=%p) --> refcnt=%u\n", n_, obj->jsonClass().c_str(), obj, ddcxs_obj_refcnt(obj)));
    }
    return false;
  };
};

//--------------------------------------------------------------
void ddcxs_refcnt_dec(ddcObject *obj, UV n=1)
{
  if (obj != NULL) {
    ddcxsRefcntDecVisitor visitor(n);
    obj->TraverseR(visitor);
  }
}

//--------------------------------------------------------------
void ddcxsDumpObjectTree(ddcObject *obj, const string& prefix="") {
  ddcObjectList stack(1,obj);
  list<string>  prefixes(1,prefix);
  while (!stack.empty()) {
    ddcObject *optr = stack.front();
    string     prfx = prefixes.front();
    stack.pop_front();
    prefixes.pop_front();
    fprintf(stderr, "%s+ %s=%p : refcnt=%u\n", prfx.c_str(), (optr ? optr->jsonClass().c_str() : "n/a"), optr, ddcxs_obj_refcnt(optr));

    if (optr != NULL) {
      ddcObjectList kids(optr->Children());
      prfx += "  ";
      for (ddcObjectList::reverse_iterator ki = kids.rbegin(); ki != kids.rend(); ++ki) {
	prefixes.push_front(prfx);
	stack.push_front(*ki);
      }
    }
  }
};

//--------------------------------------------------------------
// macros for object substructure accessors
#define ddcxs_obj_set(VAR,VAL) \
  	ddcxs_refcnt_inc(VAL, ddcxs_obj_refcnt(THIS)); \
	ddcxs_refcnt_dec(THIS->VAR, ddcxs_obj_refcnt(THIS)); \
	THIS->VAR = VAL

#define ddcxs_obj_setvec(TYP,VAR,VAL) \
  	for (TYP::iterator ii=VAL.begin(); ii != VAL.end(); ++ii) ddcxs_refcnt_inc(*ii, ddcxs_obj_refcnt(THIS)); \
	for (TYP::iterator ii=THIS->VAR.begin(); ii != THIS->VAR.end(); ++ii) ddcxs_refcnt_dec(*ii, ddcxs_obj_refcnt(THIS)); \
	THIS->VAR.swap(VAL)

/*======================================================================
 * typemap utilities: typedefs
 */

typedef std::string std_string;
typedef std::set<std::string> set_string;
typedef std::vector<std::string> vector_string;
typedef std::vector<BYTE> vector_BYTE; 	     //-- perl array of integer values in (0..255)
typedef std::vector<BYTE> vector_BYTEasCHAR; //-- perl array of single-character strings as C++ vector<BYTE>
typedef std::vector<char> vector_char;       //-- perl array of single-character strings
typedef std::vector<CQToken*> vector_CQTokenPtr;
typedef std::vector<CQCountKeyExpr*> vector_CQCountKeyExprPtr;

/*======================================================================
 * typemap utilities: classes
 */

//-- should be UNUSED
inline const char *ddcxs_class(const type_info& info)
{
  if      (info == typeid(CQueryCompiler)) return "DDC::XS::CQueryCompiler";
  else if (info == typeid(CQueryOptions)) return "DDC::XS::CQueryOptions";
  //... more special cases here
  warn("ddcxs_class(): unknown C++ class '%s'", info.name());
  string buf("DDC::XS::");
  buf += info.name();
  return buf.c_str();
}

/*======================================================================
 * typemap utilities: atomic
 */

//--------------------------------------------------------------
// fallback
template<typename T> struct ddcxs_typemap {
  inline void perl2c(SV* arg, T& var) {
    throw std::runtime_error(Format("ERROR: ddcxs_typemap<%s>::perl2c() not supported", typeid(T).name()));
  };
  //-- CLASS argument is used for objects
  inline void c2perl(T& var, SV*& arg) {
    throw std::runtime_error(Format("ERROR: ddcxs_typemap<%s>::c2perl() not supported", typeid(T).name()));
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<char> {
  inline void perl2c(SV* arg, char& var) {
    if (SvOK(arg))
      var = *( SvPV_nolen(arg) );
    else
      var = '\0';
  };
  inline void c2perl(char var, SV*& arg) {
    sv_setpvn(arg, &var, 1);
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<BYTE> {
  inline void perl2c(SV* arg, BYTE& var) {
    var = (unsigned char)SvUV(arg);
  };
  inline void c2perl(BYTE var, SV*& arg) {
    sv_setuv(arg, (UV)var);
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<int> {
  inline void perl2c(SV* arg, int& var) {
    var = SvIV(arg);
  };
  inline void c2perl(int var, SV*& arg) {
    sv_setiv(arg,var);
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<unsigned int> {
  inline void perl2c(SV* arg, unsigned int& var) {
    var = SvUV(arg);
  };
  inline void c2perl(unsigned int var, SV*& arg) {
    sv_setuv(arg,var);
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<float> {
  inline void perl2c(SV* arg, float& var) {
    var = SvNV(arg);
  };
  inline void c2perl(float var, SV*& arg) {
    sv_setnv(arg,var);
  };
};

//--------------------------------------------------------------
template<> struct ddcxs_typemap<string> {
  inline void perl2c(SV* arg, string& var) {
    STRLEN clen;
    char *cstr = SvPV(arg, clen);
    var.assign(cstr, clen);
  };
  inline void c2perl(const string& var, SV*& arg) {
    sv_setpvn(arg, var.data(), var.length());
  };
};

//--------------------------------------------------------------
template<typename T> struct ddcxs_typemap<T*> {
  inline void perl2c(SV* arg, T*& var) {
    if (sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG))
      var = INT2PTR(T*, SvIV((SV*)SvRV( arg )));
    else //if (!SvOK(arg))
      var = NULL;
  };
  inline void c2perl(T* var, SV*& arg) {
    if (var == NULL)
      arg = &PL_sv_undef;
    else {
      string CLASS("DDC::XS::");
      CLASS += var->jsonClass();
      sv_setref_pv( arg, CLASS.c_str(), (void*)var );
      ddcxs_refcnt_inc((ddcObject*)var);
      REFDEBUG(fprintf(stderr, "[debug] c2perl(obj=%s=%p,refcnt=%u):RETURN; arg.refcnt=%u\n", ((ddcObject*)var)->jsonClass().c_str(), var, ddcxs_obj_refcnt((ddcObject*)var), SvREFCNT(arg)));
    }
  };
};


/*======================================================================
 * typemap utilities: stl containers
 */

//--------------------------------------------------------------
// stl containers: generic

//------------------------------------------------------
// e.g. ddcxs_container_resize< int, vector<int> >
template<typename T, typename ContainerT >
struct ddcxs_container_resize {
  inline void operator()(ContainerT& var, size_t newsize)
  {};
};

//------------------------------------------------------
// e.g. ddcxs_container_insert< int, vector<int>, ddcxs_typemap<int> >
//  + we specify typemap XT=ddcxs_typemap<T> in addition to T so we can do
//    funky things like vector_BYTEasCHAR which treats vector<BYTE> as a vector
//    of single-character strings by overriding the default XT=ddcxs_typemap<BYTE>
//    with ddcxs_typemap<char>
template<typename T, typename ContainerT, typename XT=ddcxs_typemap<T> >
struct ddcxs_container_insert {
  inline void operator()(int i, SV* sv, ContainerT& var, XT& xt)
  {
    throw std::runtime_error(Format("ERROR: ddcxs_container_insert<%s,%s>.insert(): not supported", typeid(T).name(), typeid(ContainerT).name(), typeid(XT).name()));
  };
};

//------------------------------------------------------
template<typename T, typename ContainerT=vector<T>, typename XT=ddcxs_typemap<T> >
struct ddcxs_xtypemap {
  //--------------------------------------------
  inline void perl2c(SV* arg, ContainerT& var) {
    if (SvROK(arg) && (SvTYPE(SvRV(arg)) == SVt_PVAV) ) {
      //-- AV
      AV *av = (AV*)SvRV( arg );
      int _i, _avlen=av_len(av);
      XT xt;
      ddcxs_container_resize<T,ContainerT>()(var, _avlen+1);
      for (_i=0; _i <= _avlen; _i++) {
	SV **sv = av_fetch(av,_i,0);
	ddcxs_container_insert<T,ContainerT,XT>()(_i, ((sv && *sv) ? *sv : &PL_sv_undef), var, xt);
      }
    }
    else {
      var.clear();
    }
  };

  //--------------------------------------------
  inline void c2perl(ContainerT& var, SV*& arg) {
    AV *av = newAV();
    int _i = 0;
    XT xt;
    av_fill(av, var.size()-1);
    for (typename ContainerT::const_iterator si=var.begin(); si != var.end(); ++si, ++_i) {
      SV **itemsv = av_fetch(av, _i, 1);
      xt.c2perl(*si, *itemsv);
    }
    sv_2mortal((SV*)av);
    arg = newRV((SV*)av);
    sv_2mortal(arg);
  };
};

//--------------------------------------------------------------
// container: set<T>

//------------------------------------------------------
template<typename T> struct ddcxs_container_insert<T, set<T>, ddcxs_typemap<T> > {
  inline void operator()(int i, SV* sv, set<T>& var, ddcxs_typemap<T>& xt)
  {
    T item;
    xt.perl2c(sv,item);
    var.insert(item);
  };
};

//------------------------------------------------------
template<typename T> struct ddcxs_typemap< set<T> >
{
  inline void perl2c(SV* arg, set<T>& var) {
    ddcxs_xtypemap< T, set<T> >().perl2c(arg,var);
  };
  inline void c2perl(set<T>& var, SV*& arg) {
    ddcxs_xtypemap< T, set<T> >().c2perl(var,arg);
  };
};


//--------------------------------------------------------------
// container: list<T>

//------------------------------------------------------
template<typename T> struct ddcxs_container_insert<T, list<T>, ddcxs_typemap<T> > {
  inline void operator()(int i, SV* sv, list<T>& var, ddcxs_typemap<T>& xt)
  {
    T item;
    xt.perl2c(sv,item);
    var.push_back(item);
  };
};

//------------------------------------------------------
template<typename T> struct ddcxs_typemap< list<T> >
{
  inline void perl2c(SV* arg, list<T>& var) {
    ddcxs_xtypemap< T, list<T> >().perl2c(arg,var);
  };
  inline void c2perl(list<T>& var, SV*& arg) {
    ddcxs_xtypemap< T, list<T> >().c2perl(var,arg);
  };
};

//--------------------------------------------------------------
// container: vector<T>

//------------------------------------------------------
template<typename T> struct ddcxs_container_insert<T, vector<T>, ddcxs_typemap<T> > {
  inline void operator()(int i, SV* sv, vector<T>& var, ddcxs_typemap<T>& xt)
  {
    xt.perl2c(sv, var[i]);
  };
};

//------------------------------------------------------
template<typename T>
struct ddcxs_container_resize<T, vector<T> > {
  inline void operator()(vector<T>& var, size_t newsize)
  {
    var.resize(newsize);
  };
};

//------------------------------------------------------
template<typename T> struct ddcxs_typemap< vector<T> >
{
  inline void perl2c(SV* arg, vector<T>& var) {
    ddcxs_xtypemap< T, vector<T> >().perl2c(arg,var);
  };
  inline void c2perl(vector<T>& var, SV*& arg) {
    ddcxs_xtypemap< T, vector<T> >().c2perl(var,arg);
  };
};

//--------------------------------------------------------------
// container: vector_BYTEasCHAR

//------------------------------------------------------
template<> struct ddcxs_container_insert<BYTE, vector<BYTE>, ddcxs_typemap<char> > {
  inline void operator()(int i, SV* sv, vector<BYTE>& var, ddcxs_typemap<char>& xt)
  {
    xt.perl2c(sv, reinterpret_cast<char&>(var[i]));
  };
};


/*======================================================================
 * typemap utilities: high-level wrappers
 */
template<typename T>
inline void ddcxs_perl2c(SV* arg, T& var)
{
  ddcxs_typemap<T>().perl2c(arg,var);
}

template<typename T>
inline void ddcxs_c2perl(T& var, SV*& arg)
{
  ddcxs_typemap<T>().c2perl(var,arg);
}

bool ddcxs_object_ok(SV *arg, bool nullok=true)
{
  return ((sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG)) || (nullok && !SvOK(arg)));
}

/*======================================================================
 * constants
 */
inline const char *build_library_version()
{
  return PACKAGE_VERSION;
}

inline const char *library_version()
{
  return DDCVersionString();
}
