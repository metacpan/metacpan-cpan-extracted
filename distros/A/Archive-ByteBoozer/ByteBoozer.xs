#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cruncher.h"

MODULE = Archive::ByteBoozer  PACKAGE = Archive::ByteBoozer
PROTOTYPES: ENABLE

# my $source = bb_source($data, $size);

File*
bb_source(data, size)
        unsigned char *data
        size_t         size
    CODE:
        File *source;
        Newxz(source, 1, File);
        if (source == NULL)
            XSRETURN_UNDEF;
        source->size = size;
        source->data = (byte *)data;
        RETVAL = source;
    OUTPUT:
        RETVAL

# my $target = bb_crunch($source, $start_address);

File*
bb_crunch(source, start_address)
        File         *source
        unsigned int  start_address
    CODE:
        File *target;
        Newxz(target, 1, File);

        decruncherType theDecrType = noDecr;
        if (start_address > 0)
          theDecrType = normalDecr;

        _bool isRelocated = _false;

        if (target == NULL)
            XSRETURN_UNDEF;
        if (!crunch(source, target, start_address, theDecrType, isRelocated))
            XSRETURN_UNDEF;
        RETVAL = target;
    OUTPUT:
        RETVAL

# my $data = bb_data($file);

void
bb_data(file)
        File *file
    PPCODE:
        # Push string (PV) with data on the stack and mortalize it:
        SV *fileData = sv_2mortal(newSVpv((const char *)file->data, file->size));
        XPUSHs(fileData);

# my $size = bb_size($file);

void
bb_size(file)
        File *file
    PPCODE:
        # Push unsigned integer (UV) with size on the stack and mortalize it:
        SV *fileSize = sv_2mortal(newSVuv(file->size));
        XPUSHs(fileSize);

# bb_free($source, $target);

void
bb_free(source, target)
        File *source
        File *target
    CODE:
        Safefree(source);
        Safefree(target);
        XSRETURN_UNDEF;
