#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libcue/libcue.h>


MODULE = Audio::Cuefile::Libcue		PACKAGE = Audio::Cuefile::Libcue		
PROTOTYPES: DISABLE

 # constructors
struct Cd *
cue_parse_file(fp)
	FILE *	fp

struct Cd *
cue_parse_string(string)
	const char *	string

 # destructor
void
DESTROY(cd)
	struct Cd *	cd
CODE:
	cd_delete(cd);

 # CD functions
enum DiscMode
cd_get_mode(cd)
	struct Cd *	cd

const char *
cd_get_cdtextfile(cd)
	struct Cd *	cd

 # return number of tracks in cd
int
cd_get_ntrack(cd)
	struct Cd *	cd

 # CDTEXT functions
struct Cdtext *
cd_get_cdtext(cd)
	struct Cd *	cd

struct Cdtext *
track_get_cdtext(track)
	struct Track *	track

const char *
cdtext_get(pti, cdtext)
	enum Pti	pti
	struct Cdtext *	cdtext

 # REM functions
struct Rem *
cd_get_rem(cd)
	struct Cd *	cd

struct Rem *
track_get_rem(track)
	struct Track *	track

 # return pointer to value for rem comment
 # @param unsigned int: enum of rem comment
const char *
rem_get(cmt, rem)
	enum RemType	cmt
	struct Rem *	rem

 # Track functions
struct Track *
cd_get_track(cd, i)
	struct Cd *	cd
	int	i

const char *
track_get_filename(track)
	struct Track *	track

long
track_get_start(track)
	struct Track *	track

long
track_get_length(track)
	struct Track *	track

enum TrackMode
track_get_mode(track)
	struct Track *	track

enum TrackSubMode
track_get_sub_mode(track)
	struct Track *	track

int
track_is_set_flag(track, flag)
	struct Track *	track
	enum TrackFlag	flag

long
track_get_zero_pre(track)
	struct Track *	track

long
track_get_zero_post(track)
	struct Track *	track

const char *
track_get_isrc(track)
	struct Track *	track

long
track_get_index(track, i)
	struct Track *	track
	int	i
