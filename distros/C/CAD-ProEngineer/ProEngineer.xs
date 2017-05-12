
/* CAD::ProEngineer.xs
 *
 * Copyright (c) 2003 Marc Mettes
 *
 * See COPYRIGHT section in ProEngineer.pm for usage and distribution rights.
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "ProToolkit.h"
#include "ProUtil.h"
#include "ProMenu.h"
#include "ProMenuBar.h"
#include "ProUICmd.h"
#include "ProParameter.h"
#include "ProDimension.h"



/* bless_safefree()

   Generates a blessed object from a pointer.  Will mark the object for 
   use with Safefree() if 'add_safefree' is TRUE.  The object is compatible 
   with blessed objects created by sv_setref_pv().

   In the context of a VisitAction or VisitFilter function, we should not 
   be attempting to free the object pointer when perl destroys the object.  
   This function can flag the new perl object so that Safefree() will not 
   be called.
*/
/* */
SV* bless_safefree(char *class_name, void *ptr, int add_safefree) {
  SV *tmp_sv, *rv;

  tmp_sv = newSV(0);
  sv_setiv(tmp_sv, PTR2IV(ptr));
  sv_setpv(tmp_sv, (add_safefree ? "safefree" : "Do not safefree this object!"));
  SvIOK_on(tmp_sv);

  rv = (SV *)newRV_noinc((SV *)tmp_sv);
  sv_bless(rv, gv_stashpv(class_name,FALSE));

  /* printf("class_name: %s\n", HvNAME(gv_stashpv(class_name,FALSE))); */
  /* printf("Object: |%s| |%d|\n", SvPV_nolen((SV*)SvRV(rv)), SvIV((SV*)SvRV(rv)) ); */
  /* printf("sv_isobject:%d   sv_derived_from:%d  sv_isa:%d\n", 
         sv_isobject(rv), sv_derived_from(rv, "CAD::ProEngineer::ProModelitem"),
         sv_isa(rv, "CAD::ProEngineer::ProModelitem")); */

  /* Was this, but we need to be able to flag objects for Safefree */
  /* promdlitem_sv = newSV(0); */
  /* sv_setref_pv(promdlitem_sv, "CAD::ProEngineer::ProModelitem", (void*)modelitem); */

  return(rv);
}



/* std_DESTROY()

   Common code for object destructor.
*/
/* */
int std_DESTROY(SV *rv) {
  void *ptr;

  IV tmp = SvIV((SV*)SvRV(rv));
  ptr = INT2PTR(void *,tmp);

  if (strEQ(SvPV_nolen((SV*)SvRV(rv)), "safefree")) {
    Safefree(ptr);
    return(TRUE);
  }
  else {
    return(FALSE);
  }
}


/*
*/
/* */
void* get_ptr_from_object(SV *stack_item, char *class_name) {

  void *ptr=NULL;
  /* int ax; */

  if (sv_derived_from(stack_item, class_name)) {
    /* Perl object to C pointer conversion here */
    IV tmp = SvIV((SV*)SvRV(stack_item));
    ptr = INT2PTR(void *,tmp);
  }

  return(ptr);
}


uiCmdAccessState std_uiCmdAccessState_ACCESS_AVAILABLE(uiCmdAccessMode access_mode) {
  /* printf("  returning ACCESS_AVAILABLE %d\n", ACCESS_AVAILABLE); */
  return(ACCESS_AVAILABLE);
}



int std_uiCmdCmdActFn(uiCmdCmdId command, uiCmdValue *p_value, void *p_push_command_data) {

  dSP ; /* declares variables, must be first entry in function */
  IV ptr_iv;

  /* printf("start std_uiCmdCmdActFn - command = %d\n", command); */
  ptr_iv = PTR2IV(command);

  ENTER ;
  SAVETMPS ;

  PUSHMARK(SP) ;
  XPUSHs(sv_2mortal(newSVpv("uiCmdCmdActFn", 0)));
  XPUSHs(sv_2mortal(newSViv(ptr_iv)));
  PUTBACK ;

  call_pv("CAD::ProEngineer::Execute_Callback", G_DISCARD);

  FREETMPS ;
  LEAVE ;

  return(0); /* Return value is ignored */
}


ProError std_VisitAction(void *handle, ProError status, ProAppData data) {

  dSP ; /* declares variables, must be first entry in function */
  I32 ax=0 ;
  SV *handle_sv, *rv_handle;
  SV *rv_visit_action_cv, *rv_user_appdata, *visit_type_sv;
  HV *sys_appdata_hv;
  char *visit_action_key="VisitAction", *visit_filter_key="VisitFilter", 
       *visit_appdata_key="AppData", *visit_type_key="Type";
  int count;
  ProError err;

  sys_appdata_hv = (HV *)data;
  if (SvTYPE(sys_appdata_hv) != SVt_PVHV) {
    printf("sys_appdata_hv is not an hv!\n");
  }

  /* Fetch the visit action cv ref */
  /* */
  rv_visit_action_cv = *hv_fetch(sys_appdata_hv, visit_action_key, strlen(visit_action_key), FALSE);
  if (rv_visit_action_cv == &PL_sv_undef || SvTYPE(SvRV(rv_visit_action_cv)) != SVt_PVCV) {
    printf("rv_visit_action_cv is not an cv ref!\n");
    return(PRO_TK_NO_ERROR); /* return if no sub to run */
  }

  /* Fetch the user's appdata ref */
  /* */
  rv_user_appdata = *hv_fetch(sys_appdata_hv, visit_appdata_key, strlen(visit_appdata_key), FALSE);
  if (!SvROK(rv_user_appdata)) {
    printf("rv_user_appdata is not a ref!\n");
  }

  /* Fetch the perl object class name, for blessing the handle ref */
  /* */
  visit_type_sv = *hv_fetch(sys_appdata_hv, visit_type_key, strlen(visit_type_key), FALSE);
  if (SvTYPE(visit_type_sv) != SVt_PV) {
    printf("visit_type_sv is not a scalar pv\n");
  }

  /* Bless the ref, note use of FALSE here so that DESTROY() does not attempt
     to Safefree the pointer.  The visit function will free the pointer itself. */
  /* */
  rv_handle = (SV *)bless_safefree(SvPV_nolen(visit_type_sv), (void*)handle, FALSE);

  ENTER ;
  SAVETMPS;

  PUSHMARK(SP) ;
  XPUSHs(sv_2mortal(rv_handle));
  XPUSHs(sv_2mortal(newSViv(status)));
  XPUSHs(rv_user_appdata); /* Do not mortalize! */
  PUTBACK ;

  count = call_sv(rv_visit_action_cv, G_SCALAR);

  SPAGAIN ;

  if (count >= 1) {
    err = POPi;
  }

  PUTBACK ;
  FREETMPS ;
  LEAVE ;

  if (count < 1) {
    printf("Wrong number of return values.\n") ;
    /* XSRETURN_UNDEF; */
    return(PRO_TK_GENERAL_ERROR);
  }

  /* printf("err = %d\n", err); *.
  /* return(PRO_TK_NO_ERROR); */
  return(err);
}


ProError std_VisitFilter(void *handle, ProAppData data) {

  dSP ; /* declares variables, must be first entry in function */
  I32 ax=0 ;
  SV *handle_sv, *rv_handle;
  SV *rv_visit_filter_cv, *rv_user_appdata, *visit_type_sv;
  HV *sys_appdata_hv;
  char *visit_action_key="VisitAction", *visit_filter_key="VisitFilter", 
       *visit_appdata_key="AppData", *visit_type_key="Type";
  int count;
  ProError err;

  sys_appdata_hv = (HV *)data;
  if (SvTYPE(sys_appdata_hv) != SVt_PVHV) {
    printf("sys_appdata_hv is not an hv\n");
  }

  /* Fetch the visit filter cv ref */
  /* */
  rv_visit_filter_cv = *hv_fetch(sys_appdata_hv, visit_filter_key, strlen(visit_filter_key), FALSE);
  if (rv_visit_filter_cv == &PL_sv_undef || SvTYPE(SvRV(rv_visit_filter_cv)) != SVt_PVCV) {
    /* printf("rv_visit_filter_cv is not an cv ref!\n"); */
    return(PRO_TK_NO_ERROR);
  }

  /* Fetch the user's appdata ref */
  /* */
  rv_user_appdata = *hv_fetch(sys_appdata_hv, visit_appdata_key, strlen(visit_appdata_key), FALSE);
  if (!SvROK(rv_user_appdata)) {
    printf("rv_user_appdata is not a ref!\n");
  }

  /* Fetch the perl object class name, for blessing the handle ref */
  /* */
  visit_type_sv = *hv_fetch(sys_appdata_hv, visit_type_key, strlen(visit_type_key), FALSE);
  if (SvTYPE(visit_type_sv) != SVt_PV) {
    printf("visit_type_sv is not a scalar pv\n");
  }

  /* Bless the ref, note use of FALSE here so that DESTROY() does not attempt
     to Safefree the pointer.  The visit function will free the pointer itself. */
  /* */
  rv_handle = (SV *)bless_safefree(SvPV_nolen(visit_type_sv), (void*)handle, FALSE);

  ENTER ;
  SAVETMPS;

  PUSHMARK(SP) ;
  XPUSHs(sv_2mortal(rv_handle));
  XPUSHs(rv_user_appdata); /* Do not mortalize! */
  PUTBACK ;

  count = call_sv(rv_visit_filter_cv, G_SCALAR);

  SPAGAIN ;

  if (count >= 1) {
    err = POPi;
  }

  PUTBACK ;
  FREETMPS ;
  LEAVE ;

  if (count < 1) {
    printf("Wrong number of return values.\n") ;
    /* XSRETURN_UNDEF; */
    return(PRO_TK_GENERAL_ERROR);
  }

  /* printf("err = %d\n", err); */
  /* return(PRO_TK_NO_ERROR); */
  return(err);
}


static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return(-1);
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return(0);
}


MODULE = CAD::ProEngineer		PACKAGE = CAD::ProEngineer		


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


void
ProToolkitMain(...)
  INIT:
    int item_idx = 0, total_items = 0;
    SV *object;
    SV *old_argc;
    SV *args;
    AV *global_args;
    int i;
    I32 lastarg;
    char **newargs, *progname = "";
    SV *tmp;
    HV *oldstash = PL_curstash;

  CODE:
    /* Check for object oriented calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (total_items == 0) { /* Function call (zero arg) */
      /* No args given, so use global @ARGV instead */
      if ((global_args = get_av("ARGV", FALSE)) == NULL) {
	croak("Global ARGV array does not exist!!");
      }
      args = newRV_inc((SV *)global_args);
      /* printf("  Zero args given\n"); */
    }
    else if (total_items == 1) { /* Function call (one arg) */
      args = ST(item_idx);
      /* printf("  One arg given\n"); */
    }
    else if (total_items == 2) { /* Function call (two args), or object oriented (one arg) */
      args = ST(item_idx+1);
      /* printf("  Two args given\n"); */
    }
    else { /* Bad number of arguments, croak */
      croak("bad args!");
    }
    
    if ((!SvROK(args)) || (SvTYPE(SvRV(args)) != SVt_PVAV) || ((lastarg = av_len((AV *)SvRV(args))) < 0)) {
        croak("Not a reference to an array, or array is empty!");
        /* XSRETURN_UNDEF; */
    }

    /* printf(" stash: %s\n", HvNAME(oldstash)); */
    /* printf(" lastarg: %d\n", lastarg); */

    /* put command line args into char** */
    /* */
    New(0, newargs, lastarg+2, char *);

    /* perl strips argv[0], but ProToolkitMain() needs it */
    /* */
    New(0, newargs[0], strlen(progname)+1, char);
    strcpy(newargs[0], progname);
    /* printf("newargs %d: %s\n", 0, newargs[0]); */

    /* Loop through array, add elements to char** */
    /* */
    for (i=0; i<=lastarg; i++) {
      tmp = *av_fetch((AV *)SvRV(args), i, 0);
      New(0, newargs[i+1], SvLEN(tmp)+1, char);
      strcpy(newargs[i+1], SvPV_nolen(tmp));
      /* printf("newargs %d: %s\n", i+1, newargs[i+1]); */
    }

    /* Startup Pro/Toolkit main, which takes control */
    /* */
    ProToolkitMain(lastarg+2,newargs);

    /* Free up the pointers, but will this actually be called?? */
    /* */
    for (i=0; i<=lastarg+1; i++) {
      Safefree(newargs[i]);
    }
    Safefree(newargs);



void
ProMessageDisplay(...)
  INIT:
    int item_idx = 0, total_items = 0;
    char *msg_file, *format_str;
    ProFileName msg_file_wstr;
    ProCharLine out_str;
    ProLine out_wstr;
    void *b[10];
    int i, j=0;
    ProError err;
    SV *buf;
    STRLEN len = 0;
  ALIAS:
    ProMessageToBuffer = 1
  PPCODE:
    /* Check for object oriented calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    /* Check whether *ToBuffer */
    /* */
    buf = ST(item_idx);
    if (ix == 1) {
      if (SvROK(buf) && ( SvTYPE(SvRV(buf))==SVt_PV || SvTYPE(SvRV(buf))==SVt_IV || SvTYPE(SvRV(buf))==SVt_NV )) {
        total_items--;
        item_idx++;
      }
      else {
        /* Output buffer not given in arg list */
        buf = NULL;
      }
    }

    /* printf("before arg checks\n"); */
    if (total_items < 2 || total_items > 12) {
      XSRETURN_UNDEF;
    }

    /* Extract message file and format string args */
    /* */
    format_str = SvPV_nolen(ST(item_idx+1));
    msg_file = SvPV_nolen(ST(item_idx));
    /* printf("msg_file:%s:   format_str:%s:\n", msg_file, format_str); */
    /* printf("total_items:%d:   item_idx:%d:\n", total_items, item_idx); */

    /* Extract variables args */
    /* */
    for (i=0; i<10; i++) {
      SV *tmp_sv;
      int *tmp_int;
      double *tmp_dbl;
      /* printf("  i=%d\n", i); */
      if (i < total_items-2) {
	tmp_sv = ST(item_idx+2+i);
	/* printf("    (IOK,NOK,POK)=(%d,%d,%d) (IOKp,NOKp,POKp)=(%d,%d,%d)\n", 
	       SvIOK(tmp_sv), SvNOK(tmp_sv), SvPOK(tmp_sv), 
	       SvIOKp(tmp_sv), SvNOKp(tmp_sv), SvPOKp(tmp_sv) ); */
	if (SvPOK(tmp_sv)) {
          New(0, b[i], SvCUR(tmp_sv)+1, char);
          /* printf("Newing char b[%d]\n", i); */
          strcpy(b[i], SvPV_nolen(tmp_sv)); /* MSVC doesn't like ptr assignment here, OK on Solaris */
	  /* printf("    char b[%d]: %s (%s)\n", i, b[i], SvPV_nolen(tmp_sv)); */
	}
	else if (SvNOK(tmp_sv)) {
          New(0, tmp_dbl, 1, double);
          /* printf("Newing char b[%d]\n", i); */
	  *tmp_dbl = SvNV(tmp_sv);
	  b[i] = tmp_dbl;
	  /* printf("    dbl b[%d]: %f\n", i, *tmp_dbl);  */
	}
	else if (SvIOK(tmp_sv)) {
          New(0, tmp_int, 1, int);
          /* printf("Newing char b[%d]\n", i); */
	  *tmp_int = SvIV(tmp_sv);
	  b[i] = tmp_int;
	  /* printf("    int b[%d]: %d\n", i, *tmp_int);  */
	}
	else {
	  /* Not a string, integer, or float ? */
	  /* */
	  XSRETURN_UNDEF;
	}
	/* printf("    SvCur=%d (%d,%d,%d) (%d,%d,%d)\n", SvCUR(tmp_sv),
	       SvIOK(tmp_sv), SvNOK(tmp_sv), SvPOK(tmp_sv), 
	       SvIOKp(tmp_sv), SvNOKp(tmp_sv), SvPOKp(tmp_sv) ); */
	/* printf("    Val=(%s,%d,%f)\n", SvPV_nolen(tmp_sv), SvIV(tmp_sv), SvNV(tmp_sv)); */
      }
      else {
	b[i] = NULL;
      }
    }
    ProStringToWstring(msg_file_wstr, msg_file);

    if (ix == 1) {
      err = ProMessageToBuffer(out_wstr,msg_file_wstr,format_str,b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9]);
      ProWstringToString(out_str, out_wstr);
      if (buf == NULL) {
        /* Return answer */
        XPUSHs(sv_2mortal(newSVpv(out_str,len)));
      }
      else {
        sv_setpv(SvRV(buf), out_str);
      }
      if (GIMME_V == G_ARRAY) {
        /* If list context, return list with err as 2nd item */
        XPUSHs(sv_2mortal(newSViv(err)));
      }
    }
    else {
      err = ProMessageDisplay(msg_file_wstr,format_str,b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9]);
      /* Return err */
      XPUSHs(sv_2mortal(newSViv(err)));
    }
    /* Free the memory that we allocated */
    for (i=0; i<10; i++) {
      if (b[i] != NULL) {
        /* printf("freeing: b[%d]\n", i); */
        Safefree(b[i]);
      }
    }



void
ProMessageClear(...)
  PPCODE:
    ProMessageClear();



void
ProMessageRead(...)
  INIT:
    SV *limit;
    SV *answer;
    int def_string_limit = 127;
    int use_default_limit = 0;
    int item_idx = 0, total_items = 0;
    int answer_wstr_len = def_string_limit;
    wchar_t *answer_wstr;
    char *answer_str;
    ProError err;
    STRLEN len = 0;
  ALIAS:
    ProMessageStringRead = 1
    ProMessagePasswordRead = 2
  PPCODE:
    /* printf(" items: %d\n", items); */
    /* printf(" ix: %d\n", ix); */

    /* Check for object oriented calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    /* printf("before arg checks\n"); */
    if (total_items == 0) {
      use_default_limit = 1;
      limit = NULL;
    }
    else if (total_items == 1) {
      limit = ST(item_idx);
    }
    else if (total_items == 2) {
      limit = ST(item_idx);
      answer = ST(item_idx+1);
    }
    else { /* Bad arguments, croak */
      croak("bad args!");
    }

    /* printf("before limit extraction\n"); */
    if (!use_default_limit && SvIOK(limit) && SvIV(limit) > 0 && SvIV(limit) <= def_string_limit) {
      answer_wstr_len = SvIV(limit);
    }
    New(0, answer_wstr, answer_wstr_len+1, wchar_t);

    /* printf("before switch\n"); */
    switch (ix) {

      case 0:
      case 1:
	printf("ProMessageStringRead, limit=%d\n", answer_wstr_len);
	err = ProMessageStringRead(answer_wstr_len, answer_wstr);
	break;

      case 2:
	printf("ProMessagePasswordRead, limit=%d\n", answer_wstr_len);
	err = ProMessagePasswordRead(answer_wstr_len, answer_wstr);
	break;

    }

    New(0, answer_str, answer_wstr_len+1, char);
    ProWstringToString(answer_str,answer_wstr);
    /* printf("  - answer_str:%s:  err:%d:\n", answer_str, err); */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setpv(answer, answer_str);
      /* Return err */
      XPUSHs(sv_2mortal(newSViv(err)));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(newSVpv(answer_str,len)));
      if (GIMME_V == G_ARRAY) {
	/* If list context, return list with err as 2nd item */
	XPUSHs(sv_2mortal(newSViv(err)));
      }
    }
    Safefree(answer_wstr);
    Safefree(answer_str);



void
ProMessageNumRead(...)
  INIT:
    SV *object;
    SV *limit;
    SV *answer;
    SV *tmp;
    int use_default_limit = 0;
    int answer_int = 0;
    int item_idx = 0, total_items = 0;
    int limit_int[2], *int_ptr = NULL, last_item, i, limit_count = 0;
    double answer_double = 0;
    double limit_dbl[2], *dbl_ptr = NULL;
    ProError err;
  ALIAS:
    ProMessageIntegerRead = 1
    ProMessageDoubleRead = 2
  PPCODE:
    /* printf(" items: %d\n", items); */
    /* printf(" ix: %d\n", ix); */

    /* Check for object oriented calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    /* printf("before arg checks\n"); */
    if (total_items == 0) {
      use_default_limit = 1;
      limit = NULL;
    }
    else if (total_items == 1) {
      limit = ST(item_idx);
    }
    else if (total_items == 2) {
      limit = ST(item_idx);
      answer = ST(item_idx+1);
    }
    else { /* Bad arguments, croak */
      croak("bad args!");
    }

    /* printf("before limit extraction\n"); */
    if (!use_default_limit) {

      /* Is limit: (not a reference), or (not a ref to a list), or (not having 2 elements) ?
      /* */
      if ((!SvROK(limit)) || (SvTYPE(SvRV(limit)) != SVt_PVAV) || ((last_item = av_len((AV *)SvRV(limit))) != 1)) {
        XSRETURN_UNDEF;
      }

      /* Extract the limit values from the array reference */
      /* */
      for (i=0; i<=last_item; i++) {
	tmp = *av_fetch((AV *)SvRV(limit), i, 0);
	if (SvNIOK(tmp)) {
	  if (ix == 1 || ix == 0) {
	    limit_int[i] = SvIV(tmp);
	  }
	  else if (ix == 2) {
	    limit_dbl[i] = SvNV(tmp);
	  }
	  limit_count++;
	}
      }

      /* If two numbers provided for limit, then use the array, */
      /* otherwise default to NULL, meaning no limit */
      /* */
      if (limit_count == 2) {
	if (ix == 1 || ix == 0) {
	  int_ptr = limit_int;
	}
	else if (ix == 2) {
	  dbl_ptr = limit_dbl;
	}
      }

    }

    /* printf("before switch\n"); */
    switch (ix) {

      case 0:
      case 1:
	printf("ProMessageIntegerRead\n");
	err = ProMessageIntegerRead(int_ptr,&answer_int);
	break;

      case 2:
	printf("ProMessageDoubleRead\n");
	err = ProMessageDoubleRead(dbl_ptr,&answer_double);
	break;

    }

    if (total_items == 2) {
      /* Push int/double answer back into scalar argument */
      if (ix == 1 || ix == 0) {
	sv_setiv(answer, answer_int);
      }
      else if (ix == 2) {
	sv_setnv(answer, answer_double);
      }
      /* Return err */
      XPUSHs(sv_2mortal(newSViv(err)));
    }
    else {
      /* Return int/double answer */
      if (ix == 1 || ix == 0) {
	XPUSHs(sv_2mortal(newSViv(answer_int)));
      }
      else if (ix == 2) {
        XPUSHs(sv_2mortal(newSVnv(answer_double)));
      }
      if (GIMME_V == G_ARRAY) {
	/* If list context, return list with err as 2nd item */
	XPUSHs(sv_2mortal(newSViv(err)));
      }
    }



void
ProMdlCurrentGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model=NULL;
    ProError err;
    SV *promdl_sv, *rv;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    err = ProMdlCurrentGet(&model);
    if (model == NULL) {
      printf("  model was NULL\n");
    }
    /* promdl_sv = newSV(0);
    sv_setref_pv(promdl_sv, "CAD::ProEngineer::ProMdl", (void*)model); */
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProMdl", (void*)model, FALSE);

    /* Setup return values */
    if (total_items == 1) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 1 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProMdlInit(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model=NULL;
    ProError err;
    SV *name_sv, *type_sv, *promdl_sv, *rv;
    char *name_str;
    ProName name_wstr;
    ProMdlType type;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 2 || total_items > 3) {
      XSRETURN_UNDEF;
    }

    name_sv = ST(item_idx);
    type_sv = ST(item_idx+1);
    name_str = SvPV_nolen(name_sv);
    ProStringToWstring(name_wstr,name_str);
    type = SvIV(type_sv);

    err = ProMdlInit(name_wstr, type, &model);
    printf ("  ProMdlInit: err = %d\n", err);
    if (model == NULL) {
      printf("  model was NULL\n");
    }
    if (err != PRO_TK_NO_ERROR) {
      model = NULL;
    }
    /* promdl_sv = newSV(0);
    sv_setref_pv(promdl_sv, "CAD::ProEngineer::ProMdl", (void*)model); */
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProMdl", (void*)model, FALSE);

    /* Setup return values */
    if (total_items == 3) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+2), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 3 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProMdlNameGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model;
    ProCharName mdlname_str;
    ProName mdlname_wstr;
    ProError err;
    SV *model_sv;
    STRLEN len = 0;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProMdl")) {
      /* Perl CAD::ProEngineer::ProMdl to C ProMdl conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      model = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProMdl, then return Perl undef */
      XSRETURN_UNDEF;
    }

    err = ProMdlNameGet(model,mdlname_wstr);
    ProWstringToString(mdlname_str,mdlname_wstr);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setpv(ST(item_idx+1), mdlname_str);
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(newSVpv(mdlname_str,len)));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }




void
ProMdlTypeGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model;
    ProError err;
    int int_num;
  ALIAS:
    ProSolidPostfixIdGet = 1
    ProMdlPostfixIdGet = 2
    ProMdlSessionIdGet = 3
    ProMdlIdGet = 4
    ProMdlWindowGet = 5
    ProMdlModificationVerify = 6
    ProMdlSubtypeGet = 7
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProMdl")) {
      /* Perl CAD::ProEngineer::ProMdl to C ProMdl conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      model = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProMdl, then return Perl undef */
      XSRETURN_UNDEF;
    }

    switch (ix) {
      case 0:
        err = ProMdlTypeGet(model,&int_num);
	break;

      case 1:
      case 2:
      case 3:
        err = ProSolidToPostfixId(model,&int_num);
	break;

      case 4:
        err = ProMdlIdGet(model,&int_num);
	break;

      case 5:
        err = ProMdlWindowGet(model,&int_num);
	break;

      case 6:
        err = ProMdlModificationVerify(model,(ProBoolean *)&int_num);
	break;

      case 7:
        err = ProMdlSubtypeGet(model,(ProMdlsubtype *)&int_num);
	break;
    }

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setiv(ST(item_idx+1), int_num);
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(newSViv(int_num)));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProMdlDisplay(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model;
    ProError err;
    int int_num;
  ALIAS:
    ProMdlSave = 1
    ProMdlErase = 2
    ProMdlEraseAll = 3
    ProMdlDelete = 4
    ProTreetoolRefresh = 5
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProMdl")) {
      /* Perl CAD::ProEngineer::ProMdl to C ProMdl conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      model = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProMdl, then return Perl undef */
      XSRETURN_UNDEF;
    }

    switch (ix) {
      case 0:
        err = ProMdlDisplay(model);
	break;

      case 1:
        err = ProMdlSave(model);
	break;

      case 2:
        err = ProMdlErase(model);
	break;

      case 3:
        err = ProMdlEraseAll(model);
	break;

      case 4:
        err = ProMdlDelete(model);
	break;

      case 5:
        err = ProTreetoolRefresh(model);
	break;
    }

    if (GIMME_V != G_VOID) {
      /* return err */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



I32
ProError(...)
  PROTOTYPE:
  ALIAS:
    PRO_TK_NO_ERROR = PRO_TK_NO_ERROR
    PRO_TK_GENERAL_ERROR = PRO_TK_GENERAL_ERROR
    PRO_TK_BAD_INPUTS = PRO_TK_BAD_INPUTS
    PRO_TK_USER_ABORT = PRO_TK_USER_ABORT
    PRO_TK_E_NOT_FOUND = PRO_TK_E_NOT_FOUND
    PRO_TK_E_FOUND = PRO_TK_E_FOUND
    PRO_TK_LINE_TOO_LONG = PRO_TK_LINE_TOO_LONG
    PRO_TK_CONTINUE = PRO_TK_CONTINUE
    PRO_TK_BAD_CONTEXT = PRO_TK_BAD_CONTEXT
    PRO_TK_NOT_IMPLEMENTED = PRO_TK_NOT_IMPLEMENTED
    PRO_TK_OUT_OF_MEMORY = PRO_TK_OUT_OF_MEMORY
    PRO_TK_COMM_ERROR = PRO_TK_COMM_ERROR
    PRO_TK_NO_CHANGE = PRO_TK_NO_CHANGE
    PRO_TK_SUPP_PARENTS = PRO_TK_SUPP_PARENTS
    PRO_TK_PICK_ABOVE = PRO_TK_PICK_ABOVE
    PRO_TK_INVALID_DIR = PRO_TK_INVALID_DIR
    PRO_TK_INVALID_FILE = PRO_TK_INVALID_FILE
    PRO_TK_CANT_WRITE = PRO_TK_CANT_WRITE
    PRO_TK_INVALID_TYPE = PRO_TK_INVALID_TYPE
    PRO_TK_INVALID_PTR = PRO_TK_INVALID_PTR
    PRO_TK_UNAV_SEC = PRO_TK_UNAV_SEC
    PRO_TK_INVALID_MATRIX = PRO_TK_INVALID_MATRIX
    PRO_TK_INVALID_NAME = PRO_TK_INVALID_NAME
    PRO_TK_NOT_EXIST = PRO_TK_NOT_EXIST
    PRO_TK_CANT_OPEN = PRO_TK_CANT_OPEN
    PRO_TK_ABORT = PRO_TK_ABORT
    PRO_TK_NOT_VALID = PRO_TK_NOT_VALID
    PRO_TK_INVALID_ITEM = PRO_TK_INVALID_ITEM
    PRO_TK_MSG_NOT_FOUND = PRO_TK_MSG_NOT_FOUND
    PRO_TK_MSG_NO_TRANS = PRO_TK_MSG_NO_TRANS
    PRO_TK_MSG_FMT_ERROR = PRO_TK_MSG_FMT_ERROR
    PRO_TK_MSG_USER_QUIT = PRO_TK_MSG_USER_QUIT
    PRO_TK_MSG_TOO_LONG = PRO_TK_MSG_TOO_LONG
    PRO_TK_CANT_ACCESS = PRO_TK_CANT_ACCESS
    PRO_TK_OBSOLETE_FUNC = PRO_TK_OBSOLETE_FUNC
    PRO_TK_NO_COORD_SYSTEM = PRO_TK_NO_COORD_SYSTEM
    PRO_TK_E_AMBIGUOUS = PRO_TK_E_AMBIGUOUS
    PRO_TK_E_DEADLOCK = PRO_TK_E_DEADLOCK
    PRO_TK_E_BUSY = PRO_TK_E_BUSY
    PRO_TK_E_IN_USE = PRO_TK_E_IN_USE
    PRO_TK_NO_LICENSE = PRO_TK_NO_LICENSE
    PRO_TK_BSPL_UNSUITABLE_DEGREE = PRO_TK_BSPL_UNSUITABLE_DEGREE
    PRO_TK_BSPL_NON_STD_END_KNOTS = PRO_TK_BSPL_NON_STD_END_KNOTS
    PRO_TK_BSPL_MULTI_INNER_KNOTS = PRO_TK_BSPL_MULTI_INNER_KNOTS
    PRO_TK_BAD_SRF_CRV = PRO_TK_BAD_SRF_CRV
    PRO_TK_EMPTY = PRO_TK_EMPTY
    PRO_TK_BAD_DIM_ATTACH = PRO_TK_BAD_DIM_ATTACH
    PRO_TK_NOT_DISPLAYED = PRO_TK_NOT_DISPLAYED
    PRO_TK_CANT_MODIFY = PRO_TK_CANT_MODIFY
    PRO_TK_CHECKOUT_CONFLICT = PRO_TK_CHECKOUT_CONFLICT
    PRO_TK_CRE_VIEW_BAD_SHEET = PRO_TK_CRE_VIEW_BAD_SHEET
    PRO_TK_CRE_VIEW_BAD_MODEL = PRO_TK_CRE_VIEW_BAD_MODEL
    PRO_TK_CRE_VIEW_BAD_PARENT = PRO_TK_CRE_VIEW_BAD_PARENT
    PRO_TK_CRE_VIEW_BAD_TYPE = PRO_TK_CRE_VIEW_BAD_TYPE
    PRO_TK_CRE_VIEW_BAD_EXPLODE = PRO_TK_CRE_VIEW_BAD_EXPLODE
    PRO_TK_UNATTACHED_FEATS = PRO_TK_UNATTACHED_FEATS
    PRO_TK_REGEN_AGAIN = PRO_TK_REGEN_AGAIN
    PRO_TK_DWGCREATE_ERRORS = PRO_TK_DWGCREATE_ERRORS
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



I32
ProMdlType(...)
  PROTOTYPE:
  ALIAS:
    PRO_MDL_UNUSED = PRO_MDL_UNUSED
    PRO_MDL_ASSEMBLY = PRO_MDL_ASSEMBLY
    PRO_MDL_PART = PRO_MDL_PART
    PRO_MDL_DRAWING = PRO_MDL_DRAWING
    PRO_MDL_3DSECTION = PRO_MDL_3DSECTION
    PRO_MDL_2DSECTION = PRO_MDL_2DSECTION
    PRO_MDL_LAYOUT = PRO_MDL_LAYOUT
    PRO_MDL_DWGFORM = PRO_MDL_DWGFORM
    PRO_MDL_MFG = PRO_MDL_MFG
    PRO_MDL_REPORT = PRO_MDL_REPORT
    PRO_MDL_MARKUP = PRO_MDL_MARKUP
    PRO_MDL_DIAGRAM = PRO_MDL_DIAGRAM
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



I32
ProMdlsubtype(...)
  PROTOTYPE:
  ALIAS:
    PROMDLSTYPE_NONE = PROMDLSTYPE_NONE
    PROMDLSTYPE_BULK = PROMDLSTYPE_BULK
    PROMDLSTYPE_PART_SOLID = PROMDLSTYPE_PART_SOLID
    PROMDLSTYPE_PART_COMPOSITE = PROMDLSTYPE_PART_COMPOSITE
    PROMDLSTYPE_PART_SHEETMETAL = PROMDLSTYPE_PART_SHEETMETAL
    PROMDLSTYPE_PART_CONCEPT_MODEL = PROMDLSTYPE_PART_CONCEPT_MODEL
    PROMDLSTYPE_ASM_DESIGN = PROMDLSTYPE_ASM_DESIGN
    PROMDLSTYPE_ASM_INTERCHANGE = PROMDLSTYPE_ASM_INTERCHANGE
    PROMDLSTYPE_ASM_INTCHG_SUBST = PROMDLSTYPE_ASM_INTCHG_SUBST
    PROMDLSTYPE_ASM_INTCHG_FUNC = PROMDLSTYPE_ASM_INTCHG_FUNC
    PROMDLSTYPE_ASM_CLASS_CAV = PROMDLSTYPE_ASM_CLASS_CAV
    PROMDLSTYPE_ASM_VERIFY = PROMDLSTYPE_ASM_VERIFY
    PROMDLSTYPE_ASM_PROCPLAN = PROMDLSTYPE_ASM_PROCPLAN
    PROMDLSTYPE_ASM_NCMODEL = PROMDLSTYPE_ASM_NCMODEL
    PROMDLSTYPE_MFG_NCASM = PROMDLSTYPE_MFG_NCASM
    PROMDLSTYPE_MFG_NCPART = PROMDLSTYPE_MFG_NCPART
    PROMDLSTYPE_MFG_EXPMACH = PROMDLSTYPE_MFG_EXPMACH
    PROMDLSTYPE_MFG_CMM = PROMDLSTYPE_MFG_CMM
    PROMDLSTYPE_MFG_SHEETMETAL = PROMDLSTYPE_MFG_SHEETMETAL
    PROMDLSTYPE_MFG_CAST = PROMDLSTYPE_MFG_CAST
    PROMDLSTYPE_MFG_MOLD = PROMDLSTYPE_MFG_MOLD
    PROMDLSTYPE_MFG_DIEFACE = PROMDLSTYPE_MFG_DIEFACE
    PROMDLSTYPE_MFG_HARNESS = PROMDLSTYPE_MFG_HARNESS
    PROMDLSTYPE_MFG_PROCPLAN = PROMDLSTYPE_MFG_PROCPLAN
    PROMDLSTYPE_REGEN_BACKUP = PROMDLSTYPE_REGEN_BACKUP
    PROMDLSTYPE_OLD_REG_MFG = PROMDLSTYPE_OLD_REG_MFG
    PROMDLSTYPE_ASM_CLASS_SCAN_SET = PROMDLSTYPE_ASM_CLASS_SCAN_SET
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



void
ProMdlToModelitem(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model=NULL;
    ProError err;
    SV *rv;
    ProModelitem *modelitem;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProMdl")) {
      /* Perl CAD::ProEngineer::ProMdl to C ProMdl conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      model = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProMdl, then return Perl undef */
      XSRETURN_UNDEF;
    }


    /* printf("before arg checks\n"); */
    if (total_items < 1 || total_items > 2) {
      XSRETURN_UNDEF;
    }

    New(0, modelitem, 1, ProModelitem);
    err = ProMdlToModelitem(model,modelitem);
    if (model == NULL) {
      printf("  model was NULL\n");
    }
    if (err != PRO_TK_NO_ERROR) {
      modelitem = NULL;
    }
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProModelitem", (void*)modelitem, TRUE);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProModelitemInit(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProMdl model;
    ProModelitem *ptr;
    int item_id, item_type;
    SV *rv;
  ALIAS:
    ProDimensionInit = 1
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProMdl")) {
      /* Perl CAD::ProEngineer::ProMdl to C ProMdl conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      model = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProMdl, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 3 || total_items > 4) {
      XSRETURN_UNDEF;
    }

    item_id = SvIV(ST(item_idx+1));
    item_type = SvIV(ST(item_idx+2));

    /* Extract the owner/type of the objects to be visited */
    /* */
    switch (ix) {

      case 0:
        New(0, ptr, 1, ProModelitem);
        ProModelitemInit(model, item_id, item_type, (ProModelitem *)ptr);
        rv = (SV *)bless_safefree("CAD::ProEngineer::ProModelitem", (void*)ptr, TRUE);
        break;

      case 1:
        New(0, ptr, 1, ProDimension);
        ptr->owner = model;
        ptr->id = item_id;
        ptr->type = item_type;
        rv = (SV *)bless_safefree("CAD::ProEngineer::ProDimension", (void*)ptr, TRUE);
        break;

    }

    /* Setup return values */
    if (total_items == 4) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+3), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 4 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProModelitemMdlGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProMdl model=NULL;
    ProError err;
    SV *promdl_sv, *rv;
    ProModelitem *modelitem;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProModelitem")) {
      /* Perl CAD::ProEngineer::ProModelitem to C ProModelitem conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      modelitem = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProModelitem, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 1 || total_items > 2) {
      XSRETURN_UNDEF;
    }

    err = ProModelitemMdlGet(modelitem,&model);
    printf ("  ProModelitemMdlGet: err = %d\n", err);
    if (model == NULL) {
      printf("  model was NULL\n");
    }
    if (err != PRO_TK_NO_ERROR) {
      model = NULL;
    }
    /* promdl_sv = newSV(0);
    sv_setref_pv(promdl_sv, "CAD::ProEngineer::ProMdl", (void*)model); */
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProMdl", (void*)model, FALSE);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



I32
ProBoolean(...)
  PROTOTYPE:
  ALIAS:
    PRO_B_FALSE = PRO_B_FALSE
    PRO_B_TRUE = PRO_B_TRUE
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



I32
uiCmdPriority(...)
  PROTOTYPE:
  ALIAS:
    uiCmdPrioDefault = uiCmdPrioDefault
    uiProeImmediate = uiProeImmediate
    uiProeAsynch = uiProeAsynch
    uiProe2ndImmediate = uiProe2ndImmediate
    uiProe3rdImmediate = uiProe3rdImmediate
    uiCmdNoPriority = uiCmdNoPriority
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



I32
uiCmdAccessState(...)
  PROTOTYPE:
  ALIAS:
    ACCESS_REMOVE = ACCESS_REMOVE
    ACCESS_INVISIBLE = ACCESS_INVISIBLE
    ACCESS_UNAVAILABLE = ACCESS_UNAVAILABLE
    ACCESS_DISALLOW = ACCESS_DISALLOW
    ACCESS_AVAILABLE = ACCESS_AVAILABLE
  CODE:
    /* The alias number (to the right of the equal sign) is resolved */
    /* during compilation. As long as all of the constants have a  */
    /* unique value, everything will work just fine. */
    RETVAL = ix;
  OUTPUT:
    RETVAL



void
ProCmdActionAdd(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    char *action_name;
    int priority, active_win, aux_win, uiCmdAccessState_type;
    uiCmdCmdId cmd_id;
    CV *uiCmdCmdActFn_cv, *uiCmdAccessState_cv;
    char *uiCmdCmdActFn_hv_key="uiCmdCmdActFn", *uiCmdAccessState_hv_key="uiCmdAccessState";
    IV ptr_iv;
    SV *rv_uiCmdCmdActFn_cv, *rv_uiCmdCmdActFn_hv, *cmdid_sv;
    SV *rv_uiCmdAccessState_cv, *rv_uiCmdAccessState_hv;
    HV *module_cb_hv, *uiCmdCmdActFn_hv, *uiCmdAccessState_hv;
    void (* uiCmdAccessState_fp)();
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (total_items < 7 || total_items > 8) {
      XSRETURN_UNDEF;
    }

    /* Extract arguments */
    /* */
    action_name = SvPV_nolen(ST(item_idx));
    rv_uiCmdCmdActFn_cv = ST(item_idx+1);
    if (!SvROK(rv_uiCmdCmdActFn_cv) || SvTYPE(SvRV(rv_uiCmdCmdActFn_cv)) != SVt_PVCV) {
      rv_uiCmdCmdActFn_cv = &PL_sv_undef;
    }
    priority = SvIV(ST(item_idx+2));
    uiCmdAccessState_type = SvIV(ST(item_idx+3));
    active_win = SvIV(ST(item_idx+4));
    aux_win = SvIV(ST(item_idx+5));
    cmdid_sv = ST(item_idx+6);

    switch (uiCmdAccessState_type) {
      case ACCESS_AVAILABLE:
      default:
        uiCmdAccessState_fp = (void *)std_uiCmdAccessState_ACCESS_AVAILABLE;
        break;
    }

    err = ProCmdActionAdd(action_name, (uiCmdCmdActFn)std_uiCmdCmdActFn, priority, 
                          (uiCmdAccessFn)uiCmdAccessState_fp, active_win, aux_win, &cmd_id);

    /* Store cmd_id in an sv */
    /* */
    ptr_iv = PTR2IV(cmd_id);
    /* printf("  ProCmdActionAdd: cmd_id_str = %d\n", ptr_iv); */
    sv_setiv(cmdid_sv, ptr_iv);

    /* Store uiCmdCmdActFn cv ref in new HV using stringified cmd_id as the key */
    /* */
    uiCmdCmdActFn_hv = (HV *)sv_2mortal((SV *)newHV());
    hv_store(uiCmdCmdActFn_hv, SvPV_nolen(cmdid_sv), SvCUR(cmdid_sv), SvREFCNT_inc(rv_uiCmdCmdActFn_cv), 0);
    rv_uiCmdCmdActFn_hv = (SV *)newRV_inc((SV *)uiCmdCmdActFn_hv);
    if (rv_uiCmdCmdActFn_hv == NULL) { printf("rv_uiCmdCmdActFn_hv is NULL\n"); } else { /* printf("rv_uiCmdCmdActFn_hv ok\n"); */ }

    /* Store HV ref in "Callbacks" hash under key: "uiCmdCmdActFn" */
    /* */
    module_cb_hv = get_hv("CAD::ProEngineer::Callbacks", TRUE);
    if (module_cb_hv == NULL) { printf("module_cb_hv is NULL\n"); } else { /* printf("module_cb_hv ok\n"); */ }

    /* Store uiCmdCmdActFn ref in "Callbacks" hash under key: "uiCmdCmdActFn" */
    /* */
    hv_store(module_cb_hv, uiCmdCmdActFn_hv_key, strlen(uiCmdCmdActFn_hv_key), SvREFCNT_inc(rv_uiCmdCmdActFn_hv), 0);



void
ProMenubarmenuPushbuttonAdd(...)
  INIT:
    int item_idx = 0, total_items = 0;
    char *menu_name, *button_name, *button_label, *button_help, *neighbor;
    int add_after_neighbor;
    uiCmdCmdId cmd_id;
    ProFileName msg_file_wstr;
    ProError err;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (total_items < 8 || total_items > 9) {
      XSRETURN_UNDEF;
    }

    menu_name = SvPV_nolen(ST(item_idx));
    button_name = SvPV_nolen(ST(item_idx+1));
    button_label = SvPV_nolen(ST(item_idx+2));
    button_help = SvPV_nolen(ST(item_idx+3));
    neighbor = SvPV_nolen(ST(item_idx+4));
    add_after_neighbor = SvIV(ST(item_idx+5));
    cmd_id = INT2PTR(uiCmdCmdId,SvIV(ST(item_idx+6)));
    ProStringToWstring(msg_file_wstr, SvPV_nolen(ST(item_idx+7)));
    /* printf("cmd_id: %d\n", cmd_id); */

    err = ProMenubarmenuPushbuttonAdd(menu_name, button_name, button_label, button_help, 
                                      neighbor, add_after_neighbor, cmd_id, msg_file_wstr);
    if (GIMME_V != G_VOID) {
      /* return err */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProParameterInit(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    SV *proparameter_sv, *rv;
    ProModelitem *modelitem;
    ProParameter *parameter;
    ProName w_name;
    char *name;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProModelitem")) {
      /* Perl CAD::ProEngineer::ProModelitem to C ProModelitem conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      modelitem = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProModelitem, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 2 || total_items > 3) {
      XSRETURN_UNDEF;
    }

    name = SvPV_nolen(ST(item_idx+1));
    ProStringToWstring(w_name,name);

    New(0, parameter, 1, ProParameter);
    err = ProParameterInit(modelitem, w_name, parameter);
    if (parameter == NULL) {
      printf("  parameter was NULL\n");
    }
    if (err != PRO_TK_NO_ERROR) {
      parameter = NULL;
    }
    /* proparameter_sv = newSV(0);
    sv_setref_pv(proparameter_sv, "CAD::ProEngineer::ProParameter", (void*)parameter); */
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProParameter", (void*)parameter, TRUE);

    /* Setup return values */
    if (total_items == 3) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+2), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 3 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProParameterValueGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProParameter *parameter;
    ProParamvalue *paramval;
    SV *proparamval_sv, *rv;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProParameter")) {
      /* Perl CAD::ProEngineer::ProParameter to C ProParameter conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      parameter = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProParameter, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 1 || total_items > 2) {
      XSRETURN_UNDEF;
    }

    New(0, paramval, 1, ProParamvalue);
    err = ProParameterValueGet(parameter, paramval);
    if (paramval == NULL) {
      printf("  paramval was NULL\n");
    }
    if (err != PRO_TK_NO_ERROR) {
      paramval = NULL;
    }
    /* proparamval_sv = newSV(0);
    sv_setref_pv(proparamval_sv, "CAD::ProEngineer::ProParamvalue", (void*)paramval); */
    rv = (SV *)bless_safefree("CAD::ProEngineer::ProParamvalue", (void*)paramval, TRUE);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(rv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(rv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProParameterNameGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProParameter *parameter;
    ProCharName name;
    SV *proparamname_sv;
    STRLEN len = 0;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProParameter")) {
      /* Perl CAD::ProEngineer::ProParameter to C ProParameter conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      parameter = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProParameter, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 1 || total_items > 2) {
      XSRETURN_UNDEF;
    }

    ProWstringToString(name, parameter->id);
    proparamname_sv = newSVpv(name,len);
    err = PRO_TK_NO_ERROR;

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(proparamname_sv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(proparamname_sv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProParamvalueValueGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProParamvalue *paramval;
    SV *value_sv;
    ProParamvalueValue value;
    ProParamvalueType value_type;
    ProCharLine str_value;
    STRLEN len = 0;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (items >= 1 && sv_derived_from(ST(item_idx), "CAD::ProEngineer::ProParamvalue")) {
      /* Perl CAD::ProEngineer::ProParamvalue to C ProParamvalue conversion here */
      IV tmp = SvIV((SV*)SvRV(ST(item_idx)));
      paramval = INT2PTR(void *,tmp);
    }
    else {
      /* If not Perl CAD::ProEngineer::ProParameter, then return Perl undef */
      XSRETURN_UNDEF;
    }

    /* printf("before arg checks\n"); */
    if (total_items < 1 || total_items > 2) {
      XSRETURN_UNDEF;
    }

    ProParamvalueTypeGet(paramval, &value_type);

    err = ProParamvalueValueGet(paramval, value_type, &value);
    if (value_type == PRO_PARAM_DOUBLE) {
      value_sv = newSVnv(value.d_val);
    }
    else if (value_type == PRO_PARAM_STRING) {
      ProWstringToString(str_value, value.s_val);
      value_sv = newSVpv(str_value,len);
    }
    else if (value_type == PRO_PARAM_INTEGER) {
      value_sv = newSViv(value.i_val);
    }
    else if (value_type == PRO_PARAM_BOOLEAN) {
      value_sv = (value.l_val ? &PL_sv_yes : &PL_sv_no);
    }
    else {
      value_sv = &PL_sv_undef;
    }

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(value_sv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(value_sv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
std_VisitFunction(...)
  ALIAS:
    ProParameterVisit = 1
    ProSolidDimensionVisit = 2
  INIT:
    int item_idx = 0, total_items = 0;
    int st_item_filter, st_item_action;
    ProError err;
    int type;
    char *visit_action_key="VisitAction", *visit_filter_key="VisitFilter", 
         *visit_appdata_key="AppData", *visit_type_key="Type";
    SV *rv_visit_filter_cv=NULL, *rv_visit_action_cv=NULL, *rv_user_appdata, *visit_type_sv;
    HV *sys_appdata_hv;
    void *owner;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    /* Extract the owner/type of the objects to be visited */
    /* */
    switch (ix) {

      case 1:
        if (total_items != 4 || (owner = get_ptr_from_object(ST(item_idx), "CAD::ProEngineer::ProModelitem")) == NULL) {
          XSRETURN_IV(PRO_TK_BAD_INPUTS);
        }
        st_item_filter = items - 3;
        st_item_action = items - 2;
        break;

      case 2:
        if (total_items != 5 || (owner = get_ptr_from_object(ST(item_idx), "CAD::ProEngineer::ProMdl")) == NULL) {
          XSRETURN_IV(PRO_TK_BAD_INPUTS);
        }
        type = SvIV(ST(item_idx+1));
        st_item_filter = items - 2;
        st_item_action = items - 3;
        break;

    }

    /* Extract filter cv arg, set to undef if not a reference or not a cv */
    /* */
    rv_visit_filter_cv = ST(st_item_filter);
    if (!SvROK(rv_visit_filter_cv) || SvTYPE(SvRV(rv_visit_filter_cv)) != SVt_PVCV) {
      rv_visit_filter_cv = &PL_sv_undef;
    }

    /* Extract action cv arg, set to undef if not a reference or not a cv */
    /* */
    rv_visit_action_cv = ST(st_item_action);
    if (!SvROK(rv_visit_action_cv) || SvTYPE(SvRV(rv_visit_action_cv)) != SVt_PVCV) {
      rv_visit_action_cv = &PL_sv_undef;
    }

    /* Extract user supplied appdata arg, set to undef if not a reference */
    /* */
    rv_user_appdata = ST(items-1);
    if (!SvROK(rv_user_appdata)) {
      /* printf("  user appdata is not a ref\n"); */
      rv_user_appdata = &PL_sv_undef;
    }

    /* Create SV to hold name of data type */
    /* */
    switch (ix) {

      case 1:
        visit_type_sv = sv_2mortal(newSVpv("CAD::ProEngineer::ProParameter", 0));
        break;

      case 2:
        visit_type_sv = sv_2mortal(newSVpv("CAD::ProEngineer::ProDimension", 0));
        break;

    }

    /* Store data in new HV (sys_appdata_hv) */
    /* */
    /* sys_appdata_hv = newHV(); */
    sys_appdata_hv = (HV *)sv_2mortal((SV *)newHV());
    hv_store(sys_appdata_hv, visit_action_key, strlen(visit_action_key), SvREFCNT_inc(rv_visit_action_cv), 0);
    hv_store(sys_appdata_hv, visit_filter_key, strlen(visit_filter_key), SvREFCNT_inc(rv_visit_filter_cv), 0);
    hv_store(sys_appdata_hv, visit_appdata_key, strlen(visit_appdata_key), SvREFCNT_inc(rv_user_appdata), 0);
    hv_store(sys_appdata_hv, visit_type_key, strlen(visit_type_key), SvREFCNT_inc(visit_type_sv), 0);

    /* Use visit function depending on called function name */
    /* */
    switch (ix) {

      case 1:
        err = ProParameterVisit((ProModelitem *)owner, (ProParameterFilter)std_VisitFilter, 
                               (ProParameterAction)std_VisitAction, (ProAppData)sys_appdata_hv);
        break;

      case 2:
        err = ProSolidDimensionVisit((ProSolid)owner, (ProBoolean)type, 
                                     (ProDimensionVisitAction)std_VisitAction, 
                                     (ProDimensionFilterAction)std_VisitFilter, 
                                     (ProAppData)sys_appdata_hv);
        break;

    }



void
ProDimensionValueGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProDimension *dim;
    SV *value_sv;
    double value;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (total_items < 1 || total_items > 2 
          || (dim = get_ptr_from_object(ST(item_idx), "CAD::ProEngineer::ProDimension")) == NULL) {
      XSRETURN_IV(PRO_TK_BAD_INPUTS);
    }

    err = ProDimensionValueGet(dim, &value);
    value_sv = newSVnv(value);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(value_sv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(value_sv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



void
ProDimensionSymbolGet(...)
  INIT:
    int item_idx = 0, total_items = 0;
    ProError err;
    ProDimension *dim;
    SV *name_sv;
    ProName w_name;
    ProCharName name;
  PPCODE:
    /* Determine if OO calling syntax */
    /* */
    if (items >= 1 && sv_isobject(ST(0)) && sv_isa(ST(0), "CAD::ProEngineer")) {
      item_idx = 1;
      total_items = items - 1;
    }
    else {
      item_idx = 0;
      total_items = items;
    }

    if (total_items < 1 || total_items > 2 
          || (dim = get_ptr_from_object(ST(item_idx), "CAD::ProEngineer::ProDimension")) == NULL) {
      XSRETURN_IV(PRO_TK_BAD_INPUTS);
    }

    err = ProDimensionSymbolGet(dim, w_name);
    ProWstringToString(name, w_name);
    name_sv = newSVpv(name,0);

    /* Setup return values */
    if (total_items == 2) {
      /* Push answer back into scalar argument */
      sv_setsv(ST(item_idx+1), sv_2mortal(name_sv));
    }
    else {
      /* Return answer */
      XPUSHs(sv_2mortal(name_sv));
    }
    if (total_items == 2 || GIMME_V == G_ARRAY) {
      /* If list context or non-OO, return err after others, if any */
      XPUSHs(sv_2mortal(newSViv(err)));
    }



MODULE = CAD::ProEngineer		PACKAGE = CAD::ProEngineer::ProModelitem


void DESTROY(...)
  INIT:
    int verbose=0;
  CODE:
    if (SvTRUE(get_sv("CAD::ProEngineer::Verbose", FALSE))) {
      verbose = 1;
    }
    if (verbose) {
      printf("Destroying ProModelitem object ...");
    }
    if (std_DESTROY(ST(0)) == TRUE && verbose) {
      printf(" freeing the pointer ...");
    }
    if (verbose) {
      printf("\n");
    }



MODULE = CAD::ProEngineer		PACKAGE = CAD::ProEngineer::ProParameter


void DESTROY(...)
  INIT:
    int verbose=0;
  CODE:
    if (SvTRUE(get_sv("CAD::ProEngineer::Verbose", FALSE))) {
      verbose = 1;
    }
    if (verbose) {
      printf("Destroying ProParameter object ...");
    }
    if (std_DESTROY(ST(0)) == TRUE) {
      printf(" freeing the pointer ...");
    }
    if (verbose) {
      printf("\n");
    }



MODULE = CAD::ProEngineer		PACKAGE = CAD::ProEngineer::ProParamvalue


void DESTROY(...)
  INIT:
    int verbose=0;
  CODE:
    if (SvTRUE(get_sv("CAD::ProEngineer::Verbose", FALSE))) {
      verbose = 1;
    }
    if (verbose) {
      printf("Destroying ProParamvalue object ...");
    }
    if (std_DESTROY(ST(0)) == TRUE) {
      printf(" freeing the pointer ...");
    }
    if (verbose) {
      printf("\n");
    }



MODULE = CAD::ProEngineer		PACKAGE = CAD::ProEngineer::ProDimension


void DESTROY(...)
  INIT:
    int verbose=0;
  CODE:
    if (SvTRUE(get_sv("CAD::ProEngineer::Verbose", FALSE))) {
      verbose = 1;
    }
    if (verbose) {
      printf("Destroying ProDimension object ...");
    }
    if (std_DESTROY(ST(0)) == TRUE) {
      printf(" freeing the pointer ...");
    }
    if (verbose) {
      printf("\n");
    }



