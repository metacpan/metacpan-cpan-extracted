#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

MODULE = Dallycot::Processor::XS  PACKAGE = Dallycot::Processor::XS

int add_cost(SV *engine, int delta)
  PREINIT:
    int new_cost;
    int ignore_cost;
    int count;
  CODE:
    PUSHMARK(SP);
    XPUSHs(engine);
    PUTBACK;
    count = call_method("ignore_cost", G_SCALAR);

    SPAGAIN;

    if (count != 1)
      croak("ignore_cost method didn't return a value!");

    ignore_cost = POPi;

    if(ignore_cost) {
      new_cost = 0;
    }
    else {
      PUSHMARK(SP);
      XPUSHs(engine);
      PUTBACK;
      count = call_method("cost", G_SCALAR);

      SPAGAIN;

      if (count != 1)
        croak("cost method didn't return a value!");

      new_cost = POPi;

      new_cost = new_cost + delta;

      PUSHMARK(SP);
      XPUSHs(engine);
      XPUSHs(sv_2mortal(newSVnv(new_cost)));
      PUTBACK;

      call_method("_cost", G_SCALAR);

      SPAGAIN;
    }
    
    RETVAL = new_cost;

  OUTPUT:
    RETVAL

void DEMOLISH(SV *engine, int flag)
  PREINIT:
    int count;
    int has_parent;
    int our_cost;
    SV *parent;
  CODE:
    if(!flag) {
      PUSHMARK(SP);
      XPUSHs(engine);
      PUTBACK;
      count = call_method("has_parent", G_SCALAR);

      SPAGAIN;

      if (count != 1)
        croak("has_parent method didn't return a value!");

      has_parent = POPi;
      if(has_parent) {
        PUSHMARK(SP);
        XPUSHs(engine);
        PUTBACK;
        count = call_method("parent", G_SCALAR);
        SPAGAIN;
        if (count != 1)
          croak("parent method didn't return a value!");
        parent = POPs;

        PUSHMARK(SP);
        XPUSHs(engine);
        PUTBACK;
        count = call_method("cost", G_SCALAR);
        SPAGAIN;
        if (count != 1)
          croak("cost method didn't return a value!");

        our_cost = POPi;
        PUSHMARK(SP);
        XPUSHs(parent);
        XPUSHs(sv_2mortal(newSVnv(our_cost)));
        PUTBACK;
        call_method("add_cost", G_SCALAR);
      }
    }
