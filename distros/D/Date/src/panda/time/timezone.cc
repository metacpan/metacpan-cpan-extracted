#include "time.h"
#include <map>
#include <assert.h>
#include <stdlib.h>
#include <cstring>
#include <panda/string.h>
#include <panda/unordered_string_map.h>

namespace panda { namespace time {

static constexpr const size_t  TZNAME_MAX     = 255; // max length of timezone name or POSIX rule (Europe/Moscow, ...)
static constexpr const char    GMT_FALLBACK[] = "GMT0";

static bool tz_from_env (char* lzname, const char* envar) {
    const char* val = getenv(envar);
    if (val == NULL) return false;
    size_t len = std::strlen(val);
    if (len < 1 || len > TZNAME_MAX) return false;
    std::strcpy(lzname, val);
    return true;
}

static string readfile (const string_view& path) {
    char spath[path.length()+1]; // need to make path null-terminated
    std::memcpy(spath, path.data(), path.length());
    spath[path.length()] = 0;

    FILE* fh = fopen(spath, "rb");
    if (fh == NULL) return string();

    if (fseek(fh, 0, SEEK_END) != 0) {
        fclose(fh);
        return string();
    }

    auto size = ftell(fh);
    if (size < 0) {
        fclose(fh);
        return string();
    }

    rewind(fh);
    string ret(size);
    size_t readsize = fread(ret.buf(), sizeof(char), size, fh);
    if (readsize != (size_t)size) return string();

    fclose(fh);
    ret.length(readsize);
    return ret;
}

}}

#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__NetBSD__) || defined(__bsdi__) || defined(__DragonFly__) || defined(__linux__) || defined(__APPLE__) || defined(__OpenBSD__)
    #include "os/unix.icc"
#elif defined __VMS
    #include "os/vms.icc"
#elif defined _WIN32
    #include "os/win.icc"
#elif defined(sun) || defined(__sun)
    #include "os/solaris.icc"
#else
    #error "Current operating system is not supported"
#endif

#ifdef TZDIR
    #undef  __PTIME_TZDIR
    #define __TMP_SHIT(name) #name
    #define __PTIME_TZDIR __TMP_SHIT(TZDIR)
#endif

namespace panda { namespace time {

using Timezones = panda::unordered_string_map<string, TimezoneSP>;

static string     _tzdir;
static string     _tzsysdir = __PTIME_TZDIR;
static Timezones  _tzcache;
static TimezoneSP _localzone;

static TimezoneSP _tzget (const string_view& zname);

static bool _virtual_zone     (const string_view& zonename, Timezone* zone);
static void _virtual_fallback (Timezone* zone);

const TimezoneSP& tzlocal () {
    if (!_localzone) tzset();
    return _localzone;
}

TimezoneSP tzget (const string_view& zonename) {
    if (!zonename.length()) return tzlocal();
    auto it = _tzcache.find(zonename);
    if (it != _tzcache.cend()) return it->second;
    auto strname = string(zonename);
    auto zone = _tzget(strname);
    _tzcache.emplace(strname, zone);
    return zone;
}

void tzset (const TimezoneSP& _zone) {
    TimezoneSP zone = _zone;
    if (!zone) {
        const char* s = getenv("TZ");
        string_view etzname = s ? s : "";
        if (etzname.length()) zone = tzget(etzname);
        else zone = _tzget("");
    }
    if (_localzone == zone) return;
    if (_localzone) _localzone->is_local = false;
    _localzone = zone;
    _localzone->is_local = true;
}

void tzset (const string_view& zonename) {
    if (zonename.length()) tzset(tzget(zonename));
    else tzset();
}

const string& tzsysdir ()                  { return _tzsysdir; }
const string& tzdir    ()                  { return _tzdir ? _tzdir : _tzsysdir; }
void          tzdir    (const string& dir) { _tzdir = dir; }

bool tzparse      (const string_view&, Timezone*);
bool tzparse_rule (const string_view&, Timezone::Rule*);

static string get_localzone_name () {
    char tmp[TZNAME_MAX+1];
    if (tz_from_env(tmp, "TZ") || get_os_localzone_name(tmp)) return string(tmp, strlen(tmp));
    return string(GMT_FALLBACK);
}

static TimezoneSP _tzget (const string_view& zname) {
    auto zonename = string(zname);
    //printf("ptime: tzget for zone %s\n", zonename);
    auto zone = new Timezone();
    TimezoneSP ret = zone;
    zone->is_local = false;
    
    if (!zonename.length()) {
        zonename = get_localzone_name();
        zone->is_local = true;
        assert(zonename.length());
    }
    
    if (zonename.length() > TZNAME_MAX) {
        //fprintf(stderr, "ptime: tzrule too long\n");
        _virtual_fallback(zone);
        return ret;
    }

    string filename;
    if (zonename.front() == ':') {
        filename = zonename.substr(1);
        zone->name = zonename;
    }
    else {
        string dir = tzdir();
        if (!dir) {
            fprintf(stderr, "ptime: tzget: this OS has no olson timezone files, you must explicitly set tzdir(DIR)\n");
            _virtual_fallback(zone);
            return ret;
        }
        zone->name = zonename;
        filename = dir + '/' + zonename;
    }
    
    string content = readfile(filename);

    if (!content) { // tz rule
        //printf("ptime: tzget rule %s\n", zonename);
        if (!_virtual_zone(zonename, zone)) {
            //fprintf(stderr, "ptime: parsing rule '%s' failed\n", zonename);
            _virtual_fallback(zone);
            return ret;
        }
    }
    else { // tz file
        //printf("ptime: tzget file %s\n", filename.c_str());
        bool result = tzparse(content, zone);
        if (!result) {
            //fprintf(stderr, "ptime: parsing file '%s' failed\n", filename.c_str());
            _virtual_fallback(zone);
            return ret;
        }
    }
    
    return ret;
}

static void _virtual_fallback (Timezone* zone) {
    //fprintf(stderr, "ptime: fallback to '%s'\n", PTIME_GMT_FALLBACK);
    assert(_virtual_zone(GMT_FALLBACK, zone) == true);
    zone->name = GMT_FALLBACK;
    zone->is_local = false;
}

static bool _virtual_zone (const string_view& zonename, Timezone* zone) {
    //printf("ptime: virtual zone %s\n", zonename);
    if (!tzparse_rule(zonename, &zone->future)) return false;
    zone->future.outer.offset = zone->future.outer.gmt_offset;
    zone->future.inner.offset = zone->future.inner.gmt_offset;
    zone->future.delta        = zone->future.inner.offset - zone->future.outer.offset;
    zone->future.max_offset   = std::max(zone->future.outer.offset, zone->future.inner.offset);
    
    zone->leaps_cnt = 0;
    zone->leaps = NULL;
    zone->trans_cnt = 1;
    zone->trans = new Timezone::Transition[zone->trans_cnt];
    std::memset(zone->trans, 0, sizeof(Timezone::Transition));
    zone->trans[0].start       = EPOCH_NEGINF;
    zone->trans[0].local_start = EPOCH_NEGINF;
    zone->trans[0].local_lower = EPOCH_NEGINF;
    zone->trans[0].local_upper = EPOCH_NEGINF;
    zone->trans[0].leap_corr   = 0;
    zone->trans[0].leap_delta  = 0;
    zone->trans[0].leap_end    = EPOCH_NEGINF;
    zone->trans[0].leap_lend   = EPOCH_NEGINF;
    zone->ltrans = zone->trans[0];
    return true;
}

}}
