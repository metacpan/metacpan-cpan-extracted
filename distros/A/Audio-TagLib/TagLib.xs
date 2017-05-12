/***************************************************************************
    copyright            : (C) 2005 - 2010 by Dongxu Ma
    email                : dongxu@cpan.org
    copyright            : (C) 2011 - 2013 - Geoffrey Leach
    email                : gleach@cpan.org
 ***************************************************************************
 *   This library is free software; you can redistribute it and/or modify 
 *   it under the same terms as Perl itself, either Perl version 5.8.7 or,
 *   at your option, any later version of Perl 5 you may have available.
 ***************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "iconv_wrap.h"

// Patch Festus Hagen 1.62.fh4 - rt.cpan.org #82298

#include "taglib.h"

#if defined(write)
#undef write
#endif

#if defined(read)
#undef read
#endif

#if defined(setbuf)
#undef setbuf
#endif

#if defined(do_open)
#undef do_open
#endif

#if defined(do_close)
#undef do_close
#endif

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib
PROTOTYPES: 	ENABLE

INCLUDE:	xs/tbytevector.xs
INCLUDE:	xs/tbytevectorlist.xs

INCLUDE:	xs/apefooter.xs
INCLUDE:	xs/apeitem.xs

INCLUDE:	xs/tstring.xs
INCLUDE:	xs/tstringlist.xs

INCLUDE:	xs/mpegheader.xs
INCLUDE:	xs/xingheader.xs
INCLUDE:	xs/oggpage.xs
INCLUDE:	xs/oggpageheader.xs

INCLUDE:	xs/audioproperties.xs
INCLUDE:	xs/flacproperties.xs
INCLUDE:	xs/mpcproperties.xs
INCLUDE:	xs/mpegproperties.xs

INCLUDE:	xs/vorbisproperties.xs
INCLUDE:	xs/vorbisfile.xs

INCLUDE:	xs/tfile.xs
INCLUDE:	xs/fileref.xs
INCLUDE:	xs/flacfile.xs
INCLUDE:	xs/mpcfile.xs
INCLUDE:	xs/mpegfile.xs
INCLUDE:	xs/oggfile.xs
INCLUDE:	xs/oggflacfile.xs

INCLUDE:	xs/id3v2extendedheader.xs
INCLUDE:	xs/id3v2footer.xs
INCLUDE:	xs/id3v2header.xs
INCLUDE:	xs/id3v2frame.xs
INCLUDE:	xs/id3v2framefactory.xs

INCLUDE:	xs/tag.xs
INCLUDE:	xs/apetag.xs
INCLUDE:	xs/id3v1tag.xs
INCLUDE:	xs/id3v2tag.xs
INCLUDE:	xs/id3v2tagframelistmap.xs
INCLUDE:	xs/id3v2tagframelistmapiterator.xs
INCLUDE:	xs/id3v2tagframelist.xs
INCLUDE:	xs/id3v2tagframelistiterator.xs
#GCL
INCLUDE:    xs/id3v2relativevolumeframe.xs
INCLUDE:	xs/xiphcomment.xs
INCLUDE:	xs/oggfieldlistmap.xs
INCLUDE:	xs/oggfieldlistmapiterator.xs

INCLUDE:	xs/apeitemlistmap.xs
INCLUDE:	xs/apeitemlistmapiterator.xs

INCLUDE:	xs/bytevectoriterator.xs
INCLUDE:	xs/stringiterator.xs

INCLUDE:	xs/id3v1genres.xs
INCLUDE:	xs/id3v1genremap.xs
INCLUDE:	xs/id3v1genremapiterator.xs
INCLUDE:	xs/id3v2synchdata.xs

INCLUDE:	xs/attachedpictureframe.xs
INCLUDE:	xs/commentsframe.xs
#GCL
#INCLUDE:	xs/relativevolumeframe.xs
INCLUDE:	xs/textidentificationframe.xs
INCLUDE:	xs/uniquefileidentifierframe.xs
INCLUDE:	xs/unknownframe.xs
