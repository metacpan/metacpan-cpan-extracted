#line 171 "KontoCheck.lx"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "konto_check.h"
#include "konto_check-at.h"

MODULE = Business::KontoCheck		PACKAGE = Business::KontoCheck		
PROTOTYPES: ENABLE

# Aufrufe der konto_check Bibliothek
int
kto_check(pz_or_blz,kto,lut_name)
   char *pz_or_blz;
   char *kto;
   char *lut_name;

const char *
kto_check_str(pz_or_blz,kto,lut_name)
   char *pz_or_blz;
   char *kto;
   char *lut_name;

int
kto_check_blz(blz,kto)
   char *blz;
   char *kto;

int
kto_check_regel(blz,kto)
   char *blz;
   char *kto;

int
set_verbose_debug(mode)
	int mode;

int
set_default_compression(mode)
	int mode;

int
dump_lutfile(outputname,felder)
   char *outputname;
   int felder;
CODE:
#line 249 "KontoCheck.lx"
   RETVAL=dump_lutfile_p(outputname,felder);
OUTPUT:
   RETVAL

int
kto_check_pz(pz,kto...)
   char *pz;
   char *kto;
PREINIT:
#line 258 "KontoCheck.lx"
   char *blz;
CODE:
#line 260 "KontoCheck.lx"
   switch(items){
      case 2:
         blz=NULL;
         break;
      case 3:
         blz=(char *)SvPV_nolen(ST(2));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::kto_check_pz(pz, kto[, blz])");
         break;
   }
   RETVAL = kto_check_pz(pz,kto,blz);
OUTPUT:
   RETVAL

int
kto_check_regel_dbg_i(blz,kto,blz2,kto2,bic,regel,methode,pz_methode,pz,pz_pos)
   char *blz;
   char *kto;
   char *blz2;
   char *kto2;
   const char *bic;
   int regel;
   const char *methode;
   int pz_methode;
   int pz;
   int pz_pos;
PREINIT:
#line 288 "KontoCheck.lx"
   char blz2a[10],kto2a[12];
   RETVAL retvals;
CODE:
#line 291 "KontoCheck.lx"
   if(items<10)Perl_croak(aTHX_ "Usage: Business::KontoCheck::kto_check_regel_dbg_i(blz,kto,blz2,kto2,bic,regel,methode,pz_methode,pz,pz_pos)");
   RETVAL=kto_check_regel_dbg(blz,kto,blz2a,kto2a,&bic,&regel,&retvals);
 	sv_setpv((SV*)ST(2),blz2a);
 	SvSETMAGIC(ST(2));
 	sv_setpv((SV*)ST(3),kto2a);
 	SvSETMAGIC(ST(3));
 	sv_setpv((SV*)ST(4),bic);
 	SvSETMAGIC(ST(4));
 	sv_setiv(ST(5),(IV)regel);
 	SvSETMAGIC(ST(5));
 	sv_setpv((SV*)ST(6),methode);
 	SvSETMAGIC(ST(6));
 	sv_setiv(ST(7),(IV)pz_methode);
 	SvSETMAGIC(ST(7));
 	sv_setiv(ST(8),(IV)pz);
 	SvSETMAGIC(ST(8));
 	sv_setiv(ST(9),(IV)pz_pos);
 	SvSETMAGIC(ST(9));
OUTPUT:
   RETVAL

int
lut_valid()

void
lut_cleanup()

int
lut_init(...)
PREINIT:
#line 321 "KontoCheck.lx"
   char *lut_name;
   unsigned int required;
   unsigned int set;
CODE:
#line 325 "KontoCheck.lx"
   switch(items){
      case 0:
         lut_name=NULL;
         required=DEFAULT_INIT_LEVEL;
         set=0;
         break;
      case 1:
         lut_name=(char *)SvPV_nolen(ST(0));
         required=DEFAULT_INIT_LEVEL;
         set=0;
         break;
      case 2:
         lut_name=(char *)SvPV_nolen(ST(0));
         required=(unsigned int)SvUV(ST(1));
         set=0;
         break;
      case 3:
         lut_name=(char *)SvPV_nolen(ST(0));
         required=(unsigned int)SvUV(ST(1));
         set=(unsigned int)SvUV(ST(2));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_init(lut_name[,required[,set]])");
         break;
   }

   RETVAL=lut_init(lut_name,required,set);
OUTPUT:
   RETVAL

int
kto_check_init(lut_name...)
   char *lut_name
PREINIT:
#line 359 "KontoCheck.lx"
   unsigned int required;
   unsigned int set;
   unsigned int incremental;
CODE:
#line 363 "KontoCheck.lx"
   switch(items){
      case 1:
         required=DEFAULT_INIT_LEVEL;
         set=0;
         incremental=0;
         break;
      case 2:
         required=(unsigned int)SvUV(ST(1));
         set=0;
         incremental=0;
         break;
      case 3:
         required=(unsigned int)SvUV(ST(1));
         set=(unsigned int)SvUV(ST(2));
         incremental=0;
         break;
      case 4:
         required=(unsigned int)SvUV(ST(1));
         set=(unsigned int)SvUV(ST(2));
         incremental=(unsigned int)SvUV(ST(3));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::kto_check_init(lut_name[,required[,set[,incremental]]])");
         break;
   }

   RETVAL=kto_check_init_p(lut_name,required,set,incremental);
OUTPUT:
   RETVAL

int
lut_keine_iban_berechnung(inputname,outputname...)
   char *inputname;
   char *outputname;
PREINIT:
#line 398 "KontoCheck.lx"
   unsigned int set;
CODE:
#line 400 "KontoCheck.lx"
   switch(items){
      case 2:
         set=0;
         break;
      case 3:
         set=(unsigned int)SvUV(ST(2));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_keine_iban_berechnung(inputname, outputname[, set])");
         break;
   }

	RETVAL=lut_keine_iban_berechnung(inputname,outputname,set);
OUTPUT:
   RETVAL

int
generate_lut2(inputname,outputname...)
   char *inputname;
   char *outputname;
PREINIT:
#line 421 "KontoCheck.lx"
   char *user_info;
   char *gueltigkeit;
   char *keine_iban_berechnung;
   unsigned int felder;
   unsigned int filialen;
   unsigned int slots;
   unsigned int lut_version;
   unsigned int set;
CODE:
#line 430 "KontoCheck.lx"
   keine_iban_berechnung=NULL;
   gueltigkeit=NULL;
   felder=-1;
   filialen=slots=lut_version=set=0;
   switch(items){
      case 2:
         user_info=NULL;
         break;
      case 3:
         user_info=(char *)SvPV_nolen(ST(2));
         break;
      case 4:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         break;
      case 5:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         break;
      case 6:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         filialen=(unsigned int)SvUV(ST(5));
         break;
      case 7:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         filialen=(unsigned int)SvUV(ST(5));
         slots=(unsigned int)SvUV(ST(6));
         break;
      case 8:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         filialen=(unsigned int)SvUV(ST(5));
         slots=(unsigned int)SvUV(ST(6));
         lut_version=(unsigned int)SvUV(ST(7));
         break;
      case 9:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         filialen=(unsigned int)SvUV(ST(5));
         slots=(unsigned int)SvUV(ST(6));
         lut_version=(unsigned int)SvUV(ST(7));
         set=(unsigned int)SvUV(ST(8));
         break;
      case 10:
         user_info=(char *)SvPV_nolen(ST(2));
         gueltigkeit=(char *)SvPV_nolen(ST(3));
         felder=(unsigned int)SvUV(ST(4));
         filialen=(unsigned int)SvUV(ST(5));
         slots=(unsigned int)SvUV(ST(6));
         lut_version=(unsigned int)SvUV(ST(7));
         set=(unsigned int)SvUV(ST(8));
         keine_iban_berechnung=(char *)SvPV_nolen(ST(9));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::generate_lut2(inputname, outputname[, user_info[, gueltigkeit[, felder[, filialen[, slots[, lut_version[, set[, keine_iban_cfg]]]]]]]])");
         break;
   }

	RETVAL=generate_lut2_p(inputname,outputname,user_info,gueltigkeit,felder,filialen,slots,lut_version,set);
   if(keine_iban_berechnung)lut_keine_iban_berechnung(keine_iban_berechnung,outputname,set);
OUTPUT:
   RETVAL

int
lut_filialen_i(r,blz)
   char *blz;
   int r;
CODE:
#line 505 "KontoCheck.lx"
   if(items!=2)Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_filialen(blz)");
   RETVAL=lut_filialen(blz,&r);
OUTPUT:
   r
   RETVAL

int lut_multiple_i(blz,filiale...)
char *blz;
int filiale;
PREINIT:
#line 515 "KontoCheck.lx"
   int cnt;
   char **p_name;
   char **p_name_kurz;
   int *p_plz;
   char **p_ort;
   int *p_pan;
   char **p_bic;
   int p_pz;
   int *p_nr;
   char *p_aenderung;
   char *p_loeschung;
   int *p_nachfolge_blz;
 CODE:
#line 528 "KontoCheck.lx"
   if(items!=14)Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_multiple_i(blz, filiale, cnt, "
         "name, name_kurz, plz, ort, pan, bic, pz, nr, aenderung, loeschung, nachfolge_blz)");
   RETVAL=lut_multiple(blz,&cnt,NULL,&p_name,&p_name_kurz,&p_plz,&p_ort,&p_pan,&p_bic,&p_pz,&p_nr,
         &p_aenderung,&p_loeschung,&p_nachfolge_blz,NULL,NULL,NULL);
   if(RETVAL>0 || RETVAL==LUT2_PARTIAL_OK){
      sv_setiv(ST(2), (IV)cnt);
      SvSETMAGIC(ST(2));
      sv_setpv((SV*)ST(3), p_name[filiale]);
      SvSETMAGIC(ST(3));
      sv_setpv((SV*)ST(4), p_name_kurz[filiale]);
      SvSETMAGIC(ST(4));
      sv_setiv(ST(5), (IV)p_plz[filiale]);
      SvSETMAGIC(ST(5));
      sv_setpv((SV*)ST(6), p_ort[filiale]);
      SvSETMAGIC(ST(6));
      sv_setiv(ST(7), (IV)p_pan[filiale]);
      SvSETMAGIC(ST(7));
      sv_setpv((SV*)ST(8), p_bic[filiale]);
      SvSETMAGIC(ST(8));
      sv_setiv(ST(9), (IV)p_pz);
      SvSETMAGIC(ST(9));
      sv_setiv(ST(10), (IV)p_nr[filiale]);
      SvSETMAGIC(ST(10));
      sv_setiv(ST(11), (IV)p_aenderung[filiale]);
      SvSETMAGIC(ST(11));
      sv_setiv(ST(12), (IV)p_loeschung[filiale]);
      SvSETMAGIC(ST(12));
      sv_setiv(ST(13), (IV)p_nachfolge_blz[filiale]);
      SvSETMAGIC(ST(13));
   }
   else{
      sv_setiv(ST(2), (IV)0);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   RETVAL

#line 566 "KontoCheck.lx"
const char *
pz2str(pz...)
   int pz;
CODE:
   int ret;
#line 573 "KontoCheck.lx"
   if(items<1 || items>2)Perl_croak(aTHX_ "Usage: Business::KontoCheck::pz2str(pz[,retval])");

   RETVAL=pz2str(pz,&ret);
   if(items==2){
      sv_setiv(ST(1),(IV)ret);
      SvSETMAGIC(ST(1));
   }
OUTPUT:
   RETVAL

#line 584 "KontoCheck.lx"
int
lut_blz_i(blz...)
   char *blz;
PREINIT:
#line 590 "KontoCheck.lx"
   unsigned int offset;
CODE:
#line 593 "KontoCheck.lx"
   if(items==1)
      offset=0;
   else if(items==2 || items==3)
      offset=(unsigned int)SvUV(ST(1));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_blz(blz[,offset[,retval]])");

   RETVAL=lut_blz(blz,offset);
   if(items==3){
      sv_setiv(ST(2),(IV)RETVAL);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   RETVAL

#line 609 "KontoCheck.lx"
int
bic_info_i(bic,mode,anzahl,start_idx)
   char *bic;
   int mode;
   int anzahl;
   int start_idx;
CODE:
#line 618 "KontoCheck.lx"
   if(items!=4)Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_info(bic,mode,anzahl,start_idx))");

   RETVAL=bic_info(bic,mode,&anzahl,&start_idx);
   sv_setiv(ST(2),(IV)anzahl);
   SvSETMAGIC(ST(2));
   sv_setiv(ST(3),(IV)start_idx);
   SvSETMAGIC(ST(3));
OUTPUT:
   RETVAL

#line 602 "KontoCheck.lx"

const char *
lut_name_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 609 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 612 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_name(blz[,zweigstelle[,retval]])");

   RETVAL=lut_name(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 603 "KontoCheck.lx"

const char *
lut_name_kurz_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 610 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 613 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_name_kurz(blz[,zweigstelle[,retval]])");

   RETVAL=lut_name_kurz(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 604 "KontoCheck.lx"

int
lut_plz_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 611 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 614 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_plz(blz[,zweigstelle[,retval]])");

   RETVAL=lut_plz(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 605 "KontoCheck.lx"

const char *
lut_ort_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 612 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 615 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_ort(blz[,zweigstelle[,retval]])");

   RETVAL=lut_ort(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 606 "KontoCheck.lx"

int
lut_pan_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 613 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 616 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_pan(blz[,zweigstelle[,retval]])");

   RETVAL=lut_pan(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 607 "KontoCheck.lx"

const char *
lut_bic_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 614 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 617 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_bic(blz[,zweigstelle[,retval]])");

   RETVAL=lut_bic(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 608 "KontoCheck.lx"

int
lut_pz_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 615 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 618 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_pz(blz[,zweigstelle[,retval]])");

   RETVAL=lut_pz(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 609 "KontoCheck.lx"

int
lut_aenderung_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 616 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 619 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_aenderung(blz[,zweigstelle[,retval]])");

   RETVAL=lut_aenderung(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 610 "KontoCheck.lx"

int
lut_loeschung_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 617 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 620 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_loeschung(blz[,zweigstelle[,retval]])");

   RETVAL=lut_loeschung(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 611 "KontoCheck.lx"

int
lut_nachfolge_blz_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 618 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 621 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_nachfolge_blz(blz[,zweigstelle[,retval]])");

   RETVAL=lut_nachfolge_blz(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 612 "KontoCheck.lx"

int
lut_iban_regel_i(r,blz...)
   char *blz;
   int r;
PREINIT:
#line 619 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 622 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_iban_regel(blz[,zweigstelle[,retval]])");

   RETVAL=lut_iban_regel(blz,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL


#line 608 "KontoCheck.lx"

const char *
bic_name_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 615 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 618 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_name(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_name(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 609 "KontoCheck.lx"

const char *
bic_name_kurz_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 616 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 619 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_name_kurz(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_name_kurz(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 610 "KontoCheck.lx"

int
bic_plz_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 617 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 620 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_plz(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_plz(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 611 "KontoCheck.lx"

const char *
bic_ort_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 618 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 621 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_ort(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_ort(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 612 "KontoCheck.lx"

int
bic_pan_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 619 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 622 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_pan(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_pan(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 613 "KontoCheck.lx"

const char *
bic_bic_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 620 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 623 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_bic(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_bic(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 614 "KontoCheck.lx"

int
bic_pz_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 621 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 624 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_pz(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_pz(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 615 "KontoCheck.lx"

int
bic_aenderung_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 622 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 625 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_aenderung(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_aenderung(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 616 "KontoCheck.lx"

int
bic_loeschung_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 623 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 626 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_loeschung(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_loeschung(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 617 "KontoCheck.lx"

int
bic_nachfolge_blz_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 624 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 627 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_nachfolge_blz(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_nachfolge_blz(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL

#line 618 "KontoCheck.lx"

int
bic_iban_regel_i(r,bic...)
   char *bic;
   int r;
PREINIT:
#line 625 "KontoCheck.lx"
   unsigned int zweigstelle,mode;
CODE:
#line 628 "KontoCheck.lx"
   if(items==2)
      mode=zweigstelle=0;
   else if(items==3){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=0;
   }
   else if(items==4 || items==5){
      mode=(unsigned int)SvUV(ST(2));
      zweigstelle=(unsigned int)SvUV(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_iban_regel(bic[,mode[,zweigstelle[,retval]]])");

   RETVAL=bic_iban_regel(bic,mode,zweigstelle,&r);
   if(items==5){
      sv_setiv(ST(4),(IV)r);
      SvSETMAGIC(ST(4));
   }
OUTPUT:
   r
   RETVAL


#line 633 "KontoCheck.lx"

const char *
biq_name_i(r,idx...)
   int r;
   int idx;
CODE:
#line 640 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_name(idx[,retval]])");

   RETVAL=biq_name(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 634 "KontoCheck.lx"

const char *
biq_name_kurz_i(r,idx...)
   int r;
   int idx;
CODE:
#line 641 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_name_kurz(idx[,retval]])");

   RETVAL=biq_name_kurz(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 635 "KontoCheck.lx"

int
biq_plz_i(r,idx...)
   int r;
   int idx;
CODE:
#line 642 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_plz(idx[,retval]])");

   RETVAL=biq_plz(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 636 "KontoCheck.lx"

const char *
biq_ort_i(r,idx...)
   int r;
   int idx;
CODE:
#line 643 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_ort(idx[,retval]])");

   RETVAL=biq_ort(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 637 "KontoCheck.lx"

int
biq_pan_i(r,idx...)
   int r;
   int idx;
CODE:
#line 644 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_pan(idx[,retval]])");

   RETVAL=biq_pan(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 638 "KontoCheck.lx"

const char *
biq_bic_i(r,idx...)
   int r;
   int idx;
CODE:
#line 645 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_bic(idx[,retval]])");

   RETVAL=biq_bic(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 639 "KontoCheck.lx"

int
biq_pz_i(r,idx...)
   int r;
   int idx;
CODE:
#line 646 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_pz(idx[,retval]])");

   RETVAL=biq_pz(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 640 "KontoCheck.lx"

int
biq_aenderung_i(r,idx...)
   int r;
   int idx;
CODE:
#line 647 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_aenderung(idx[,retval]])");

   RETVAL=biq_aenderung(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 641 "KontoCheck.lx"

int
biq_loeschung_i(r,idx...)
   int r;
   int idx;
CODE:
#line 648 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_loeschung(idx[,retval]])");

   RETVAL=biq_loeschung(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 642 "KontoCheck.lx"

int
biq_nachfolge_blz_i(r,idx...)
   int r;
   int idx;
CODE:
#line 649 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_nachfolge_blz(idx[,retval]])");

   RETVAL=biq_nachfolge_blz(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL

#line 643 "KontoCheck.lx"

int
biq_iban_regel_i(r,idx...)
   int r;
   int idx;
CODE:
#line 650 "KontoCheck.lx"
   if(items<2 || items>3)
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::biq_iban_regel(idx[,retval]])");

   RETVAL=biq_iban_regel(idx,&r);
   if(items==3){
      sv_setiv(ST(2),(IV)r);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   r
   RETVAL


#line 638 "KontoCheck.lx"

const char *
iban_name_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 645 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 648 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_name(iban[,zweigstelle[,retval]])");

   RETVAL=iban_name(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 639 "KontoCheck.lx"

const char *
iban_name_kurz_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 646 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 649 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_name_kurz(iban[,zweigstelle[,retval]])");

   RETVAL=iban_name_kurz(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 640 "KontoCheck.lx"

int
iban_plz_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 647 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 650 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_plz(iban[,zweigstelle[,retval]])");

   RETVAL=iban_plz(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 641 "KontoCheck.lx"

const char *
iban_ort_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 648 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 651 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_ort(iban[,zweigstelle[,retval]])");

   RETVAL=iban_ort(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 642 "KontoCheck.lx"

int
iban_pan_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 649 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 652 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_pan(iban[,zweigstelle[,retval]])");

   RETVAL=iban_pan(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 643 "KontoCheck.lx"

const char *
iban_bic_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 650 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 653 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_bic(iban[,zweigstelle[,retval]])");

   RETVAL=iban_bic(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 644 "KontoCheck.lx"

int
iban_pz_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 651 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 654 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_pz(iban[,zweigstelle[,retval]])");

   RETVAL=iban_pz(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 645 "KontoCheck.lx"

int
iban_aenderung_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 652 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 655 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_aenderung(iban[,zweigstelle[,retval]])");

   RETVAL=iban_aenderung(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 646 "KontoCheck.lx"

int
iban_loeschung_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 653 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 656 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_loeschung(iban[,zweigstelle[,retval]])");

   RETVAL=iban_loeschung(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 647 "KontoCheck.lx"

int
iban_nachfolge_blz_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 654 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 657 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_nachfolge_blz(iban[,zweigstelle[,retval]])");

   RETVAL=iban_nachfolge_blz(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL

#line 648 "KontoCheck.lx"

int
iban_iban_regel_i(r,iban...)
   char *iban;
   int r;
PREINIT:
#line 655 "KontoCheck.lx"
   unsigned int zweigstelle;
CODE:
#line 658 "KontoCheck.lx"
   if(items==2)
      zweigstelle=0;
   else if(items==3 || items==4)
      zweigstelle=(unsigned int)SvUV(ST(2));
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_iban_regel(iban[,zweigstelle[,retval]])");

   RETVAL=iban_iban_regel(iban,zweigstelle,&r);
   if(items==4){
      sv_setiv(ST(3),(IV)r);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   r
   RETVAL


const char *
kto_check_retval2txt(ret)
   int ret;
CODE:
#line 656 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2txt(ret)");

   RETVAL=kto_check_retval2txt(ret);
OUTPUT:
   RETVAL


#line 664 "KontoCheck.lx"

const char *
retval2txt(ret)
   int ret;
CODE:
#line 670 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2txt(ret)");

   RETVAL=kto_check_retval2txt(ret);
OUTPUT:
   RETVAL

const char *
kto_check_retval2iso(ret)
   int ret;
CODE:
#line 657 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2iso(ret)");

   RETVAL=kto_check_retval2iso(ret);
OUTPUT:
   RETVAL


#line 665 "KontoCheck.lx"

const char *
retval2iso(ret)
   int ret;
CODE:
#line 671 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2iso(ret)");

   RETVAL=kto_check_retval2iso(ret);
OUTPUT:
   RETVAL

const char *
kto_check_retval2txt_short(ret)
   int ret;
CODE:
#line 658 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2txt_short(ret)");

   RETVAL=kto_check_retval2txt_short(ret);
OUTPUT:
   RETVAL


#line 666 "KontoCheck.lx"

const char *
retval2txt_short(ret)
   int ret;
CODE:
#line 672 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2txt_short(ret)");

   RETVAL=kto_check_retval2txt_short(ret);
OUTPUT:
   RETVAL

const char *
kto_check_retval2html(ret)
   int ret;
CODE:
#line 659 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2html(ret)");

   RETVAL=kto_check_retval2html(ret);
OUTPUT:
   RETVAL


#line 667 "KontoCheck.lx"

const char *
retval2html(ret)
   int ret;
CODE:
#line 673 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2html(ret)");

   RETVAL=kto_check_retval2html(ret);
OUTPUT:
   RETVAL

const char *
kto_check_retval2utf8(ret)
   int ret;
CODE:
#line 660 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2utf8(ret)");

   RETVAL=kto_check_retval2utf8(ret);
OUTPUT:
   RETVAL


#line 668 "KontoCheck.lx"

const char *
retval2utf8(ret)
   int ret;
CODE:
#line 674 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2utf8(ret)");

   RETVAL=kto_check_retval2utf8(ret);
OUTPUT:
   RETVAL

const char *
kto_check_retval2dos(ret)
   int ret;
CODE:
#line 661 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2dos(ret)");

   RETVAL=kto_check_retval2dos(ret);
OUTPUT:
   RETVAL


#line 669 "KontoCheck.lx"

const char *
retval2dos(ret)
   int ret;
CODE:
#line 675 "KontoCheck.lx"
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::retval2dos(ret)");

   RETVAL=kto_check_retval2dos(ret);
OUTPUT:
   RETVAL


const char *
kto_check_encoding_str(mode)
   int mode

int
rebuild_blzfile(inputname,outputname,set)
   char *inputname
   char *outputname
   int set

int
pz_aenderungen_enable(set)
   int set

int
kto_check_encoding(mode)
   int mode

int
keep_raw_data(mode)
   int mode

const char *
current_lutfile_name_i(want_array...)
   int want_array;
PREINIT:
#line 709 "KontoCheck.lx"
   int set,level,ret;
CODE:
#line 711 "KontoCheck.lx"
   if(items!=4)Perl_croak(aTHX_ "Usage: Business::KontoCheck::current_lutfile_name_i(want_array,set,level,retval)");
   if(want_array)
      RETVAL=current_lutfile_name(&set,&level,&ret);
   else
      RETVAL=current_lutfile_name(NULL,NULL,&ret);
   if(ret<0)RETVAL="";
   if(want_array){
      sv_setiv(ST(1), (IV)set);
      SvSETMAGIC(ST(1));
      sv_setiv(ST(2), (IV)level);
      SvSETMAGIC(ST(2));
      sv_setiv(ST(3), (IV)ret);
      SvSETMAGIC(ST(3));
   }
OUTPUT:
   RETVAL


int
lut_info_i(lut_name...)
   char *lut_name;
PREINIT:
#line 733 "KontoCheck.lx"
   char *info1,*info2,*dptr;
   int valid1,valid2,want_array,ret;
CODE:
#line 736 "KontoCheck.lx"
   want_array=(int)SvIV(ST(1));
   if(items!=7)Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_info_i(lut_name,want_array,info1,valid1,info2,valid2,lut_dir)");
   if(want_array<0)Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_info(lut_name)");
   if(want_array){
       ret=lut_info(lut_name,&info1,&info2,&valid1,&valid2);
       lut_dir_dump_str(lut_name,&dptr);
       if(!info1)info1="";
       if(!info2)info2="";
   }
   else{
      ret=lut_info(lut_name,NULL,NULL,&valid1,&valid2);
      dptr=info1=info2="";
   }
   if(ret<OK)
   	RETVAL=ret;
   else if(valid1==LUT2_VALID || valid2==LUT2_VALID)
   	RETVAL=LUT2_VALID;
   else if(valid1==LUT1_SET_LOADED)
   	RETVAL=LUT1_SET_LOADED;
   else if(valid1==LUT2_NO_VALID_DATE || valid2==LUT2_NO_VALID_DATE)
   	RETVAL=LUT2_NO_VALID_DATE;
   else
   	RETVAL=LUT2_INVALID;

 	sv_setpv((SV*)ST(2), info1);
 	SvSETMAGIC(ST(2));
 	sv_setiv(ST(3), (IV)valid1);
 	SvSETMAGIC(ST(3));
 	sv_setpv((SV*)ST(4), info2);
 	SvSETMAGIC(ST(4));
 	sv_setiv(ST(5), (IV)valid2);
 	SvSETMAGIC(ST(5));
 	sv_setpv((SV*)ST(6),dptr);
 	SvSETMAGIC(ST(6));

 	if(want_array){
         /* der Speicher von info1, info2 und dptr muß wieder freigegeben
          * werden. Dazu kann allerdings nicht einfach free() benutzt werden,
          * da das von strawberry perl auf die Perl-Version umdefiniert wird
          * und dann zu einem Absturz führt. kc_free() ist in konto_check.c
          * definiert und ruft dort einfach free() auf.
          */
       if(*info1)kc_free(info1);
       if(*info2)kc_free(info2);
       if(*dptr)kc_free(dptr);
   }
OUTPUT:
   RETVAL

int
generate_lut(inputname,outputname,user_info,lut_version)
   char *inputname;
   char *outputname;
   char *user_info;
   unsigned int lut_version;

int
copy_lutfile(old_name,new_name,new_slots)
   char *old_name;
   char *new_name;
   int new_slots

int
ci_check(ci)
   char *ci;
CODE:
   if(items!=1)Perl_croak(aTHX_ "Usage: Business::KontoCheck::ci_check(ci)");
   RETVAL=ci_check(ci);
OUTPUT:
   RETVAL

int
iban_check(iban...)
   char *iban;
PREINIT:
   int *ret,r;
CODE:
   switch(items){
      case 1:
         ret=NULL;
         break;
      case 2:
         ret=&r;
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::iban_check(iban[,ret_kc])");
         break;
   }
   RETVAL=iban_check(iban,ret);
   if(ret){
      sv_setiv(ST(1),(IV)r);
      SvSETMAGIC(ST(1));
   }
OUTPUT:
   RETVAL

int
bic_check(bic...)
   char *bic;
PREINIT:
   int cnt;
CODE:
   switch(items){
      case 1:
         RETVAL=bic_check(bic,NULL);
         break;
      case 2:
         RETVAL=bic_check(bic,&cnt);
         sv_setiv(ST(1),(IV)cnt);
         SvSETMAGIC(ST(1));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::bic_check(bic[,cnt])");
         break;
   }
OUTPUT:
   RETVAL

int
lut_blocks(...)
PREINIT:
#line 857 "KontoCheck.lx"
   int mode;
   char *lut_filename;
   char *lut_blocks_ok;
   char *lut_blocks_fehler;
CODE:
#line 862 "KontoCheck.lx"
   if(items>1)
      mode=(int)SvIV(ST(0));
   else
      mode=0;  /* Dummy gegen Compiler-Warnungen */
   lut_filename=lut_blocks_ok=lut_blocks_fehler=NULL;
   switch(items){
      case 0:
      case 1:
         RETVAL=lut_blocks(0,NULL,NULL,NULL);
         break;
      case 2:
         RETVAL=lut_blocks(mode,&lut_filename,NULL,NULL);
         break;
      case 3:
         RETVAL=lut_blocks(mode,&lut_filename,&lut_blocks_ok,NULL);
         break;
      case 4:
         RETVAL=lut_blocks(mode,&lut_filename,&lut_blocks_ok,&lut_blocks_fehler);
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_blocks([$mode[,$filename[,$blocks_ok[,$blocks_fehler]]])");
         break;
   }
	if(lut_filename){
      sv_setpv((SV*)ST(1),lut_filename);
      SvSETMAGIC(ST(1));
      kc_free(lut_filename);
   }
	if(lut_blocks_ok){
      sv_setpv((SV*)ST(2),lut_blocks_ok);
      SvSETMAGIC(ST(2));
      kc_free(lut_blocks_ok);
   }
	if(lut_blocks_fehler){
      sv_setpv((SV*)ST(3),lut_blocks_fehler);
      SvSETMAGIC(ST(3));
      kc_free(lut_blocks_fehler);
   }
OUTPUT:
   RETVAL

int
iban_gen_i(blz,kto...)
   char *blz;
   char *kto;
PREINIT:
   char *ptr,*dptr,*papier,iban[24],blz2[16],kto2[16];
   const char *bic;
   int regel,ret;
#if DEBUG>0
   RETVAL rv;
#endif
CODE:
   if(items!=9){
      Perl_croak(aTHX_ "Business::KontoCheck::iban_gen_i() requires 9 arguments, %d are given",(int)items);
      RETVAL=0;
   }
   else{
      papier=iban_bic_gen(blz,kto,&bic,blz2,kto2,&ret);
      if(papier){
         for(ptr=papier,dptr=iban;*ptr;ptr++)if(*ptr!=' ')*dptr++=*ptr;
         *dptr=0;
         sv_setpv((SV*)ST(2),iban);
         SvSETMAGIC(ST(2));
         sv_setpv((SV*)ST(3),papier);
         SvSETMAGIC(ST(3));
         kc_free(papier);
      }
      if(bic){
         sv_setpv((SV*)ST(4),bic);
         SvSETMAGIC(ST(4));
      }
      regel=lut_iban_regel(blz,0,NULL);
      sv_setiv(ST(5),regel);
      SvSETMAGIC(ST(5));
#if DEBUG>0
      kto_check_blz_dbg(blz,kto,&rv);
      sv_setpv((SV*)ST(6),rv.methode);
#else
      sv_setpv((SV*)ST(6),"no debug version");
#endif
      SvSETMAGIC(ST(6));
      sv_setpv((SV*)ST(7),blz2);
      SvSETMAGIC(ST(7));
      sv_setpv((SV*)ST(8),kto2);
      SvSETMAGIC(ST(8));
      RETVAL=ret;
   }
OUTPUT:
   RETVAL

const char*
iban2bic_i(iban...)
   char *iban;
PREINIT:
   char blz[16],kto[16];
   const char *bic;
   int ret;
CODE:
   if(items!=4){
      Perl_croak(aTHX_ "Business::KontoCheck::iban2bic_i() requires 4 arguments, %d are given",(int)items);
      RETVAL=0;
   }
   else{
      bic=iban2bic(iban,&ret,blz,kto);
      sv_setiv(ST(1),ret);
      SvSETMAGIC(ST(1));
      if(ret>0){
         sv_setpv((SV*)ST(2),blz);
         SvSETMAGIC(ST(2));
         sv_setpv((SV*)ST(3),kto);
         SvSETMAGIC(ST(3));
      }
      RETVAL=bic;
   }
OUTPUT:
   RETVAL

int
ipi_check(zweck)
   char *zweck;

int 
ipi_gen_i(zweck...)
   char *zweck;
PREINIT:
   char ipi_buffer[24],ipi_papier[32];
CODE:
   if(items<1 || items>3)Perl_croak(aTHX_ "Usage: Business::KontoCheck::ipi_gen(zweck[,zweck_edv[,zweck_papier]])");
   RETVAL=ipi_gen(zweck,ipi_buffer,ipi_papier);
   if(items>=2){
      sv_setpv((SV*)ST(1),ipi_buffer);
      SvSETMAGIC(ST(1));
   }
   if(items==3){
      sv_setpv((SV*)ST(2),ipi_papier);
      SvSETMAGIC(ST(2));
   }
OUTPUT:
   RETVAL

void
lut_suche_volltext_i(want_array,search...)
   int want_array;
   char *search;
PREINIT:
#line 1008 "KontoCheck.lx"
   char **base_name;
   int i,ret,anzahl,anzahl_name,start_name_idx,*start_idx,*zw,*bb;
   int sort,uniq,anzahl2,*idx_o,*cnt_o;
   AV *zweigstelle,*blz_array,*vals,*cnt_array;
   SV *zweigstelle_p,*blz_array_p,*vals_p,*cnt_array_p;
PPCODE:
   if(items<2 || items>5)Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_volltext(suchworte[,retval[,uniq[,sort]]])");
   ret=lut_suche_volltext(search,&anzahl_name,&start_name_idx,&base_name,&anzahl,&start_idx,&zw,&bb);
   if(items>=3){
      sv_setiv(ST(2),(IV)ret);
      SvSETMAGIC(ST(2));
   }

   sort=uniq=-1;
   if(items>=4)uniq=(int)SvIV(ST(3));
   if(items>=5)sort=(int)SvIV(ST(4));
   if(uniq>0)
      uniq=2;
   else if(uniq<=0 && sort>0)
      uniq=1;
   else if(uniq<0 && sort<0)
      uniq=UNIQ_DEFAULT_PERL;
   if(uniq) /* bei uniq>0 sortieren, uniq>1 sortieren + uniq */
      lut_suche_sort1(anzahl,bb,zw,start_idx,&anzahl2,&idx_o,&cnt_o,uniq>1);
   else{
      anzahl2=anzahl;
      idx_o=start_idx;
      cnt_o=NULL;
   }

   blz_array=newAV();
   if(anzahl2){
      /* das BLZ-Array und cnt-Array auch in ein neues Array kopieren und als Referenz zurückgeben */
      av_unshift(blz_array,anzahl2); /* Platz machen */
      for(i=0;i<anzahl2;i++)av_store(blz_array,i,newSViv(bb[idx_o[i]]));
   }
   blz_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)blz_array)));

   if(want_array){   /* die drei nächsten Arrays werden nur bei Bedarf gefüllt */
      zweigstelle=newAV();
      vals=newAV();
      cnt_array=newAV();
      if(anzahl2){
            /* die Zweigstellen und Werte in ein neues Array kopieren, dann als Referenz zurückgeben */
         av_unshift(vals,anzahl_name);    /* Platz machen */
         av_unshift(zweigstelle,anzahl2);
         if(cnt_o)av_unshift(cnt_array,anzahl2);
         for(i=0;i<anzahl_name;i++)av_store(vals,i,newSVpvf("%s",base_name[start_name_idx+i]));
         for(i=0;i<anzahl2;i++){
            av_store(zweigstelle,i,newSViv(zw[idx_o[i]]));
            if(cnt_o)av_store(cnt_array,i,newSViv(cnt_o[i]));
         }
      }
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      zweigstelle_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)zweigstelle)));
      vals_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)vals)));
      cnt_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)cnt_array)));
      XPUSHs(blz_array_p);
      XPUSHs(zweigstelle_p);
      XPUSHs(vals_p);
      XPUSHs(sv_2mortal(newSViv(ret)));
      XPUSHs(cnt_array_p);
      XSRETURN(5);
   }
   else{
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      XPUSHs(blz_array_p);
      XSRETURN(1);
   }

void
lut_suche_multiple_i(want_array,search...)
   int want_array;
   char *search;
PREINIT:
#line 1089 "KontoCheck.lx"
   char *such_cmd;
   int i,uniq,ret;
   UINT4 anzahl,*blz,*zweigstellen;
   AV *zweigstellen_array,*blz_array;
   SV *zweigstelle_p,*blz_array_p;
PPCODE:

            /* Anzahl, BLZ, Zweigstellen: nur Rückgabeparameter */
   switch(items){
      case 2:  /* keine zusätzlichen Parameter */
         uniq=UNIQ_DEFAULT_PERL;
         such_cmd=NULL;
         break;
      case 3:  /* nur uniq */
         uniq=SvIV(ST(2));
         such_cmd=NULL;
         break;
      case 4:
      case 5:
         uniq=SvIV(ST(2));
         such_cmd=SvPV_nolen(ST(3));
         break;
      default:
         Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_multiple(search_words[,uniq[,search_cmd[,ret]]])");
         break;
   }

   ret=lut_suche_multiple(search,uniq,such_cmd,&anzahl,&zweigstellen,&blz);
   if(items>4){   /* retval zurückgeben */
      sv_setiv(ST(4),(IV)ret);
      SvSETMAGIC(ST(4));
   }

   blz_array=newAV();
   if(anzahl){
      /* das BLZ-Array auch in ein neues Array kopieren und als Referenz zurückgeben */
      av_unshift(blz_array,anzahl); /* Platz machen */
      for(i=0;i<anzahl;i++)av_store(blz_array,i,newSViv(blz[i]));
   }
   blz_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)blz_array)));

   if(want_array){   /* das nächste Array wird nur bei Bedarf gefüllt */
      zweigstellen_array=newAV();
      if(anzahl){
            /* die Zweigstellen in ein neues Array kopieren, dann als Referenz zurückgeben */
         av_unshift(zweigstellen_array,anzahl);
         for(i=0;i<anzahl;i++)av_store(zweigstellen_array,i,newSViv(zweigstellen[i]));
      }
      kc_free((char*)zweigstellen);
      kc_free((char*)blz);
      zweigstelle_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)zweigstellen_array)));
      XPUSHs(blz_array_p);
      XPUSHs(zweigstelle_p);
      XPUSHs(sv_2mortal(newSViv(ret)));
      XSRETURN(3);
   }
   else{
      kc_free((char*)zweigstellen);
      kc_free((char*)blz);
      XPUSHs(blz_array_p);
      XSRETURN(1);
   }

void
lut_suche_c(want_array,art...)
   int want_array;
   int art;
PREINIT:
#line 1157 "KontoCheck.lx"
   char *search,**base_name,warn_buffer[128],*fkt;
   int i,ret,anzahl,*start_idx,*zw,*bb;
   int sort,uniq,anzahl2,*idx_o,*cnt_o;
   STRLEN len;
   AV *zweigstellen_array,*blz_array,*vals,*cnt_array;
   SV *zweigstelle_p,*blz_array_p,*vals_p,*cnt_array_p;
PPCODE:
   switch(art){
      case 1:
         fkt="bic";
         break;
      case 2:
         fkt="namen";
         break;
      case 3:
         fkt="namen_kurz";
         break;
      case 4:
         fkt="ort";
         break;
      default:
         fkt=NULL;
         break;
   }
   if(items>2 && items<7)
      search=SvPV(ST(2),len);
   else{
      if(fkt)
         snprintf(warn_buffer,128,"Usage: Business::KontoCheck::lut_suche_%s(%s[,retval[,uniq[,sort]]])",fkt,fkt);
      else
         snprintf(warn_buffer,128,"unknown internal subfunction for lut_suche_c");
      Perl_croak(aTHX_ "%s",warn_buffer);
   }
   switch(art){   /* die entsprechenden Funktionen aufrufen */
      case 1:
         ret=lut_suche_bic(search,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 2:
         ret=lut_suche_namen(search,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 3:
         ret=lut_suche_namen_kurz(search,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 4:
         ret=lut_suche_ort(search,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      default:
         Perl_croak(aTHX_ "unknown internal subfunction for lut_suche_c");
         break;
   }
   if(items>3){
      sv_setiv(ST(3),(IV)ret);
      SvSETMAGIC(ST(3));
   }
   uniq=sort=-1;
   if(items>4)uniq=(int)SvIV(ST(4));
   if(items>5)sort=(int)SvIV(ST(5));
   if(uniq>0)
      uniq=2;
   else if(uniq<=0 && sort>0)
      uniq=1;
   else if(uniq<0 && sort<0)
      uniq=UNIQ_DEFAULT_PERL;
   if(uniq) /* bei uniq>0 sortieren, uniq>1 sortieren + uniq */
      lut_suche_sort1(anzahl,bb,zw,start_idx,&anzahl2,&idx_o,&cnt_o,uniq>1);
   else{
      anzahl2=anzahl;
      idx_o=start_idx;
      cnt_o=NULL;
   }
   blz_array=newAV();
   if(anzahl2){
         /* das BLZ-Array auch in ein neues Array kopieren und als Referenz zurückgeben */
      av_unshift(blz_array,anzahl2); /* Platz machen */
      for(i=0;i<anzahl2;i++)av_store(blz_array,i,newSViv(bb[idx_o[i]]));
   }
   blz_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)blz_array)));

   if(want_array){   /* die drei nächsten Arrays werden nur bei Bedarf gefüllt */
      zweigstellen_array=newAV();
      vals=newAV();
      cnt_array=newAV();
      if(anzahl2){
            /* die Zweigstellen und Werte in ein neues Array kopieren, dann als Referenz zurückgeben */
         av_unshift(zweigstellen_array,anzahl2);
         av_unshift(vals,anzahl2);
         if(cnt_o)av_unshift(cnt_array,anzahl2);
         for(i=0;i<anzahl2;i++){
            av_store(zweigstellen_array,i,newSViv(zw[idx_o[i]]));
            av_store(vals,i,newSVpvf("%s",base_name[idx_o[i]]));
            if(cnt_o)av_store(cnt_array,i,newSViv(cnt_o[i]));
         }
      }
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      zweigstelle_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)zweigstellen_array)));
      vals_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)vals)));
      cnt_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)cnt_array)));
      XPUSHs(blz_array_p);
      XPUSHs(zweigstelle_p);
      XPUSHs(vals_p);
      XPUSHs(sv_2mortal(newSViv(ret)));
      XPUSHs(cnt_array_p);
      XSRETURN(5);
   }
   else{
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      XPUSHs(blz_array_p);
      XSRETURN(1);
   }

void
lut_suche_i(want_array,art...)
   int want_array;
   int art;
PREINIT:
#line 1278 "KontoCheck.lx"
   int search1;
   int search2;
   int i,ret,anzahl,*start_idx,*base_name,*zw,*bb;
   int sort,uniq,anzahl2,*idx_o,*cnt_o;
   AV *zweigstellen_array,*blz_array,*vals,*cnt_array;
   SV *zweigstelle_p,*blz_array_p,*vals_p,*cnt_array_p;
PPCODE:
   sort=uniq=-1;
   switch(items){
      case 3:
         search1=search2=(int)SvIV(ST(2));
         break;
      case 7:  /* alle Parameter mit uniq und sort angegeben */
         sort=(int)SvIV(ST(6));
      case 6:  /* nur uniq angegeben, kein sort */
         uniq=(int)SvIV(ST(5));
      case 4:  /* Angabe von search1 und search2; ret, uniq und sort weggelassen */
      case 5:  /* search1, search2 und ret angegeben */
         search1=(int)SvIV(ST(2));
         search2=(int)SvIV(ST(3));
         break;
      default:
         switch(art){
            case 1:
               Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_blz(blz1[,blz2[,retval[,uniq[,sort]]]])");
               break;
            case 2:
               Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_pz(pz1[,pz2[,retval[,uniq[,sort]]]])");
               break;
            case 3:
               Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_plz(plz1[,plz2[,retval[,uniq[,sort]]]])");
               break;
            case 4:
               Perl_croak(aTHX_ "Usage: Business::KontoCheck::lut_suche_regel(regel1[,regel2[,retval[,uniq[,sort]]]])");
               break;
            default:
               Perl_croak(aTHX_ "unknown internal subfunction for lut_suche_i");
               break;
         }
         break;
   }
   switch(art){   /* die entsprechenden Funktionen aufrufen */
      case 1:
         ret=lut_suche_blz(search1,search2,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 2:
         ret=lut_suche_pz(search1,search2,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 3:
         ret=lut_suche_plz(search1,search2,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      case 4:
         ret=lut_suche_regel(search1,search2,&anzahl,&start_idx,&zw,&base_name,&bb);
         break;
      default:
         Perl_croak(aTHX_ "unknown internal subfunction for lut_suche_i");
         break;
   }

   if(uniq>0)
      uniq=2;
   else if(uniq<=0 && sort>0)
      uniq=1;
   else if(uniq<0 && sort<0)
      uniq=UNIQ_DEFAULT_PERL;
   if(uniq) /* bei uniq>0 sortieren, uniq>1 sortieren + uniq */
      lut_suche_sort1(anzahl,bb,zw,start_idx,&anzahl2,&idx_o,&cnt_o,uniq>1);
   else{
      anzahl2=anzahl;
      idx_o=start_idx;
      cnt_o=NULL;
   }
   if(items>=5){
      sv_setiv(ST(4),(IV)ret);
      SvSETMAGIC(ST(4));
   }

   blz_array=newAV();
   if(anzahl2){
         /* das BLZ-Array auch in ein neues Array kopieren und als Referenz zurückgeben */
      av_unshift(blz_array,anzahl2); /* Platz machen */
      for(i=0;i<anzahl2;i++)av_store(blz_array,i,newSViv(bb[idx_o[i]]));
   }
   blz_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)blz_array)));

   if(want_array){   /* die drei nächsten Arrays werden nur bei Bedarf gefüllt */
      zweigstellen_array=newAV();
      vals=newAV();
      cnt_array=newAV();
      if(anzahl2){
            /* die Zweigstellen und Werte in ein neues Array kopieren, dann als Referenz zurückgeben */
         av_unshift(zweigstellen_array,anzahl2);
         av_unshift(vals,anzahl2);
         if(cnt_o)av_unshift(cnt_array,anzahl2);
         for(i=0;i<anzahl2;i++){
            av_store(zweigstellen_array,i,newSViv(zw[idx_o[i]]));
            av_store(vals,i,newSViv(base_name[idx_o[i]]));
            if(cnt_o)av_store(cnt_array,i,newSViv(cnt_o[i]));
         }
      }
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      zweigstelle_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)zweigstellen_array)));
      vals_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)vals)));
      cnt_array_p=sv_2mortal((SV*)newRV(sv_2mortal((SV*)cnt_array)));

      XPUSHs(blz_array_p);
      XPUSHs(zweigstelle_p);
      XPUSHs(vals_p);
      XPUSHs(sv_2mortal(newSViv(ret)));
      XPUSHs(cnt_array_p);
      XSRETURN(5);
   }
   else{
      if(uniq){
         kc_free((char*)idx_o);
         kc_free((char*)cnt_o);
      }
      XPUSHs(blz_array_p);
      XSRETURN(1);
   }

int
kto_check_at(blz,kto,lut_name)
   char *blz;
   char *kto;
   char *lut_name;

char *
kto_check_at_str(blz,kto,lut_name)
   char *blz;
   char *kto;
   char *lut_name;

int
generate_lut_at(inputname,outputname...)
   char *inputname;
   char *outputname;
PREINIT:
#line 1419 "KontoCheck.lx"
   char *plain_name;
   char *plain_format;
CODE:
#line 1422 "KontoCheck.lx"
   if(items==2){
      plain_name=NULL;
      plain_format=NULL;
   }
   else if(items==3){
      plain_name=(char *)SvPV_nolen(ST(2));
      plain_format=NULL;
   }
   else if(items==4){
      plain_name=(char *)SvPV_nolen(ST(2));
      plain_format=(char *)SvPV_nolen(ST(3));
   }
   else
      Perl_croak(aTHX_ "Usage: Business::KontoCheck::generate_lut_at(inputname,outputname[,plain_name[,plain_format]])");
   RETVAL=generate_lut_at(inputname,outputname,plain_name,plain_format);
OUTPUT:
   RETVAL

