#pragma once
#include <xs/Sv.h>

namespace xs {

struct CloneFlags {
    static constexpr const int TRACK_REFS = 1;
};

Sv clone (const Sv& source, int flags = CloneFlags::TRACK_REFS);

}
