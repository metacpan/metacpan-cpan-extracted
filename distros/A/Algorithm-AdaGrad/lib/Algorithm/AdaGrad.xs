#define PERL_NO_GET_CONTEXT

#include "AdaGrad.hpp"
#include <string>
#include <fstream>

#define do_open Perl_do_open
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#if __cplusplus < 201103L
#include <tr1/unordered_map>
namespace std {
    using namespace std::tr1;
}
#else
#include <unordered_map>
#endif

#define MAGIC 1

enum {
    POSITIVE_LABEL = 1,
    NEGATIVE_LABEL = -1,
};

typedef std::unordered_map<std::string, AdaGrad*> classifers_type;

typedef struct AdaGradS {
    classifers_type* classifers;
    double eta;
}* AdaGradPtr;

#define GET_ADAGRAD_PTR(x) get_adagrad(aTHX_ x, "$self")


static AdaGradPtr get_adagrad(pTHX_ SV* object, const char* context) {
    SV *sv;
    IV address;

    if (MAGIC) SvGETMAGIC(object);
    if (!SvROK(object)) {
        if (SvOK(object)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }
    sv = SvRV(object);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    if(!sv_derived_from(object,"Algorithm::AdaGrad")) {
        croak("%s is not a Algorithm::AdaGrad", context);
    }
    address = SvIV(sv);
    if (!address)
    croak("Algorithm::AdaGrad object %s has a NULL pointer", context);
    return INT2PTR(AdaGradPtr, address);
}

static double getDoubleValue(pTHX_ SV* sv, const char* errMsg) {
    svtype svt = SvTYPE(sv);
    if(svt != SVt_NV && svt != SVt_IV){
        croak(errMsg);
    }
    double ret;
    if(svt == SVt_IV){
        ret = SvIV(sv);
    }else{
        ret = SvNV(sv);
    }
    return ret;
}

static void handleUpdate(pTHX_ AdaGradPtr self, SV* sv) {
    SvGETMAGIC (sv);
    
    if(!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) {
        croak("Invalid parameter: parameter must be HASH-reference");
    }

    HV* hv = (HV*)SvRV(sv);
    STRLEN len;

    SV** tmpSV = hv_fetchs(hv, "label", 0);
    if(tmpSV == NULL) {
        croak("Invalid parameter: \"label\" does not exist.");
    } else if(SvTYPE(*tmpSV) != SVt_IV){
        croak("Invalid parameter: \"label\" must be 1 or -1.");
    }
    IV label = SvIV(*tmpSV);
    if(label != POSITIVE_LABEL && label != NEGATIVE_LABEL){
        croak("Invalid parameter: \"label\" must be 1 or -1.");
    }
    
    tmpSV = hv_fetchs(hv, "features", 0);
    if(tmpSV == NULL) {
        croak("Invalid parameter: \"features\" does not exist.");
    } else if(!SvROK(*tmpSV) || SvTYPE(SvRV(*tmpSV)) != SVt_PVHV) {
        croak("Invalid parameter: \"features\" must be HASH-reference.");
    }
    HV* features = (HV*)SvRV(*tmpSV);

    hv_iterinit(features);
    HE* he = NULL;
    std::unordered_map<std::string, AdaGrad*>& classifers = *(self->classifers);
    while ((he = hv_iternext(features))){
        char* key = HePV(he, len);
        std::string featStr = std::string(key, len);
        SV* val = HeVAL(he);
        double gradient = getDoubleValue(val, "Invalid parameter: type of internal \"features\" must be number.");
        gradient *= -1.0 * label;
        if(classifers.find(featStr) == classifers.end()){
            classifers.insert(std::make_pair(featStr, new AdaGrad(self->eta)));
        }
        AdaGrad* ag = classifers[featStr];
        ag->update(gradient);
    }
}


static void _save(pTHX_ AdaGradPtr self, SV* sv) {
    if(SvTYPE(sv) != SVt_PV && SvTYPE(sv) != SVt_PVMG){
        croak("Invalid parameter: the parameter must be string.");
    }
    STRLEN len;
    const char* filename = SvPV(sv, len);
    std::ofstream ofs(filename);
    std::unordered_map<std::string, AdaGrad*>& classifers = *(self->classifers);
    
    ofs.write(reinterpret_cast<const char*>(&(self->eta)), sizeof(double));
    size_t featureNum = classifers.size();
    ofs.write(reinterpret_cast<const char*>(&featureNum), sizeof(size_t));
    
    std::unordered_map<std::string, AdaGrad*>::iterator iter = classifers.begin();
    std::unordered_map<std::string, AdaGrad*>::iterator iter_end = classifers.end();  
    for(;iter != iter_end; ++iter){
        size_t size = iter->first.size();
        ofs.write(reinterpret_cast<const char*>(&size), sizeof(size_t));
        ofs.write(iter->first.c_str(), sizeof(char) * size);
        iter->second->save(ofs);
    }
    if(ofs.fail()) {
        croak("Failed to save file: %s", filename);
    }
    ofs.close();
}

static void _load(pTHX_ AdaGradPtr self, SV* sv) {
    if(SvTYPE(sv) != SVt_PV && SvTYPE(sv) != SVt_PVMG){
        croak("Invalid parameter: the parameter must be string.");
    }
    STRLEN len;
    const char* filename = SvPV(sv, len);
    
    std::ifstream ifs(filename);
    
    ifs.read(reinterpret_cast<char*>(&(self->eta)), sizeof(double));
    
    size_t featNum = 0;
    ifs.read(reinterpret_cast<char*>(&featNum), sizeof(size_t));
    
    std::unordered_map<std::string, AdaGrad*>& classifers = *(self->classifers);
    classifers.clear();
    
    for(size_t i = 0; i < featNum; ++i){
        size_t size = 0;
        ifs.read(reinterpret_cast<char*>(&size), sizeof(size_t));
        char* feature = new char[size];
        ifs.read(feature, sizeof(char) * size);
        std::string featStr(feature, size);
        delete[] feature;
        AdaGrad* newObj = new AdaGrad();
        newObj->load(ifs);
        classifers.insert(std::make_pair(featStr, newObj));
    }
    
    if(ifs.fail()) {
        croak("Failed to load file: %s", filename);
    }
    
    ifs.close();
}


MODULE = Algorithm::AdaGrad PACKAGE = Algorithm::AdaGrad

PROTOTYPES: DISABLE

AdaGradPtr
new(const char *klass, ...)
PREINIT:
    double eta = 0.0;
CODE:
{
    if(items > 1){
        SV* arg_sv = ST(1);
        eta = getDoubleValue(arg_sv, "Parameter must be a number.");
    }
    AdaGradPtr obj = NULL;
    New(__LINE__, obj, 1, struct AdaGradS);
    obj->classifers = new classifers_type();
    obj->eta = eta;
    RETVAL = obj;
}
OUTPUT:
    RETVAL

int
update(AdaGradPtr self, SV* sv)
CODE:
{   
    SvGETMAGIC (sv);
    if(!SvROK(sv) || SvTYPE(SvRV(sv)) !=  SVt_PVAV) {
        croak("Parameter must be ARRAY-reference");
    }

    AV* av = (AV*)SvRV(sv);
    size_t arraySize = av_len(av);
    for(size_t i = 0; i <= arraySize; ++i){
        SV** elm = av_fetch(av, i, 0);
        if(elm != NULL){
            handleUpdate(self, *elm);       
        }
    }
    RETVAL = 0;
}
OUTPUT:
    RETVAL

int
classify(AdaGradPtr self, SV* sv)
CODE:
{
    if(!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) {
        croak("Invalid parameter: Parameter must be HASH-reference.");
    }
    
    HV* features = (HV*)SvRV(sv);

    hv_iterinit(features);
    HE* he = NULL;
    STRLEN len;
    std::unordered_map<std::string, AdaGrad*>& classifers = *(self->classifers);
    double margin = 0.0;
    while ((he = hv_iternext(features))){
        char* key = HePV(he, len);
        std::string featStr = std::string(key, len);
        classifers_type::const_iterator iter = classifers.find(featStr);
        if(iter == classifers.end()){
            continue;
        }
        AdaGrad* ag = iter->second;
        
        SV* val = HeVAL(he);
        double gradient = getDoubleValue(val, "Invalid parameter: type of parameter must be number.");
        margin += ag->classify(gradient);
    }

    RETVAL = margin >= 0 ? POSITIVE_LABEL : NEGATIVE_LABEL;
}
OUTPUT:
    RETVAL


void save(AdaGradPtr self, SV* sv)
CODE:
{
    _save(self, sv);
}

void
load(AdaGradPtr self, SV* sv)
CODE:
{
    _load(self, sv);
}
    
void
DESTROY(AdaGradPtr self)
CODE:
{
    std::unordered_map<std::string, AdaGrad*>& classifers = *(self->classifers);
    std::unordered_map<std::string, AdaGrad*>::iterator iter = classifers.begin();
    std::unordered_map<std::string, AdaGrad*>::iterator iter_end = classifers.end();   
    for(;iter != iter_end; ++iter){
        Safefree(iter->second);
    }
    Safefree (self->classifers);
    Safefree (self);
}

