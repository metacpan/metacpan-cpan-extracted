#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ravemp.h"

typedef SV * Audio__RaveMP;
typedef ravemp_slot *Audio__RaveMPSlot;

static unsigned slot_number(SV *sv)
{
    unsigned retval = 0;

    if (sv_isobject(sv) && sv_derived_from(sv, "Audio::RaveMPSlot")) {
	ravemp_slot *slot = (ravemp_slot *)SvIV((SV*)SvRV(sv));
	retval = slot->number;
    }

    return retval;
}

#define CHECK_RAVEMP \
if (!ravemp_check_idle()) XSRETURN_UNDEF

MODULE = Audio::RaveMP   PACKAGE = Audio::RaveMP   PREFIX = ravemp_

Audio::RaveMP
new(CLASS)
    SV *CLASS

    CODE:
    RETVAL = CLASS;

    OUTPUT:
    RETVAL

void
show_status(self, arg=1)
    Audio::RaveMP self
    int arg

    CODE:
    ravemp_set_show_status(arg);

int
permitted(self)
    Audio::RaveMP self

    CODE:
    RETVAL = ravemp_permitted();

    OUTPUT:
    RETVAL

int
is_ready(self)
    Audio::RaveMP self

    CODE:
    RETVAL = ravemp_check_idle();

    OUTPUT:
    RETVAL

int
upload(self, fname, dest_name=NULL)
    Audio::RaveMP self
    char *fname
    char *dest_name

    CODE:
    CHECK_RAVEMP;
    RETVAL = ravemp_upload_file(fname, dest_name);

    OUTPUT:
    RETVAL

int
download(self, number, dest=NULL)
    Audio::RaveMP self
    unsigned number
    char *dest

    CODE:
    CHECK_RAVEMP;
    RETVAL = ravemp_download(number, dest);

    OUTPUT:
    RETVAL

AV *
contents(self, listall=0)
    Audio::RaveMP self
    unsigned listall

    PREINIT:
    int i, nslots=0;
    ravemp_slot **slots = NULL;

    CODE:
    CHECK_RAVEMP;
    slots = ravemp_contents(listall, &nslots);
    RETVAL = newAV();
    if (nslots) {
	av_extend(RETVAL, nslots);
    }

    if (slots) {
	for (i=0; slots[i]; i++) {
	    SV *sv = newSV(0);
	    sv_setref_pv(sv, "Audio::RaveMPSlot", (void*)slots[i]);
	    av_push(RETVAL, sv);
	}
	safefree(slots);
    }

    OUTPUT:
    RETVAL

    CLEANUP:
    {
	HV *stash = gv_stashpv("Audio::RaveMPSlotList", TRUE);
	sv_bless(ST(0), stash);
    }

MODULE = Audio::RaveMP   PACKAGE = Audio::RaveMPSlotList   PREFIX = ravemp_

void
DESTROY(sv_slots)
     SV *sv_slots

     PREINIT:
     I32 i;
     AV *av;

     CODE:
     av = (AV *)SvRV(sv_slots);
     for (i=0; i<=AvFILL(av); i++) {
	 SV *sv = *av_fetch(av, i, FALSE);
	 ravemp_slot *slot = (ravemp_slot *)SvIV((SV*)SvRV(sv));
	 safefree(slot);
     }

MODULE = Audio::RaveMP   PACKAGE = Audio::RaveMPSlot   PREFIX = ravemp_

int
number(slot)
    Audio::RaveMPSlot slot

    CODE:
    RETVAL = slot->number;

    OUTPUT:
    RETVAL

char
type(slot)
    Audio::RaveMPSlot slot

    CODE:
    RETVAL = slot->type;

    OUTPUT:
    RETVAL

char *
filename(sv, number=0)
    SV *sv
    unsigned number

    PREINIT:
    char *filename = NULL;

    ALIAS:
    Audio::RaveMP::filename = 1

    CODE:
    CHECK_RAVEMP;
    if (number < 1) {
	if ((number = slot_number(sv)) < 1) {
	    XSRETURN_UNDEF;
	}
    }

    RETVAL = filename = ravemp_get_filename(number);

    OUTPUT:
    RETVAL

    CLEANUP:
    if (filename) {
	safefree(filename);
    }

int
remove(sv, number=0)
    SV *sv
    unsigned number 

    ALIAS:
    Audio::RaveMP::remove = 1

    CODE:
    CHECK_RAVEMP;
    if (number < 1) {
	if ((number = slot_number(sv)) < 1) {
	    XSRETURN_UNDEF;
	}
    }

    RETVAL = ravemp_remove_file(number);

    OUTPUT:
    RETVAL

int
download(slot, dest=NULL)
    Audio::RaveMPSlot slot
    char *dest

    CODE:
    CHECK_RAVEMP;
    RETVAL = ravemp_download(slot->number, dest);

    OUTPUT:
    RETVAL
