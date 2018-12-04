#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "diskimage.h"

#define DIRECTORY_FILENAME_LENGTH 16
#define DISKDRIVE_STATUS_LENGTH   80

MODULE = D64::Disk::Image  PACKAGE = D64::Disk::Image
PROTOTYPES: ENABLE

# my $diskImage = di_load_image($name);

DiskImage*
di_load_image(name)
        char *name
    CODE:
        RETVAL = di_load_image(name);
    OUTPUT:
        RETVAL

# my $diskImage = di_create_image($name, $size);

DiskImage*
di_create_image(name, size);
        char *name
        int   size
    CODE:
        RETVAL = di_create_image(name, size);
    OUTPUT:
        RETVAL

# di_free_image($diskImage);

void
di_free_image(di)
        DiskImage *di
    CODE:
        di_free_image(di);

# di_sync($diskImage);

void
di_sync(di)
        DiskImage *di
    CODE:
        di_sync(di);

# my ($numstatus, $status) = di_status($diskImage);

void
di_status(di)
        DiskImage *di
    PREINIT:
        char *status;
        int   numstatus, statuslen;
    PPCODE:
        New(1, status, DISKDRIVE_STATUS_LENGTH + 1, char);
        if (status) {
            memset(status, '\0', DISKDRIVE_STATUS_LENGTH + 1);
            numstatus = di_status(di, status);
            statuslen = strlen(status);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(numstatus)));
            PUSHs(sv_2mortal(newSVpv(status, statuslen)));
        }
        Safefree(status);

# my $numstatus = di_format($diskImage, $rawname, $rawid);

int
di_format(di, rawname, rawid)
        DiskImage     *di
        unsigned char *rawname
        unsigned char *rawid
    CODE:
        RETVAL = di_format(di, rawname, rawid);
    OUTPUT:
        RETVAL

# my $status = di_delete($diskImage, $rawPattern, $fileType);

int
di_delete(di, rawpattern, type)
        DiskImage     *di
        unsigned char *rawpattern
        FileType       type
    CODE:
        RETVAL = di_delete(di, rawpattern, type);
    OUTPUT:
        RETVAL

# my $status = di_rename($diskImage, $oldRawName, $newRawName, $fileType);

int
di_rename(di, oldrawname, newrawname, type)
        DiskImage     *di
        unsigned char *oldrawname
        unsigned char *newrawname
        FileType       type
    CODE:
        RETVAL = di_rename(di, oldrawname, newrawname, type);
    OUTPUT:
        RETVAL

# my $sectors = di_sectors_per_track($imageType, $track);

int
di_sectors_per_track(type, track)
        ImageType type
        int       track
    CODE:
        RETVAL = di_sectors_per_track(type, track);
    OUTPUT:
        RETVAL

# my $tracks = di_tracks($imageType);

int
di_tracks(type)
        ImageType type
    CODE:
        RETVAL = di_tracks(type);
    OUTPUT:
        RETVAL

# my ($title, $id) = di_title($diskImage);

void
di_title(di)
        DiskImage *di
    PREINIT:
        unsigned char *title;
        unsigned char *id;
    PPCODE:
        title = di_title(di);
        id = title + 18;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpv((const char *)title, 16)));
        PUSHs(sv_2mortal(newSVpv((const char *)id, 5)));

# my $track_blocks_free = di_track_blocks_free($diskImage, $track);

int
di_track_blocks_free(di, track)
        DiskImage *di
        int        track
    CODE:
        RETVAL = di_track_blocks_free(di, track);
    OUTPUT:
        RETVAL

# my $is_ts_free = di_is_ts_free($diskImage, $track, $sector);

int
di_is_ts_free(di, track, sector)
        DiskImage *di
        int        track
        int        sector
    CODE:
        TrackSector ts;
        ts.track = (unsigned char)track;
        ts.sector = (unsigned char)sector;
        RETVAL = di_is_ts_free(di, ts);
    OUTPUT:
        RETVAL

# di_alloc_ts($diskImage, $track, $sector);

void
di_alloc_ts(di, track, sector)
        DiskImage *di
        int        track
        int        sector
    CODE:
        TrackSector ts;
        ts.track = (unsigned char)track;
        ts.sector = (unsigned char)sector;
        di_alloc_ts(di, ts);

# di_free_ts($diskImage, $track, $sector);

void
di_free_ts(di, track, sector)
        DiskImage *di
        int        track
        int        sector
    CODE:
        TrackSector ts;
        ts.track = (unsigned char)track;
        ts.sector = (unsigned char)sector;
        di_free_ts(di, ts);

# my $rawname = di_rawname_from_name($name);

void
di_rawname_from_name(name)
        char *name
    PREINIT:
        unsigned char *rawname;
    PPCODE:
        New(1, rawname, DIRECTORY_FILENAME_LENGTH + 1, unsigned char);
        if (rawname) {
            di_rawname_from_name(rawname, name);
            rawname[DIRECTORY_FILENAME_LENGTH] = '\0';
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSVpv((const char *)rawname, DIRECTORY_FILENAME_LENGTH)));
        }
        Safefree(rawname);

# my $name = di_name_from_rawname($rawname);

void
di_name_from_rawname(rawname)
        unsigned char *rawname
    PREINIT:
        int   namelen;
        char *name;
    PPCODE:
        New(1, name, DIRECTORY_FILENAME_LENGTH + 1, char);
        if (name) {
            namelen = di_name_from_rawname(name, rawname);
            name[namelen] = '\0';
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSVpv(name, namelen)));
        }
        Safefree(name);

# my $blocksfree = _di_blocksfree($diskImage);

int
_di_blocksfree(di)
        DiskImage *di
    CODE:
        RETVAL = di->blocksfree;
    OUTPUT:
        RETVAL

# my $imageType = _di_type($diskImage);

ImageType
_di_type(di)
        DiskImage *di
    CODE:
        RETVAL = di->type;
    OUTPUT:
        RETVAL

MODULE = D64::Disk::Image  PACKAGE = D64::Disk::Image::File
PROTOTYPES: ENABLE

# my $imageFile = di_open($diskImage, $rawname, $fileType, $mode);

ImageFile*
di_open(di, rawname, type, mode)
        DiskImage     *di
        unsigned char *rawname
        FileType       type
        char          *mode
    CODE:
        RETVAL = di_open(di, rawname, type, mode);
        if (RETVAL == NULL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

# di_close($imageFile);

void
di_close(imgfile)
        ImageFile *imgfile
    CODE:
        di_close(imgfile);

# my ($counter, $buffer) = di_read($imageFile, $maxlength);

void
di_read(imgfile, len);
        ImageFile *imgfile
        int        len
    PREINIT:
        unsigned char *buffer;
        int            counter;
    PPCODE:
        New(1, buffer, len + 1, unsigned char);
        if (buffer) {
            memset(buffer, '\0', len + 1);
            counter = di_read(imgfile, buffer, len);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(counter)));
            PUSHs(sv_2mortal(newSVpv((const char *)buffer, counter)));
        }
        Safefree(buffer);

# my $counter = di_write($imageFile, $buffer, $length);

int
di_write(imgfile, buffer, len);
        ImageFile     *imgfile
        unsigned char *buffer
        int            len
    CODE:
        RETVAL = di_write(imgfile, buffer, len);
    OUTPUT:
        RETVAL
