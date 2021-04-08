#include "time.h"
#include <map>
#include <mutex>
#include <thread>
#include <assert.h>
#include <stdlib.h>
#include <fstream>
#include <cstring>
#include <panda/string.h>
#include <panda/unordered_string_map.h>
#include "os.icc"

namespace panda { namespace time {

using Timezones = panda::unordered_string_map<string, TimezoneSP>;

static constexpr const char GMT_FALLBACK[] = "GMT0";

static string _tzdir;
static string _tzsysdir = __PTIME_TZDIR;
static string _tzembededdir = PANDA_DATE_ZONEINFO_DIR;

struct Data {
    uint64_t   rev = 0;
    TimezoneSP localzone;
};

struct Glob {
    std::recursive_mutex mtx;
    Data src_data;
    Data mt_data;
    std::thread::id mt_id = std::this_thread::get_id();
};

static inline Glob& get_glob () {
    static Glob glob;
    return glob;
}

static inline Data& get_data () {
    auto& glob = get_glob();
    if (std::this_thread::get_id() == glob.mt_id) {
        return glob.mt_data;
    }

    thread_local Data* ct_data = nullptr;
    if (!ct_data) { // TLS via pointers works 3x faster in GCC
        thread_local Data _ct_data;
        ct_data = &_ct_data;
    }

    return *ct_data;
}

#define SYNC_LOCK std::lock_guard<std::recursive_mutex> guard(get_glob().mtx);

static inline Data& get_synced_data () {
    auto& data = get_data();

    if (data.rev != get_glob().src_data.rev) { // data changed by some thread
        SYNC_LOCK;
        data = get_glob().src_data;
    }

    return data;
}

static TimezoneSP _tzget (const string_view& zname);

static bool _virtual_zone     (const string_view& zonename, Timezone* zone);
static void _virtual_fallback (Timezone* zone);

const TimezoneSP& tzlocal () {
    auto& data = get_synced_data();
    if (!data.localzone) tzset();
    return data.localzone;
}

static Timezones& get_tzcache () {
    if (std::this_thread::get_id() == get_glob().mt_id) {
        static Timezones tzcache;
        return tzcache;
    } else {
        static thread_local Timezones* tzcache = nullptr;
        if (!tzcache) {
            static thread_local Timezones _tzcache;
            tzcache = &_tzcache;
        }
        return *tzcache;
    }
}

TimezoneSP tzget (const string_view& zonename) {
    if (!zonename.length()) return tzlocal();

    auto& tzcache = get_tzcache();
    auto it = tzcache.find(zonename);
    if (it != tzcache.cend()) return it->second;
    auto strname = string(zonename);
    auto zone = _tzget(strname);
    tzcache.emplace(strname, zone);
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
    SYNC_LOCK;
    auto& src = get_glob().src_data;
    if (src.localzone == zone) return;
    if (src.localzone) src.localzone->is_local = false;
    src.localzone = zone;
    src.localzone->is_local = true;
    ++src.rev;
    get_data() = src;
}

void tzset (const string_view& zonename) {
    if (zonename.length()) tzset(tzget(zonename));
    else tzset();
}

const string& tzsysdir ()                  { return _tzsysdir; }
const string& tzdir    ()                  { return _tzdir ? _tzdir : _tzsysdir; }
void          tzdir    (const string& dir) { _tzdir = dir; }

const string& tzembededdir()                         { return _tzembededdir; }
void          tzembededdir(const panda::string& dir) { _tzembededdir = dir;  }

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

void use_system_timezones () {
    if (tzsysdir()) tzdir({});
    else fprintf(stderr, "panda-time[use_system_timezones]: this OS has no olson timezone files, you can't use system zones");
}

void use_embed_timezones() {
    auto old = tzdir();
    tzdir(_tzembededdir);
    if (tzget("America/New_York")->name != "America/New_York") {
        tzdir(old);
        fprintf(stderr, "panda-time[use_embeded_timezones]: embeded timezones hasn't been found");
    }
}

std::vector<string> available_timezones () {
    auto dir = tzdir();
    if (!dir) return {};
    auto dirents = scan_files_recursive(dir);
    std::vector<string> ret;
    ret.reserve(dirents.size());

    for (auto& file : dirents) {
        std::ifstream infile(dir + "/" + file);
        std::string line;
        if (!std::getline(infile, line)) continue;
        if (line.substr(0, 4) != "TZif") continue;
        if (file.find("posixrules") != string::npos || file.find("Factory") != string::npos) continue;
        ret.push_back(file);
    }

    return ret;
}

}}
