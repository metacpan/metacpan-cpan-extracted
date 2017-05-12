#include <string>
#include <vector>
#include <iostream>
#include "apporo.h"
using namespace std;
using namespace apporo;

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}



#endif

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *) obj); \
    }

MODULE = Apporo  PACKAGE = Apporo

Apporo*
Apporo::new(char* config_file_path)
CODE:
  std::string path = (string)config_file_path;
  Apporo *a = new Apporo(path);
  RETVAL = a;
OUTPUT:
  RETVAL

void
Apporo::DESTROY()

AV*
Apporo::retrieve(char* query)
CODE:
  AV *res = newAV();
  string q(query);
  vector <string> vec = THIS->retrieve(q);
  av_extend(res, vec.size() - 1);
  for (size_t i = 0; i < vec.size(); i++) {
    SV *tmp = newSVpv(vec[i].c_str(), 0);
    av_store(res, i, tmp);
  }
  RETVAL = res;
OUTPUT:
  RETVAL
